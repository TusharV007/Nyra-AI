import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScanResultsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> findings;

  const ScanResultsScreen({super.key, required this.findings});

  @override
  State<ScanResultsScreen> createState() => _ScanResultsScreenState();
}

class _ScanResultsScreenState extends State<ScanResultsScreen> {
  late List<Map<String, dynamic>> _findings;

  @override
  void initState() {
    super.initState();
    _findings = List.from(widget.findings);
  }

  Future<void> _launchUrl(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open link.')));
      }
    }
  }

  Future<void> _secureEvidence(Map<String, dynamic> finding, int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final db = FirebaseFirestore.instance;
      final docRef = db
          .collection('users')
          .doc(user.uid)
          .collection('evidence')
          .doc();

      await docRef.set({
        ...Map<String, dynamic>.from(finding),
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evidence secured to your locker!')),
        );
        setState(() {
          _findings.removeAt(index);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error securing evidence: $e')));
      }
    }
  }

  void _deleteFinding(int index) {
    setState(() {
      _findings.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Results')),
      body: SafeArea(
        child: Column(
          children: [
            _buildSummaryHeader(context),
            Expanded(child: _buildFindingsList(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF333333))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New Findings', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Review scan results before securing them to evidence.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildFindingsList(BuildContext context) {
    if (_findings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 60, color: Colors.grey[800]),
            const SizedBox(height: 16),
            Text(
              'All results reviewed',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _findings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final record = _findings[index];
        return _buildFindingCard(context, record, index);
      },
    );
  }

  Widget _buildFindingCard(
    BuildContext context,
    Map<String, dynamic> record,
    int index,
  ) {
    final severity = record['severity'] ?? 'Medium';
    final isHigh = severity == 'High' || severity == 'Critical';
    final imageUrl = record['image_url'] as String?;

    Color severityColor;
    switch (severity) {
      case 'Critical':
        severityColor = const Color(0xFFFF3B3B);
        break;
      case 'High':
        severityColor = Colors.redAccent;
        break;
      case 'Medium':
        severityColor = Colors.orange;
        break;
      default:
        severityColor = Colors.grey;
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHigh
              ? severityColor.withValues(alpha: 0.4)
              : const Color(0xFF333333),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Finding Photo — tappable to open source URL
          if (imageUrl != null && imageUrl.isNotEmpty)
            GestureDetector(
              onTap: () => _launchUrl(context, record['url'] as String?),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
                child: Stack(
                  children: [
                    Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: double.infinity,
                          height: 180,
                          color: const Color(0xFF111111),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white54,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                    ),
                    // Deepfake label overlay
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: severityColor.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              severity.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ), // closes ClipRRect
            ) // closes GestureDetector
          else
            _buildImagePlaceholder(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),

          // Card Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      record['platform'] ?? 'Unknown Source',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      record['date'] ?? '',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
                if (record['title'] != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    record['title'],
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 14),
                _buildDetailRow('Hash', record['hash'] ?? 'Pending...'),
                const SizedBox(height: 6),
                if (record['url'] != null) ...[
                  GestureDetector(
                    onTap: () => _launchUrl(context, record['url'] as String?),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Source',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            record['url'],
                            style: const TextStyle(
                              color: Color(0xFF6C9EFF),
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFF6C9EFF),
                            ),
                            textAlign: TextAlign.right,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                _buildDetailRow('AI Score', record['status'] ?? 'Verified'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        // DELETE BUTTON
                        onPressed: () => _deleteFinding(index),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('DELETE'),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        // SECURE EVIDENCE BUTTON
                        onPressed: () => _secureEvidence(record, index),
                        icon: const Icon(Icons.shield_outlined, size: 16),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('SECURE EVIDENCE'),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder({BorderRadius? borderRadius}) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Container(
        width: double.infinity,
        height: 120,
        color: const Color(0xFF111111),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_search, color: Colors.white24, size: 36),
            SizedBox(height: 8),
            Text(
              'No image captured',
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
