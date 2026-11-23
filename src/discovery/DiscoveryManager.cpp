#include "discovery/DiscoveryManager.h"
#include "discovery/ServiceAdvertiser.h"
#include "settings/AppSettings.h"
#include "cast/cast_auth_window.h"
#include <QDateTime>
#include <QSettings>
#include <QUuid>
#include <glib.h>
#include <algorithm>
#include <vector>

// Platform headers for MAC address reading
#ifdef __linux__
#include <sys/ioctl.h>
#include <net/if.h>
#include <netinet/in.h>
#include <cstring>
#include <unistd.h>
#elif defined(_WIN32)
#include <winsock2.h>
#include <iphlpapi.h>
#include <cstdio>
#elif defined(__APPLE__)
#include <ifaddrs.h>
#include <net/if_dl.h>
#include <net/if.h>
#include <cstdio>
#endif

namespace airshow {

static constexpr uint16_t kAirPlayPort   = 7000;
static constexpr uint16_t kCastPort      = 8009;
static constexpr uint16_t kMiracastPort  = 7250;  // MS-MICE control port (D-04)
static constexpr uint16_t kAirShowPort   = 7400;  // AirShow custom protocol (RECV-02)

DiscoveryManager::DiscoveryManager(AppSettings* settings)
    : m_settings(settings)
    , m_advertiser(ServiceAdvertiser::create()) {}

DiscoveryManager::~DiscoveryManager() {
    stop();
}

bool DiscoveryManager::start() {
    if (!m_advertiser) {
        g_warning("DiscoveryManager: no ServiceAdvertiser available on this platform");
        return false;
    }

    const std::string name = m_settings->receiverName().toStdString();
    if (m_deviceId.empty()) {
        m_deviceId = readMacAddress();
    }
    const std::string mac  = m_deviceId;
    const std::string pi   = getOrCreateUuid("airplay/pi");
    const std::string castId = getOrCreateUuid("cast/id");

    // Placeholder public key: 64 zero bytes as hex (Phase 4 will replace with real key)
    const std::string pkPlaceholder(128, '0');

    // --- _airplay._tcp (DISC-01) ---
    std::vector<TxtRecord> airplayTxt = {
        {"deviceid", mac},
        {"features", "0x5A7FFEE6,0x1E"},
        {"model",    "AppleTV3,2"},
        {"srcvers",  "220.68"},
        {"pk",       pkPlaceholder},
        {"pi",       pi},
    };
    const bool airplayOk = m_advertiser->advertise("_airplay._tcp", name, kAirPlayPort, airplayTxt);
    g_message("DiscoveryManager: mDNS register _airplay._tcp name='%s' port=%u deviceid=%s pi=%s ok=%s",
              name.c_str(), kAirPlayPort, mac.c_str(), pi.c_str(), airplayOk ? "true" : "false");

    // --- _raop._tcp (DISC-01 — iOS audio/legacy discovery) ---
    // Service name format for RAOP: "<MAC>@<ReceiverName>"
    const std::string raopName = mac + "@" + name;
    std::vector<TxtRecord> raopTxt = {
        {"txtvers", "1"},
        {"ch",      "2"},
        {"cn",      "0,1,2,3"},
        {"da",      "true"},
        {"et",      "0,3,5"},
        {"md",      "0,1,2"},
        {"pw",      "false"},
        {"sr",      "44100"},
        {"ss",      "16"},
        {"tp",      "UDP"},
        {"vn",      "65537"},
        {"vs",      "220.68"},
        {"am",      "AppleTV3,2"},
        {"pk",      pkPlaceholder},
        {"ft",      "0x5A7FFEE6,0x1E"},
    };
    const bool raopOk = m_advertiser->advertise("_raop._tcp", raopName, kAirPlayPort, raopTxt);
    g_message("DiscoveryManager: mDNS register _raop._tcp name='%s' port=%u ok=%s",
              raopName.c_str(), kAirPlayPort, raopOk ? "true" : "false");

    // --- _googlecast._tcp (DISC-02) ---
    // Strip hyphens and braces from UUID — Cast id must be exactly 32 bare hex chars.
    // QUuid::toString(WithBraces) produces "{xxxxxxxx-xxxx-...}" so we drop both.
    std::string castIdNoHyphens = castId;
    castIdNoHyphens.erase(
        std::remove_if(castIdNoHyphens.begin(), castIdNoHyphens.end(),
                       [](char c){ return c == '-' || c == '{' || c == '}'; }),
        castIdNoHyphens.end()
    );
    std::vector<TxtRecord> castTxt = {
        {"id", castIdNoHyphens},
        {"ve", "05"},
        {"md", "Chromecast"},
        {"fn", name},
        {"ic", "/icon.png"},
        {"ca", "4101"},  // 0x1005 = VIDEO_OUT|AUDIO_OUT|CAST_PROTOCOL_V2 — required for Chrome to list device
        {"st", "0"},
        {"rs", ""},
    };
    // Don't show up in Cast menus once the auth signature table has run out —
    // every sender would fail authentication (CastHandler also refuses to start).
    const auto nowSecs = static_cast<uint64_t>(QDateTime::currentSecsSinceEpoch());
    if (cast::isCastAuthAvailable(nowSecs)) {
        m_advertiser->advertise("_googlecast._tcp", name, kCastPort, castTxt);
    } else {
        g_warning("DiscoveryManager: Cast auth signatures expired — not advertising _googlecast._tcp");
    }

    // --- _display._tcp (MS-MICE Miracast over Infrastructure — DISC-04, D-04) ---
    // Windows "Connect" app discovers receivers via this mDNS service type.
    // [MS-MICE] §3.1.3: TXT record key is container_id with a standard hyphenated GUID value (without braces).
    std::string containerId;
#ifdef _WIN32
    {
        QSettings sysInfo(QStringLiteral("HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\SystemInformation"),
                          QSettings::NativeFormat);
        const QString hwId = sysInfo.value(QStringLiteral("ComputerHardwareId")).toString().trimmed();
        if (!hwId.isEmpty()) {
            containerId = hwId.toStdString();
        }
    }
#endif
    if (containerId.empty()) {
        containerId = getOrCreateUuid("miracast/container_id");
    }
    if (!containerId.empty() && containerId.front() == '{' && containerId.back() == '}') {
        containerId = containerId.substr(1, containerId.size() - 2);
    }
    std::vector<TxtRecord> miracastTxt = {
        {"container_id", containerId},
    };
    const bool displayOk = m_advertiser->advertise("_display._tcp", name, kMiracastPort, miracastTxt);
    g_message("DiscoveryManager: mDNS register _display._tcp name='%s' port=%u container_id=%s ok=%s",
              name.c_str(), kMiracastPort, containerId.c_str(), displayOk ? "true" : "false");

    // --- _airshow._tcp (RECV-02 -- AirShow companion sender discovery) ---
    std::vector<TxtRecord> airshowTxt = {
        {"ver", "1"},    // protocol version
        {"fn",  name},   // friendly name (matches other services)
    };
    m_advertiser->advertise("_airshow._tcp", name, kAirShowPort, airshowTxt);

    m_running = true;
    g_message("DiscoveryManager: started advertising as '%s'", name.c_str());
    return true;
}

void DiscoveryManager::stop() {
    if (m_advertiser && m_running) {
        m_advertiser->stop();
    }
    m_running = false;
}

void DiscoveryManager::rename(const std::string& newName) {
    if (m_advertiser && m_running) {
        m_advertiser->rename(newName);
        g_message("DiscoveryManager: re-registered as '%s'", newName.c_str());
    }
}

bool DiscoveryManager::updateTxtRecord(const std::string& serviceType,
                                       const std::string& key,
                                       const std::string& value) {
    if (!m_advertiser || !m_running) {
        g_warning("DiscoveryManager::updateTxtRecord — advertiser not running");
        return false;
    }
    const bool ok = m_advertiser->updateTxtRecord(serviceType, key, value);
    g_message("DiscoveryManager: updated TXT record service='%s' key='%s' value='%s' ok=%s",
              serviceType.c_str(), key.c_str(), value.c_str(), ok ? "true" : "false");
    return ok;
}

bool DiscoveryManager::isRunning() const {
    return m_running;
}

std::string DiscoveryManager::deviceId() const {
    if (!m_deviceId.empty()) {
        return m_deviceId;
    }
    return readMacAddress();
}

std::string DiscoveryManager::receiverName() const {
    return m_settings->receiverName().toStdString();
}

// static
std::string DiscoveryManager::readMacAddress() {
#ifdef __linux__
    int sock = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock < 0) return "AA:BB:CC:DD:EE:FF";

