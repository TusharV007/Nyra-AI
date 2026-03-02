import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isScanning = false;

  Future<void> _runManualScan() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to run a scan.')),
      );
      return;
    }

    if (user.photoURL == null || user.photoURL!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please upload an Identity Reference Photo in the Profile tab before running a scan.',
          ),
        ),
      );
      return;
    }

    setState(() => _isScanning = true);

    try {
      // Use 10.0.2.2 for Android Emulator to hit localhost.
      // For iOS Simulator or web it would be 127.0.0.1.
      final url = Uri.parse('http://10.0.2.2:8000/api/scan');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': user.uid,
          'target_name': user.displayName ?? 'Anonymous',
          'photo_url': user.photoURL,
        }),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          final msg = data["message"] ?? "Done";
          final count = data["findings_count"] ?? 0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Scan complete: $msg Found $count')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Scan failed with status: ${response.statusCode}'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error contacting backend: $e')));
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false, // Hide back button
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
      ),
      body: SafeArea(child: _buildStreamingDashboard(context)),
    );
  }

  Widget _buildStreamingDashboard(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Please log in.'));

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: DatabaseService().strScanLogs(user.uid),
      builder: (context, scanSnapshot) {
        final scanLogs = scanSnapshot.data ?? [];

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: DatabaseService().strEvidence(user.uid),
          builder: (context, evidenceSnapshot) {
            final evidence = evidenceSnapshot.data ?? [];

            return ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                _buildStatusCard(context),
                const SizedBox(height: 32),
                _buildStatisticsSection(context, scanLogs, evidence),
                const SizedBox(height: 32),
                _buildRecentActivitySection(context, scanLogs),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _isScanning ? null : _runManualScan,
                  icon: _isScanning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: Text(_isScanning ? 'SCANNING...' : 'RUN MANUAL SCAN'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.security,
                  color: Colors.black,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monitoring Active',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your digital identity is protected.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(
    BuildContext context,
    List<Map<String, dynamic>> scanLogs,
    List<Map<String, dynamic>> evidence,
  ) {
    // Calculate "Scans Today" (within last 24h)
    int scansToday = scanLogs.length;

    // Calculate Alerts
    int totalAlerts = evidence.length;

    // Calculate Unique Platforms
    Set<String> platforms = {};
    for (var ev in evidence) {
      if (ev['platform'] != null) platforms.add(ev['platform']);
    }
    int totalPlatforms = platforms.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Overview', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                context,
                scansToday.toString(),
                'Scans Total',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatItem(context, totalAlerts.toString(), 'Alerts'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatItem(
                context,
                totalPlatforms.toString(),
                'Platforms',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection(
    BuildContext context,
    List<Map<String, dynamic>> scanLogs,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Activity', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        if (scanLogs.isEmpty)
          const Text(
            'No recent activity.',
            style: TextStyle(color: Colors.grey),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: scanLogs.length > 5 ? 5 : scanLogs.length, // Max 5
            separatorBuilder: (context, index) =>
                const Divider(color: Color(0xFF333333), height: 1),
            itemBuilder: (context, index) {
              final log = scanLogs[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  log['findings_count'] > 0
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline,
                  color: log['findings_count'] > 0
                      ? Colors.redAccent
                      : Colors.white,
                ),
                title: const Text('Automated Scan Completed'),
                subtitle: Text(log['date'] ?? 'Unknown Date'),
                trailing: Text(
                  log['findings_count'] > 0
                      ? "${log['findings_count']} found"
                      : 'Clear',
                  style: const TextStyle(color: Colors.grey),
                ),
              );
            },
          ),
      ],
    );
  }
}
