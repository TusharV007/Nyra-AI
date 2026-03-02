import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart';
import '../../main.dart'; // For AuthWrapper
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
      // 1. Simulate network and ML processing delay
      await Future.delayed(const Duration(seconds: 2));

      final random = Random();
      final targetName = user.displayName ?? 'Anonymous';

      // 2. Mocking Results directly in Flutter
      List<Map<String, dynamic>> results = [
        {
          "title": "Unauthorized synthetic media of $targetName on TikTok",
          "domain": "tiktok.com",
          "prob": 92.5 + random.nextDouble() * 7.3,
        },
        {
          "title": "Possible voice clone of $targetName detected",
          "domain": "twitter.com",
          "prob": 45.0 + random.nextDouble() * 30.0,
        },
        {
          "title": "$targetName verified original vlog",
          "domain": "youtube.com",
          "prob": 1.0 + random.nextDouble() * 14.0,
        },
      ];

      final batch = FirebaseFirestore.instance.batch();
      final evidenceRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('evidence');

      final now = DateTime.now();
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final dateStr =
          "${months[now.month - 1]} ${now.day.toString().padLeft(2, '0')}, ${now.year}";
      final timeStr =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      int findingsCount = 0;

      for (var result in results) {
        final probability = result['prob'] as double;
        String severity;
        if (probability > 85)
          severity = "Critical";
        else if (probability > 50)
          severity = "High";
        else if (probability > 20)
          severity = "Medium";
        else
          severity = "Low";

        // Generate 32-character hex mock hash
        final mockHash =
            "0x${List.generate(32, (_) => random.nextInt(16).toRadixString(16)).join('')}";

        final docRef = evidenceRef.doc();
        batch.set(docRef, {
          "platform": result['domain'],
          "severity": severity,
          "hash": mockHash,
          "date": dateStr,
          "timestamp": FieldValue.serverTimestamp(),
          "target_name": targetName,
          "url":
              "https://${result['domain']}/post/${100000 + random.nextInt(900000)}",
          "status":
              "Reality Defender: ${probability.toStringAsFixed(2)}% Deepfake",
        });
        findingsCount++;
      }

      // 3. Log the scan execution event
      final logRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('scan_logs')
          .doc();
      batch.set(logRef, {
        "timestamp": FieldValue.serverTimestamp(),
        "date": "$dateStr - $timeStr",
        "findings_count": findingsCount,
        "target_name": targetName,
        "status": "Completed",
      });

      // 4. Commit to Firestore
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan complete: Done Found $findingsCount')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving scan: $e')));
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
