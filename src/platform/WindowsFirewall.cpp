#include "platform/WindowsFirewall.h"

#ifdef _WIN32
// Windows-only: INetFwPolicy2 COM API (D-12)
// Headers: netfw.h (Windows SDK), ole32.lib, oleaut32.lib, uuid.lib
#include <windows.h>
#include <netfw.h>
#include <filesystem>
#include <string>
#pragma comment(lib, "ole32.lib")
#pragma comment(lib, "oleaut32.lib")

#include <glib.h>

namespace {

HRESULT addPortRule(INetFwRules* pRules, const wchar_t* name,
                    NET_FW_IP_PROTOCOL proto, const wchar_t* ports) {
    INetFwRule* pRule = nullptr;
    HRESULT hr = CoCreateInstance(__uuidof(NetFwRule), nullptr,
                                  CLSCTX_INPROC_SERVER,
                                  __uuidof(INetFwRule),
                                  reinterpret_cast<void**>(&pRule));
    if (FAILED(hr)) return hr;

    BSTR bName  = SysAllocString(name);
    BSTR bDesc  = SysAllocString(L"ComSSU Cast wireless display discovery and streaming port");
    BSTR bPorts = SysAllocString(ports);

    pRule->put_Name(bName);
    pRule->put_Description(bDesc);
    pRule->put_Protocol(proto);
    pRule->put_LocalPorts(bPorts);
    pRule->put_Direction(NET_FW_RULE_DIR_IN);
    pRule->put_Action(NET_FW_ACTION_ALLOW);
    pRule->put_Enabled(VARIANT_TRUE);
    pRule->put_Profiles(NET_FW_PROFILE2_DOMAIN | NET_FW_PROFILE2_PRIVATE | NET_FW_PROFILE2_PUBLIC);

    pRules->Remove(bName);
    hr = pRules->Add(pRule);

    SysFreeString(bPorts);
    SysFreeString(bDesc);
    SysFreeString(bName);
    pRule->Release();
    return hr;
}

HRESULT addAppRule(INetFwRules* pRules, const wchar_t* name, const wchar_t* appPath) {
    if (!appPath || appPath[0] == L'\0') return E_INVALIDARG;

    INetFwRule* pRule = nullptr;
    HRESULT hr = CoCreateInstance(__uuidof(NetFwRule), nullptr,
                                  CLSCTX_INPROC_SERVER,
                                  __uuidof(INetFwRule),
                                  reinterpret_cast<void**>(&pRule));
    if (FAILED(hr)) return hr;

    BSTR bName = SysAllocString(name);
    BSTR bDesc = SysAllocString(L"ComSSU Cast wireless display receiver executable");
    BSTR bApp  = SysAllocString(appPath);

    pRule->put_Name(bName);
    pRule->put_Description(bDesc);
    pRule->put_ApplicationName(bApp);
    // 256 = NET_FW_IP_PROTOCOL_ANY (omitted from MinGW-w64's netfw.h enum)
    pRule->put_Protocol(static_cast<NET_FW_IP_PROTOCOL>(256));
    pRule->put_Direction(NET_FW_RULE_DIR_IN);
    pRule->put_Action(NET_FW_ACTION_ALLOW);
    pRule->put_Enabled(VARIANT_TRUE);
    pRule->put_Profiles(NET_FW_PROFILE2_DOMAIN | NET_FW_PROFILE2_PRIVATE | NET_FW_PROFILE2_PUBLIC);

    pRules->Remove(bName);
    hr = pRules->Add(pRule);

    SysFreeString(bApp);
    SysFreeString(bDesc);
    SysFreeString(bName);
    pRule->Release();
    return hr;
}

} // anonymous namespace

#endif // _WIN32

