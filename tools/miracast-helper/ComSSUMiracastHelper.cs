// ComSSUMiracastHelper.cs
// Native Windows Wi-Fi Direct + Miracast Receiver Helper for ComSSU Cast
// Uses Windows.Media.Miracast.MiracastReceiver (WinRT) + DirectComposition MediaPlayer surface.
// Compiled with Windows' built-in .NET Framework csc.exe (zero external SDK dependencies).

using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Numerics;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Windows.Forms;
using Windows.Foundation;
using Windows.Media.Core;
using Windows.Media.Miracast;
using Windows.Media.Playback;
using Windows.UI.Composition;

namespace ComSSUCast.MiracastHelper
{
    internal sealed class PendingApproval
    {
        public string RequestId;
        public string DeviceName;
        public string MacAddress;
        public MiracastReceiverConnection Connection;
        public Deferral Deferral;
        public System.Threading.Timer TimeoutTimer;
    }

    internal sealed class MiracastVideoForm : Form
    {
        [StructLayout(LayoutKind.Sequential)]
        private struct DispatcherQueueOptions
        {
            public int dwSize;
            public int threadType;
            public int apartmentType;
        }

        [DllImport("CoreMessaging.dll")]
        private static extern int CreateDispatcherQueueController(
            [In] DispatcherQueueOptions options,
            [Out] out IntPtr dispatcherQueueController);

