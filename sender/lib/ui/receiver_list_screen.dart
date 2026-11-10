import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../discovery/discovery_cubit.dart';
import '../discovery/discovery_state.dart';
import '../session/session_cubit.dart';
import '../session/session_state.dart';
import 'mirroring_screen.dart';

class ReceiverListScreen extends StatefulWidget {
  const ReceiverListScreen({super.key});

  @override
  State<ReceiverListScreen> createState() => _ReceiverListScreenState();
}

class _ReceiverListScreenState extends State<ReceiverListScreen> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '7400');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<DiscoveryCubit>().state is DiscoveryIdle) {
        context.read<DiscoveryCubit>().startDiscovery();
      }
    });
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _connectToReceiver(BuildContext context, ReceiverInfo receiver) {
    context.read<SessionCubit>().startMirroring(receiver);
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const MirroringScreen(),
      ),
    );
  }

  void _connectManual(BuildContext context) {
    final ip = _ipController.text.trim();
    final portText = _portController.text.trim();
    if (ip.isEmpty) return;
    final port = int.tryParse(portText) ?? 7400;
    final receiver = ReceiverInfo(name: 'Display ($ip)', host: ip, port: port);
    _connectToReceiver(context, receiver);
  }

  void _showManualConnectSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.settings_ethernet_rounded,
                          color: Color(0xFF1565C0), size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Connect Directly via IP',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Color(0xFF172B45),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(bottomSheetContext),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Enter the IP address shown on the receiver screen (useful if mDNS is disabled on your Wi-Fi router).',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.3),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _ipController,
                decoration: const InputDecoration(
                  labelText: 'Receiver IP Address',
                  hintText: 'e.g. 192.168.1.150',
                  prefixIcon: Icon(Icons.wifi_rounded, size: 20),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  hintText: '7400',
                  prefixIcon: Icon(Icons.numbers_rounded, size: 20),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(bottomSheetContext);
                  _connectManual(context);
                },
                icon: const Icon(Icons.cast_rounded),
                label: const Text('Connect to Display'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SessionCubit, SessionState>(
      listenWhen: (previous, current) => current is SessionConnecting,
      listener: (context, state) {
        if (state is SessionConnecting) {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => const MirroringScreen(),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 16,
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/comssu_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'ComSSU Cast',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Color(0xFF172B45),
                    ),
                  ),
                  Text(
                    'Wireless Display System',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_ethernet_rounded,
                  color: Color(0xFF1565C0)),
              tooltip: 'Connect by IP',
              onPressed: () => _showManualConnectSheet(context),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1565C0)),
              tooltip: 'Scan for Displays',
              onPressed: () => context.read<DiscoveryCubit>().startDiscovery(),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // Institutional university banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              color: Colors.white,
              child: Row(
                children: const [
                  Icon(Icons.school_rounded, size: 15, color: Color(0xFF64748B)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Computer Science Students' Society (ComSSU) • University of Makeni",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Expanded(
              child: BlocBuilder<DiscoveryCubit, DiscoveryState>(
                builder: (context, discoveryState) {
                  return switch (discoveryState) {
                    DiscoveryIdle() => _buildIdleContent(context),
                    DiscoverySearching() => _buildSearchingContent(context),
                    DiscoveryFound(:final receivers) =>
                      _buildFoundContent(context, receivers),
                    DiscoveryTimeout() => _buildTimeoutContent(context),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdleContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Image.asset('assets/comssu_logo.png', fit: BoxFit.contain),
          ),
          const SizedBox(height: 20),
          const Text(
            'Ready to Cast',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF172B45),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Search for available ComSSU wireless displays on your network.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.read<DiscoveryCubit>().startDiscovery(),
            icon: const Icon(Icons.search_rounded),
            label: const Text('Scan for Displays'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchingContent(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                const SizedBox(
                  width: 110,
                  height: 110,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF29B6F6)),
                    backgroundColor: Color(0xFFE1F5FE),
                  ),
                ),
                Container(
                  width: 84,
                  height: 84,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1565C0).withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Image.asset(
                    'assets/comssu_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const Text(
              'Scanning for ComSSU Displays...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF172B45),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Searching for active wireless receivers on your local Wi-Fi network.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: () => _showManualConnectSheet(context),
              icon: const Icon(Icons.settings_ethernet_rounded, size: 18),
              label: const Text('Connect via IP Address'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1565C0),
                side: const BorderSide(color: Color(0xFF29B6F6)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoundContent(
      BuildContext context, List<ReceiverInfo> receivers) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF29B6F6),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Available Displays (${receivers.length})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172B45),
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => context.read<DiscoveryCubit>().startDiscovery(),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh', style: TextStyle(fontSize: 13)),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1565C0),
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...receivers.map((receiver) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _connectToReceiver(context, receiver),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F9FD),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(
                        Icons.tv_rounded,
                        color: Color(0xFF1565C0),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            receiver.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF172B45),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.wifi_rounded,
                                  size: 13, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text(
                                '${receiver.host}:${receiver.port}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _connectToReceiver(context, receiver),
                      icon: const Icon(Icons.cast_rounded, size: 16),
                      label: const Text('Cast'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton.icon(
            onPressed: () => _showManualConnectSheet(context),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Display by IP'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1565C0),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeoutContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF4F9FD),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.tv_off_rounded,
                      size: 32,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Displays Detected',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF172B45),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ensure the ComSSU Wireless Display System is running on the target screen and both devices are connected to the same Wi-Fi network.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () =>
                        context.read<DiscoveryCubit>().startDiscovery(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Scan Again'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.settings_ethernet_rounded,
                          color: Color(0xFF1565C0), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Direct IP Connection',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF172B45),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'If mDNS discovery is disabled on your network router, connect directly using the IP displayed on the screen:',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _ipController,
                    decoration: const InputDecoration(
                      labelText: 'Display IP Address',
                      hintText: 'e.g. 192.168.1.150',
                      prefixIcon: Icon(Icons.wifi_rounded, size: 20),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _portController,
                    decoration: const InputDecoration(
                      labelText: 'Port',
                      hintText: '7400',
                      prefixIcon: Icon(Icons.numbers_rounded, size: 20),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _connectManual(context),
                    icon: const Icon(Icons.cast_rounded),
                    label: const Text('Connect to Display'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