namespace airshow {

bool WindowsFirewall::registerRules() {
#ifdef _WIN32
    CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

    INetFwPolicy2* pPolicy = nullptr;
    HRESULT hr = CoCreateInstance(__uuidof(NetFwPolicy2), nullptr,
                                  CLSCTX_INPROC_SERVER,
                                  __uuidof(INetFwPolicy2),
                                  reinterpret_cast<void**>(&pPolicy));
    if (FAILED(hr)) {
        // D-13: access denied or COM unavailable — show actionable prompt
        g_warning("WindowsFirewall: CoCreateInstance failed (hr=0x%lx). "
                  "Firewall rules cannot be registered automatically.", hr);
        // QMessageBox shown from main.cpp based on return value false
        CoUninitialize();
        return false;
    }

    INetFwRules* pRules = nullptr;
    hr = pPolicy->get_Rules(&pRules);
    if (FAILED(hr) || !pRules) {
        pPolicy->Release();
        CoUninitialize();
        return false;
    }

    HRESULT firstAddHr = S_OK;

    // Register inbound application allow rules (all TCP/UDP dynamic & static ports)
    // across Domain, Private, and Public (Wi-Fi Direct virtual adapter uses Public).
    wchar_t exeBuf[MAX_PATH]{};
    const DWORD len = GetModuleFileNameW(nullptr, exeBuf, MAX_PATH);
    if (len > 0 && len < MAX_PATH) {
        const std::filesystem::path exePath(exeBuf);
        const std::filesystem::path helperPath = exePath.parent_path() / L"ComSSUMiracastHelper.exe";
        firstAddHr = addAppRule(pRules, L"ComSSUCast Application", exePath.wstring().c_str());
        addAppRule(pRules, L"ComSSUMiracastHelper Application", helperPath.wstring().c_str());

        std::error_code ec;
        const std::filesystem::path devHelperPath =
            exePath.parent_path() / L"tools" / L"miracast-helper" / L"ComSSUMiracastHelper.exe";
        if (std::filesystem::exists(devHelperPath, ec)) {
            addAppRule(pRules, L"ComSSUMiracastHelper Dev Application", devHelperPath.wstring().c_str());
        }
    }

    // Register inbound application allow rules for Windows' native Miracast runtime hosts
    // (CastSrv.exe and WUDFHost.exe) so dynamic RTSP/RTP video streams over Wi-Fi Direct are allowed.
    wchar_t sysDirBuf[MAX_PATH]{};
    const UINT sysLen = GetSystemDirectoryW(sysDirBuf, MAX_PATH);
    if (sysLen > 0 && sysLen < MAX_PATH) {
        const std::filesystem::path sysDir(sysDirBuf);
        const std::filesystem::path castSrvPath = sysDir / L"CastSrv.exe";
        const std::filesystem::path wudfHostPath = sysDir / L"WUDFHost.exe";
        std::error_code ec;
        if (std::filesystem::exists(castSrvPath, ec)) {
            addAppRule(pRules, L"ComSSUCast Windows CastSrv", castSrvPath.wstring().c_str());
        }
        if (std::filesystem::exists(wudfHostPath, ec)) {
            addAppRule(pRules, L"ComSSUCast Windows WUDFHost", wudfHostPath.wstring().c_str());
        }
    }

    // Register inbound port rules for mDNS, SSDP, AirPlay/RTP, Cast, Miracast, and Web UI
    HRESULT portHr = addPortRule(pRules, L"ComSSUCast mDNS",          NET_FW_IP_PROTOCOL_UDP, L"5353");
    if (SUCCEEDED(firstAddHr) && FAILED(portHr)) {
        firstAddHr = portHr;
    }
    addPortRule(pRules, L"ComSSUCast SSDP",          NET_FW_IP_PROTOCOL_UDP, L"1900");
    addPortRule(pRules, L"ComSSUCast AirPlay TCP",   NET_FW_IP_PROTOCOL_TCP, L"7000-7001,7100");
    addPortRule(pRules, L"ComSSUCast AirPlay RTP",   NET_FW_IP_PROTOCOL_UDP, L"6000-6001,7010-7011");
    addPortRule(pRules, L"ComSSUCast Cast",          NET_FW_IP_PROTOCOL_TCP, L"8009");
    addPortRule(pRules, L"ComSSUCast Miracast MICE", NET_FW_IP_PROTOCOL_TCP, L"7250");
    addPortRule(pRules, L"ComSSUCast Miracast RTSP", NET_FW_IP_PROTOCOL_TCP, L"7236");
    addPortRule(pRules, L"ComSSUCast Miracast RTP",  NET_FW_IP_PROTOCOL_UDP, L"1028");
    addPortRule(pRules, L"ComSSUCast Protocol",      NET_FW_IP_PROTOCOL_TCP, L"7400");
    addPortRule(pRules, L"ComSSUCast Web",           NET_FW_IP_PROTOCOL_TCP, L"7401");

    pRules->Release();
    pPolicy->Release();
    CoUninitialize();

    if (FAILED(firstAddHr)) {
        g_info("WindowsFirewall: rule registration returned hr=0x%lx (run as Administrator or run scripts/setup-windows-miracast.ps1)",
               static_cast<unsigned long>(firstAddHr));
        return false;
    }
    g_message("WindowsFirewall: registered program and port rules across Domain, Private, and Public profiles");
    return true;
#else
    // D-14: Linux and macOS rely on system defaults — no firewall changes needed
    return true;
#endif
}

bool WindowsFirewall::rulesAlreadyRegistered() {
#ifdef _WIN32
    // Check QSettings first-launch flag set by AppSettings::setFirstLaunchComplete()
    // This is a fast path to skip COM/UAC on subsequent launches.
    // We rely on AppSettings::isFirstLaunch() == false meaning rules are done.
    return false;  // Caller checks AppSettings::isFirstLaunch() — see main.cpp
#else
    return true;
#endif
}

} // namespace airshow