        [ComImport]
        [Guid("29E691FA-4567-4DCA-B319-D0F207EB6807")]
        [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
        private interface ICompositorDesktopInterop
        {
            void CreateDesktopWindowTarget(
                IntPtr hwndTarget,
                bool isTopmost,
                [MarshalAs(UnmanagedType.IUnknown)] out object result);
        }

        private IntPtr _dispatcherQueueController = IntPtr.Zero;
        private Compositor _compositor;
        private CompositionTarget _compositionTarget;
        private SpriteVisual _rootVisual;
        private CompositionSurfaceBrush _surfaceBrush;
        private MediaPlayer _mediaPlayer;
        private MediaPlayerSurface _mediaSurface;
        private Action _onUserDisconnectRequested;

        public MiracastVideoForm(Action onUserDisconnectRequested)
        {
            _onUserDisconnectRequested = onUserDisconnectRequested;

            Text = "CS Society Display — Miracast Session";
            FormBorderStyle = FormBorderStyle.None;
            WindowState = FormWindowState.Maximized;
            BackColor = Color.Black;
            ShowInTaskbar = false;
            TopMost = true;
            KeyPreview = true;

            // Keep hidden until MediaSourceCreated fires
            Opacity = 0.0;
        }

        public void InitializeComposition()
        {
            var opts = new DispatcherQueueOptions
            {
                dwSize = Marshal.SizeOf(typeof(DispatcherQueueOptions)),
                threadType = 2,    // DQTYPE_THREAD_CURRENT
                apartmentType = 2  // DQTAT_COM_STA
            };
            CreateDispatcherQueueController(opts, out _dispatcherQueueController);

            // Force HWND creation without showing the window
            IntPtr hwnd = Handle;

            _compositor = new Compositor();
            var interop = (ICompositorDesktopInterop)(object)_compositor;
            object rawTarget;
            interop.CreateDesktopWindowTarget(hwnd, false, out rawTarget);
            _compositionTarget = (CompositionTarget)rawTarget;

            _rootVisual = _compositor.CreateSpriteVisual();
            _surfaceBrush = _compositor.CreateSurfaceBrush();
            _surfaceBrush.Stretch = CompositionStretch.Uniform;
            _rootVisual.Brush = _surfaceBrush;
            _compositionTarget.Root = _rootVisual;

            _mediaPlayer = new MediaPlayer();
            _mediaPlayer.RealTimePlayback = true;
            _mediaPlayer.AutoPlay = true;

            Rectangle bounds = Screen.PrimaryScreen != null
                ? Screen.PrimaryScreen.Bounds
                : new Rectangle(0, 0, 1920, 1080);

            _mediaPlayer.SetSurfaceSize(new Windows.Foundation.Size(bounds.Width, bounds.Height));
            _mediaSurface = _mediaPlayer.GetSurface(_compositor);
            _surfaceBrush.Surface = _mediaSurface.CompositionSurface;
            _rootVisual.Size = new Vector2(bounds.Width, bounds.Height);
        }

        public void StartPlayback(MediaSource mediaSource, string deviceName)
        {
            if (InvokeRequired)
            {
                BeginInvoke(new Action(() => StartPlayback(mediaSource, deviceName)));
                return;
            }

            Rectangle bounds = Screen.PrimaryScreen != null
                ? Screen.PrimaryScreen.Bounds
                : new Rectangle(0, 0, 1920, 1080);

            Bounds = bounds;
            WindowState = FormWindowState.Maximized;
            Text = string.IsNullOrEmpty(deviceName)
                ? "CS Society Display — Miracast"
                : "CS Society Display — " + deviceName;

            if (_mediaPlayer != null)
            {
                _mediaPlayer.SetSurfaceSize(new Windows.Foundation.Size(bounds.Width, bounds.Height));
                if (_rootVisual != null)
                {
                    _rootVisual.Size = new Vector2(bounds.Width, bounds.Height);
                }
                _mediaPlayer.Source = mediaSource;
                _mediaPlayer.Play();
            }

            Opacity = 1.0;
            if (!Visible)
            {
                Show();
            }
            BringToFront();
            Activate();
        }

        public void StopPlayback()
        {
            if (InvokeRequired)
            {
                BeginInvoke(new Action(StopPlayback));
                return;
            }

            if (_mediaPlayer != null)
            {
                try
                {
                    _mediaPlayer.Pause();
                    _mediaPlayer.Source = null;
                }
                catch
                {
                    // Ignore teardown errors
                }
            }

            Opacity = 0.0;
            if (Visible)
            {
                Hide();
            }
        }

        protected override void OnResize(EventArgs e)
        {
            base.OnResize(e);
            if (_rootVisual != null && ClientSize.Width > 0 && ClientSize.Height > 0)
            {
                _rootVisual.Size = new Vector2(ClientSize.Width, ClientSize.Height);
            }
            if (_mediaPlayer != null && ClientSize.Width > 0 && ClientSize.Height > 0)
            {
                try
                {
                    _mediaPlayer.SetSurfaceSize(new Windows.Foundation.Size(ClientSize.Width, ClientSize.Height));
                }
                catch
                {
                }
            }
        }

        protected override void OnKeyDown(KeyEventArgs e)
        {
            base.OnKeyDown(e);
            if (e.KeyCode == Keys.Escape)
            {
                if (_onUserDisconnectRequested != null)
                {
                    _onUserDisconnectRequested();
                }
            }
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                try { if (_mediaSurface != null) _mediaSurface.Dispose(); } catch { }
                try { if (_mediaPlayer != null) _mediaPlayer.Dispose(); } catch { }
                try { if (_rootVisual != null) _rootVisual.Dispose(); } catch { }
                try { if (_surfaceBrush != null) _surfaceBrush.Dispose(); } catch { }
                try { if (_compositionTarget != null) _compositionTarget.Dispose(); } catch { }
                try { if (_compositor != null) _compositor.Dispose(); } catch { }
            }
            base.Dispose(disposing);
        }
    }

    internal static class Program
    {
        private static readonly object StdoutLock = new object();
        private static readonly ConcurrentDictionary<string, PendingApproval> PendingApprovals =
            new ConcurrentDictionary<string, PendingApproval>();

        private static MiracastReceiver _receiver;
        private static MiracastReceiverSession _session;
        private static MiracastReceiverConnection _activeConnection;
        private static MiracastVideoForm _videoForm;

        private static string _friendlyName = "CS Society Display";
        private static string _modelName = "ComSSU Cast";
        private static string _modelNumber = "1.0.0";
        private static MiracastReceiverAuthorizationMethod _authMethod =
            MiracastReceiverAuthorizationMethod.ConfirmConnection;
        private static bool _checkOnly = false;

        [STAThread]
        private static int Main(string[] args)
        {
            Console.OutputEncoding = new UTF8Encoding(false);
            ParseArgs(args);

            try
            {
                return RunMiracastReceiver();
            }
            catch (Exception ex)
            {
                EmitJson(new Dictionary<string, object>
                {
                    { "event", "status" },
                    { "status", "unavailable" },
                    { "available", false },
                    { "reason", ex.GetType().Name + ": " + ex.Message }
                });
                return 0;
            }
        }