    struct ifconf ifc{};
    char buf[4096]{};
    ifc.ifc_len = sizeof(buf);
    ifc.ifc_buf = buf;
    if (ioctl(sock, SIOCGIFCONF, &ifc) < 0) {
        close(sock);
        return "AA:BB:CC:DD:EE:FF";
    }

    struct ifreq* ifr = ifc.ifc_req;
    int numIfaces = ifc.ifc_len / static_cast<int>(sizeof(struct ifreq));
    for (int i = 0; i < numIfaces; ++i) {
        if (std::string(ifr[i].ifr_name) == "lo") continue;
        struct ifreq req{};
        std::strncpy(req.ifr_name, ifr[i].ifr_name, IFNAMSIZ - 1);
        if (ioctl(sock, SIOCGIFHWADDR, &req) == 0) {
            close(sock);
            unsigned char* mac =
                reinterpret_cast<unsigned char*>(req.ifr_hwaddr.sa_data);
            char result[18];
            snprintf(result, sizeof(result),
                     "%02X:%02X:%02X:%02X:%02X:%02X",
                     mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
            return result;
        }
    }
    close(sock);

#elif defined(_WIN32)
    // Use GetAdaptersAddresses to find the first non-loopback adapter MAC
    ULONG bufLen = 15000;
    std::vector<uint8_t> addrBuf(bufLen);
    auto* addrs = reinterpret_cast<IP_ADAPTER_ADDRESSES*>(addrBuf.data());

    ULONG ret = GetAdaptersAddresses(AF_UNSPEC,
                                      GAA_FLAG_SKIP_ANYCAST | GAA_FLAG_SKIP_MULTICAST |
                                      GAA_FLAG_SKIP_DNS_SERVER,
                                      nullptr, addrs, &bufLen);
    if (ret == ERROR_BUFFER_OVERFLOW) {
        addrBuf.resize(bufLen);
        addrs = reinterpret_cast<IP_ADAPTER_ADDRESSES*>(addrBuf.data());
        ret = GetAdaptersAddresses(AF_UNSPEC,
                                    GAA_FLAG_SKIP_ANYCAST | GAA_FLAG_SKIP_MULTICAST |
                                    GAA_FLAG_SKIP_DNS_SERVER,
                                    nullptr, addrs, &bufLen);
    }

    if (ret == NO_ERROR) {
        auto isVirtualAdapter = [](const IP_ADAPTER_ADDRESSES* a) -> bool {
            const auto containsInsensitive = [](const wchar_t* haystack, const wchar_t* needle) -> bool {
                if (!haystack || !needle) return false;
                const QString h = QString::fromWCharArray(haystack);
                const QString n = QString::fromWCharArray(needle);
                return h.contains(n, Qt::CaseInsensitive);
            };
            const wchar_t* keywords[] = {
                L"Wi-Fi Direct", L"Local Area Connection*", L"Bluetooth",
                L"Virtual", L"VMware", L"VirtualBox", L"Hyper-V",
                L"TAP-", L"Wintun", L"WireGuard", L"Loopback"
            };
            for (const wchar_t* kw : keywords) {
                if (containsInsensitive(a->Description, kw) ||
                    containsInsensitive(a->FriendlyName, kw)) {
                    return true;
                }
            }
            return false;
        };

        auto formatMac = [](const unsigned char* mac) -> std::string {
            char result[18];
            snprintf(result, sizeof(result),
                     "%02X:%02X:%02X:%02X:%02X:%02X",
                     mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
            return result;
        };

        // Pass 1: Physical Ethernet (6) or Wi-Fi (71) adapter that is UP and not a virtual/Wi-Fi Direct adapter
        for (auto* adapter = addrs; adapter != nullptr; adapter = adapter->Next) {
            if (adapter->IfType == IF_TYPE_SOFTWARE_LOOPBACK) continue;
            if (adapter->IfType == IF_TYPE_TUNNEL) continue;
            if (adapter->PhysicalAddressLength != 6) continue;
            if (adapter->OperStatus != IfOperStatusUp) continue;
            if (adapter->IfType != 6 && adapter->IfType != 71) continue;
            if (isVirtualAdapter(adapter)) continue;
            return formatMac(adapter->PhysicalAddress);
        }

        // Pass 2: Any UP non-loopback, non-tunnel adapter
        for (auto* adapter = addrs; adapter != nullptr; adapter = adapter->Next) {
            if (adapter->IfType == IF_TYPE_SOFTWARE_LOOPBACK) continue;
            if (adapter->IfType == IF_TYPE_TUNNEL) continue;
            if (adapter->PhysicalAddressLength != 6) continue;
            if (adapter->OperStatus != IfOperStatusUp) continue;
            return formatMac(adapter->PhysicalAddress);
        }
    }

#elif defined(__APPLE__)
    // Use getifaddrs to find the first Ethernet/Wi-Fi MAC address
    struct ifaddrs* ifas = nullptr;
    if (getifaddrs(&ifas) == 0) {
        for (struct ifaddrs* ifa = ifas; ifa != nullptr; ifa = ifa->ifa_next) {
            if (ifa->ifa_addr == nullptr) continue;
            if (ifa->ifa_addr->sa_family != AF_LINK) continue;
            if (ifa->ifa_flags & IFF_LOOPBACK) continue;

            auto* sdl = reinterpret_cast<struct sockaddr_dl*>(ifa->ifa_addr);
            if (sdl->sdl_alen != 6) continue;

            unsigned char* mac = reinterpret_cast<unsigned char*>(LLADDR(sdl));
            // Skip all-zero MACs (virtual interfaces)
            if (mac[0] == 0 && mac[1] == 0 && mac[2] == 0 &&
                mac[3] == 0 && mac[4] == 0 && mac[5] == 0) continue;

            char result[18];
            snprintf(result, sizeof(result),
                     "%02X:%02X:%02X:%02X:%02X:%02X",
                     mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
            freeifaddrs(ifas);
            return result;
        }
        freeifaddrs(ifas);
    }
#endif
    return "AA:BB:CC:DD:EE:FF";
}

// static
std::string DiscoveryManager::getOrCreateUuid(const std::string& settingsKey) {
    QSettings s;
    QString key = QString::fromStdString(settingsKey);
    if (!s.contains(key)) {
        QString newUuid = QUuid::createUuid().toString(QUuid::WithBraces);
        s.setValue(key, newUuid);
        s.sync();
    }
    return s.value(key).toString().toStdString();
}

} // namespace airshow
