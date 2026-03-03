import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart';
import '../../main.dart'; // For AuthWrapper
import '../evidence/scan_results_screen.dart';
import 'package:flutter/material.dart';

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
      // Since you are debugging on a physical device, we must use your computer's
      // actual local network IP address instead of localhost or the emulator alias.
      final String baseUrl = 'http://10.29.117.168:8000';

      // 1. Call the backend — it performs the AI analysis and returns JSON results
      final url = Uri.parse('$baseUrl/api/scan');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'uid': user.uid,
              'target_name': user.displayName ?? 'Anonymous',
              'photo_url': user.photoURL,
            }),
          )
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () => throw Exception('Connection to server timed out.'),
          );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> findings = data['findings'] ?? [];

        // 2. Log the scan event
        final db = FirebaseFirestore.instance;
        final logRef = db
            .collection('users')
            .doc(user.uid)
            .collection('scan_logs')
            .doc();

        await logRef.set({
          'timestamp': FieldValue.serverTimestamp(),
          'date': DateTime.now().toString().substring(0, 16),
          'findings_count': findings.length,
          'target_name': user.displayName ?? 'Anonymous',
          'status': 'Completed',
          'findings':
              findings, // Store the raw results so they can be viewed later
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Scan complete! Found ${findings.length} result(s).',
              ),
            ),
          );

          // Navigate to the staging screen to review results before saving
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScanResultsScreen(
                findings: List<Map<String, dynamic>>.from(findings),
              ),
            ),
          );
        }
      } else {
        // Show the actual backend error detail for debugging
        String detail = response.body;
        try {
          final decoded = jsonDecode(response.body);
          detail = decoded['detail']?.toString() ?? response.body;
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scan failed (${response.statusCode}): $detail'),
            duration: const Duration(seconds: 8),
          ),
        );
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
            tooltip: 'Clear all evidence data',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1A1A1A),
                  title: const Text('Clear Evidence Data'),
                  content: const Text(
                    'This will delete all saved scan results so you can run a fresh scan. Continue?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        'Clear',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true && mounted) {
                await DatabaseService().clearAllEvidence(user.uid);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All evidence cleared. Run a new scan!'),
                    ),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (c) => const AuthWrapper()),
                  (route) => false,
                );
              }
            },
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
                onTap: () {
                  final storedFindings = log['findings'] as List<dynamic>?;
                  if (storedFindings != null && storedFindings.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScanResultsScreen(
                          findings: List<Map<String, dynamic>>.from(
                            storedFindings,
                          ),
                        ),
                      ),
                    );
                  } else if (log['findings_count'] == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('This scan found 0 results.'),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Scan details not available. Old log format.',
                        ),
                      ),
                    );
                  }
                },
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