        private static void ParseArgs(string[] args)
        {
            for (int i = 0; i < args.Length; i++)
            {
                string arg = args[i];
                if (arg == "--friendly-name" && i + 1 < args.Length)
                {
                    _friendlyName = args[++i];
                }
                else if (arg == "--model-name" && i + 1 < args.Length)
                {
                    _modelName = args[++i];
                }
                else if (arg == "--model-number" && i + 1 < args.Length)
                {
                    _modelNumber = args[++i];
                }
                else if (arg == "--auth" && i + 1 < args.Length)
                {
                    string mode = args[++i].Trim().ToLowerInvariant();
                    if (mode == "pin" || mode == "pin_required")
                    {
                        _authMethod = MiracastReceiverAuthorizationMethod.PinDisplayRequired;
                    }
                    else if (mode == "pin_if_requested")
                    {
                        _authMethod = MiracastReceiverAuthorizationMethod.PinDisplayIfRequested;
                    }
                    else if (mode == "none")
                    {
                        _authMethod = MiracastReceiverAuthorizationMethod.None;
                    }
                    else
                    {
                        _authMethod = MiracastReceiverAuthorizationMethod.ConfirmConnection;
                    }
                }
                else if (arg == "--check-only")
                {
                    _checkOnly = true;
                }
            }
        }

        private static int RunMiracastReceiver()
        {
            _receiver = new MiracastReceiver();
            MiracastReceiverStatus status = _receiver.GetStatus();

            if (_checkOnly)
            {
                bool supported = status.WiFiStatus == MiracastReceiverWiFiStatus.MiracastSupported ||
                                 status.WiFiStatus == MiracastReceiverWiFiStatus.MiracastSupportNotOptimized;
                EmitJson(new Dictionary<string, object>
                {
                    { "event", "status" },
                    { "status", supported ? "supported" : "unavailable" },
                    { "available", supported },
                    { "wifiStatus", status.WiFiStatus.ToString() },
                    { "listeningStatus", status.ListeningStatus.ToString() },
                    { "maxConnections", status.MaxSimultaneousConnections }
                });
                return 0;
            }

            if (status.WiFiStatus == MiracastReceiverWiFiStatus.MiracastNotSupported)
            {
                EmitJson(new Dictionary<string, object>
                {
                    { "event", "status" },
                    { "status", "unavailable" },
                    { "available", false },
                    { "wifiStatus", status.WiFiStatus.ToString() },
                    { "listeningStatus", status.ListeningStatus.ToString() },
                    { "reason", "Wi-Fi adapter does not support Miracast receiver mode (or App.WirelessDisplay.Connect capability is missing)." }
                });
                return 0;
            }

            // Configure MiracastReceiverSettings
            MiracastReceiverSettings settings = _receiver.GetCurrentSettings();
            settings.FriendlyName = _friendlyName;
            settings.ModelName = _modelName;
            settings.ModelNumber = _modelNumber;
            settings.AuthorizationMethod = _authMethod;
            settings.RequireAuthorizationFromKnownTransmitters = true;

            MiracastReceiverApplySettingsResult applyResult = _receiver.DisconnectAllAndApplySettings(settings);
            if (applyResult.Status != MiracastReceiverApplySettingsStatus.Success)
            {
                string errMsg = applyResult.ExtendedError != null
                    ? applyResult.ExtendedError.Message
                    : applyResult.Status.ToString();
                EmitJson(new Dictionary<string, object>
                {
                    { "event", "status" },
                    { "status", "unavailable" },
                    { "available", false },
                    { "applyStatus", applyResult.Status.ToString() },
                    { "reason", "Failed to apply MiracastReceiverSettings: " + errMsg }
                });
                return 0;
            }

            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            _videoForm = new MiracastVideoForm(DisconnectActiveConnection);
            _videoForm.InitializeComposition();

            // Create and start MiracastReceiverSession.
            // IMPORTANT: ConnectionCreated, MediaSourceCreated, and Disconnected MUST be
            // subscribed before calling session.Start(), otherwise WinRT returns E_INVALIDARG.
            _session = _receiver.CreateSession(null);
            _session.AllowConnectionTakeover = true;
            _session.ConnectionCreated += OnConnectionCreated;
            _session.MediaSourceCreated += OnMediaSourceCreated;
            _session.Disconnected += OnDisconnected;

            _receiver.StatusChanged += OnReceiverStatusChanged;

            MiracastReceiverSessionStartResult startResult = _session.Start();
            if (startResult.Status != MiracastReceiverSessionStartStatus.Success)
            {
                string errMsg = startResult.ExtendedError != null
                    ? startResult.ExtendedError.Message
                    : startResult.Status.ToString();
                EmitJson(new Dictionary<string, object>
                {
                    { "event", "status" },
                    { "status", "unavailable" },
                    { "available", false },
                    { "startStatus", startResult.Status.ToString() },
                    { "reason", "Failed to start MiracastReceiverSession: " + errMsg }
                });
                Cleanup();
                return 0;
            }

            MiracastReceiverStatus activeStatus = _receiver.GetStatus();
            EmitJson(new Dictionary<string, object>
            {
                { "event", "status" },
                { "status", "listening" },
                { "available", true },
                { "wifiStatus", activeStatus.WiFiStatus.ToString() },
                { "listeningStatus", activeStatus.ListeningStatus.ToString() },
                { "friendlyName", _friendlyName },
                { "modelName", _modelName },
                { "modelNumber", _modelNumber },
                { "authMethod", _authMethod.ToString() }
            });

            // Background thread to read commands from ComSSUCast over stdin
            Thread stdinThread = new Thread(StdinReaderLoop)
            {
                IsBackground = true,
                Name = "MiracastStdinReader"
            };
            stdinThread.Start();

            Application.Run();
            Cleanup();
            return 0;
        }

