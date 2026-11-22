#pragma once

namespace airshow {

// Windows Firewall rule registration for first-launch discovery setup (D-12, D-13).
// On Linux and macOS (D-14): all methods are no-ops that return true immediately.
// On Windows: uses INetFwPolicy2 COM API to register inbound allow rules.
//
// Ports and applications registered:
//   Applications: ComSSUCast.exe, ComSSUMiracastHelper.exe
//   UDP 5353              — mDNS (DiscoveryManager / MdnsResponder)
//   UDP 1900              — SSDP (DLNA discovery)
//   TCP 7000-7001,7100    — AirPlay control & mirroring
//   UDP 6000-6001,7010-7011 — AirPlay RTP audio & timing
//   TCP 8009              — Google Cast
//   TCP 7250, 7236 / UDP 1028 — Miracast (MS-MICE, RTSP, RTP)
//   TCP 7400, 7401        — ComSSU Cast Companion & Web Interface
class WindowsFirewall {
public:
    // Attempt to register all required firewall rules.
    // Returns true if rules were registered or already exist.
    // Returns false if permission was denied (D-13: caller must show user prompt).
    static bool registerRules();

    // Returns true if the firewall rules are already registered.
    // Used to skip the UAC prompt on subsequent launches.
    static bool rulesAlreadyRegistered();
};

} // namespace airshow