        private static void OnReceiverStatusChanged(MiracastReceiver sender, object args)
        {
            try
            {
                MiracastReceiverStatus st = sender.GetStatus();
                EmitJson(new Dictionary<string, object>
                {
                    { "event", "receiver_status_changed" },
                    { "listeningStatus", st.ListeningStatus.ToString() },
                    { "wifiStatus", st.WiFiStatus.ToString() }
                });
            }
            catch
            {
            }
        }

        private static void OnConnectionCreated(
            MiracastReceiverSession sender,
            MiracastReceiverConnectionCreatedEventArgs args)
        {
            try
            {
                Deferral deferral = args.GetDeferral();
                MiracastReceiverConnection conn = args.Connection;
                string deviceName = (conn != null && conn.Transmitter != null && !string.IsNullOrEmpty(conn.Transmitter.Name))
                    ? conn.Transmitter.Name
                    : "Wireless Display Device";
                string macAddress = (conn != null && conn.Transmitter != null && !string.IsNullOrEmpty(conn.Transmitter.MacAddress))
                    ? conn.Transmitter.MacAddress
                    : "";
                string pin = args.Pin ?? "";
                string requestId = Guid.NewGuid().ToString("N");

                var pending = new PendingApproval
                {
                    RequestId = requestId,
                    DeviceName = deviceName,
                    MacAddress = macAddress,
                    Connection = conn,
                    Deferral = deferral
                };

                // 20-second safety timeout (matches ComSSUCast's 15s SecurityManager timeout + margin)
                pending.TimeoutTimer = new System.Threading.Timer(_ =>
                {
                    ResolvePendingApproval(requestId, false, "timeout");
                }, null, 20000, Timeout.Infinite);

                PendingApprovals[requestId] = pending;

                EmitJson(new Dictionary<string, object>
                {
                    { "event", "connection_created" },
                    { "requestId", requestId },
                    { "deviceName", deviceName },
                    { "macAddress", macAddress },
                    { "pin", pin }
                });
            }
            catch (Exception ex)
            {
                EmitJson(new Dictionary<string, object>
                {
                    { "event", "error" },
                    { "stage", "connection_created" },
                    { "message", ex.Message }
                });
            }
        }

        private static void ResolvePendingApproval(string requestId, bool approved, string reason)
        {
            PendingApproval pending;
            if (!PendingApprovals.TryRemove(requestId, out pending))
            {
                return;
            }

            if (pending.TimeoutTimer != null)
            {
                try { pending.TimeoutTimer.Dispose(); } catch { }
            }

            try
            {
                if (approved)
                {
                    _activeConnection = pending.Connection;
                    EmitJson(new Dictionary<string, object>
                    {
                        { "event", "connection_approved" },
                        { "requestId", requestId },
                        { "deviceName", pending.DeviceName },
                        { "macAddress", pending.MacAddress }
                    });
                }
                else
                {
                    if (pending.Connection != null)
                    {
                        pending.Connection.Disconnect(MiracastReceiverDisconnectReason.ConnectionNotAccepted);
                    }
                    EmitJson(new Dictionary<string, object>
                    {
                        { "event", "connection_denied" },
                        { "requestId", requestId },
                        { "deviceName", pending.DeviceName },
                        { "reason", reason }
                    });
                }
            }
            catch (Exception ex)
            {
                EmitJson(new Dictionary<string, object>
                {
                    { "event", "error" },
                    { "stage", "resolve_approval" },
                    { "message", ex.Message }
                });
            }
            finally
            {
                if (pending.Deferral != null)
                {
                    try { pending.Deferral.Complete(); } catch { }
                }
            }
        }

        private static void OnMediaSourceCreated(
            MiracastReceiverSession sender,
            MiracastReceiverMediaSourceCreatedEventArgs args)
        {
            Deferral deferral = null;
            try
            {
                deferral = args.GetDeferral();
                MiracastReceiverConnection conn = args.Connection;
                _activeConnection = conn;

                string deviceName = (conn != null && conn.Transmitter != null && !string.IsNullOrEmpty(conn.Transmitter.Name))
                    ? conn.Transmitter.Name
                    : "Wireless Display Device";
                string macAddress = (conn != null && conn.Transmitter != null && !string.IsNullOrEmpty(conn.Transmitter.MacAddress))
                    ? conn.Transmitter.MacAddress
                    : "";

                if (_videoForm != null && args.MediaSource != null)
                {
                    _videoForm.StartPlayback(args.MediaSource, deviceName);
                }

                EmitJson(new Dictionary<string, object>
                {
                    { "event", "media_source_created" },
                    { "deviceName", deviceName },
                    { "macAddress", macAddress },
                    { "protocol", "Miracast" }
                });
            }
            catch (Exception ex)
            {
                EmitJson(new Dictionary<string, object>
                {
                    { "event", "error" },
                    { "stage", "media_source_created" },
                    { "message", ex.Message }
                });
            }
            finally
            {
                if (deferral != null)
                {
                    try { deferral.Complete(); } catch { }
                }
            }
        }

        private static void OnDisconnected(
            MiracastReceiverSession sender,
            MiracastReceiverDisconnectedEventArgs args)
        {
            try
            {
                MiracastReceiverConnection conn = args.Connection;
                string deviceName = (conn != null && conn.Transmitter != null && !string.IsNullOrEmpty(conn.Transmitter.Name))
                    ? conn.Transmitter.Name
                    : "Wireless Display Device";
                string macAddress = (conn != null && conn.Transmitter != null && !string.IsNullOrEmpty(conn.Transmitter.MacAddress))
                    ? conn.Transmitter.MacAddress
                    : "";

                if (_activeConnection == conn)
                {
                    _activeConnection = null;
                }

                if (_videoForm != null)
                {
                    _videoForm.StopPlayback();
                }

                EmitJson(new Dictionary<string, object>
                {
                    { "event", "disconnected" },
                    { "deviceName", deviceName },
                    { "macAddress", macAddress }
                });
            }
            catch (Exception ex)
            {
                EmitJson(new Dictionary<string, object>
                {
                    { "event", "error" },
                    { "stage", "disconnected" },
                    { "message", ex.Message }
                });
            }
        }

        private static void DisconnectActiveConnection()
        {
            try
            {
                var conn = _activeConnection;
                _activeConnection = null;
                if (conn != null)
                {
                    conn.Disconnect(MiracastReceiverDisconnectReason.DisconnectedByUser);
                }
                if (_videoForm != null)
                {
                    _videoForm.StopPlayback();
                }
                EmitJson(new Dictionary<string, object>
                {
                    { "event", "disconnected" },
                    { "reason", "user_disconnected" }
                });
            }
            catch
            {
            }
        }

        private static void StdinReaderLoop()
        {
            try
            {
                string line;
                while ((line = Console.ReadLine()) != null)
                {
                    line = line.Trim();
                    if (line.Length == 0) continue;

                    string cmd = ExtractJsonString(line, "command");
                    if (cmd == "resolve_approval" || cmd == "approve" || cmd == "deny")
                    {
                        string reqId = ExtractJsonString(line, "requestId");
                        bool approved = cmd == "approve" ||
                                        (cmd == "resolve_approval" && ExtractJsonBool(line, "approved"));
                        if (!string.IsNullOrEmpty(reqId))
                        {
                            ResolvePendingApproval(reqId, approved, approved ? "user_approved" : "user_denied");
                        }
                    }
                    else if (cmd == "disconnect")
                    {
                        DisconnectActiveConnection();
                    }
                    else if (cmd == "rename")
                    {
                        string newName = ExtractJsonString(line, "friendlyName");
                        if (!string.IsNullOrEmpty(newName) && _receiver != null)
                        {
                            _friendlyName = newName;
                            try
                            {
                                var s = _receiver.GetCurrentSettings();
                                s.FriendlyName = _friendlyName;
                                _receiver.DisconnectAllAndApplySettings(s);
                            }
                            catch
                            {
                            }
                        }
                    }
                    else if (cmd == "shutdown")
                    {
                        break;
                    }
                }
            }
            catch
            {
            }

            // Parent process closed stdin or sent shutdown -> exit Application loop
            try
            {
                if (_videoForm != null && _videoForm.IsHandleCreated)
                {
                    _videoForm.BeginInvoke(new Action(() =>
                    {
                        Cleanup();
                        Application.ExitThread();
                        Environment.Exit(0);
                    }));
                }
                else
                {
                    Cleanup();
                    Application.Exit();
                    Environment.Exit(0);
                }
            }
            catch
            {
                Cleanup();
                Environment.Exit(0);
            }
        }

        private static void Cleanup()
        {
            foreach (var kv in PendingApprovals)
            {
                ResolvePendingApproval(kv.Key, false, "shutdown");
            }
            try { if (_activeConnection != null) _activeConnection.Disconnect(MiracastReceiverDisconnectReason.Finished); } catch { }
            try { if (_session != null) _session.Dispose(); } catch { }
            try { if (_videoForm != null) _videoForm.Dispose(); } catch { }
        }

        // Minimal, dependency-free JSON helpers
        private static string ExtractJsonString(string json, string key)
        {
            string pattern = "\"" + key + "\"";
            int idx = json.IndexOf(pattern, StringComparison.OrdinalIgnoreCase);
            if (idx < 0) return "";
            int colon = json.IndexOf(':', idx + pattern.Length);
            if (colon < 0) return "";
            int firstQuote = json.IndexOf('"', colon + 1);
            if (firstQuote < 0) return "";
            var sb = new StringBuilder();
            for (int i = firstQuote + 1; i < json.Length; i++)
            {
                char c = json[i];
                if (c == '\\' && i + 1 < json.Length)
                {
                    sb.Append(json[++i]);
                }
                else if (c == '"')
                {
                    break;
                }
                else
                {
                    sb.Append(c);
                }
            }
            return sb.ToString();
        }

        private static bool ExtractJsonBool(string json, string key)
        {
            string pattern = "\"" + key + "\"";
            int idx = json.IndexOf(pattern, StringComparison.OrdinalIgnoreCase);
            if (idx < 0) return false;
            int colon = json.IndexOf(':', idx + pattern.Length);
            if (colon < 0) return false;
            string rest = json.Substring(colon + 1).TrimStart();
            return rest.StartsWith("true", StringComparison.OrdinalIgnoreCase);
        }

        private static string EscapeJson(string s)
        {
            if (string.IsNullOrEmpty(s)) return "";
            return s.Replace("\\", "\\\\")
                    .Replace("\"", "\\\"")
                    .Replace("\r", "\\r")
                    .Replace("\n", "\\n")
                    .Replace("\t", "\\t");
        }

        private static void EmitJson(Dictionary<string, object> fields)
        {
            var sb = new StringBuilder();
            sb.Append('{');
            bool first = true;
            foreach (var kv in fields)
            {
                if (!first) sb.Append(',');
                first = false;
                sb.Append('"').Append(EscapeJson(kv.Key)).Append("\":");
                if (kv.Value == null)
                {
                    sb.Append("null");
                }
                else if (kv.Value is bool)
                {
                    sb.Append(((bool)kv.Value) ? "true" : "false");
                }
                else if (kv.Value is int || kv.Value is long)
                {
                    sb.Append(kv.Value.ToString());
                }
                else
                {
                    sb.Append('"').Append(EscapeJson(kv.Value.ToString())).Append('"');
                }
            }
            sb.Append('}');

            lock (StdoutLock)
            {
                Console.Out.WriteLine(sb.ToString());
                Console.Out.Flush();
            }
        }
    }
}
