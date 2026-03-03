import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/database_service.dart';

class EvidenceScreen extends StatelessWidget {
  const EvidenceScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evidence Locker'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSummaryHeader(context),
            Expanded(child: _buildEvidenceList(context)),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secured Findings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Blockchain timestamped evidence.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF333333)),
            ),
            child: const Text('Live Updates'),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceList(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: DatabaseService().strEvidence(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final records = snapshot.data ?? [];

        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined, size: 60, color: Colors.grey[800]),
                const SizedBox(height: 16),
                Text(
                  'No evidence found.',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your identity is secure.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: records.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final record = records[index];
            return _buildEvidenceCard(context, record);
          },
        );
      },
    );
  }

  Widget _buildEvidenceCard(BuildContext context, Map<String, dynamic> record) {
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

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final docId = record['id'] as String?;

    return Stack(
      children: [
        Container(
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
              // Evidence Photo — tappable to open source URL
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
                          errorBuilder: (_, __, ___) =>
                              _buildImagePlaceholder(),
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
                    // Platform + Date row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                isHigh
                                    ? Icons.warning_amber_rounded
                                    : Icons.info_outline,
                                color: isHigh ? severityColor : Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Detected on ${record["platform"]}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          record['date'] ?? '',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    if (record['title'] != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        record['title'],
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 14),
                    _buildDetailRow('Hash', record['hash'] ?? 'Pending...'),
                    const SizedBox(height: 6),
                    if (record['url'] != null) ...[
                      GestureDetector(
                        onTap: () =>
                            _launchUrl(context, record['url'] as String?),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Source',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
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
                    _buildDetailRow(
                      'AI Score',
                      record['status'] ?? 'Timestamped & Verified',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Generating Legal PDF Report...',
                                  ),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                              await _exportPdfReport(record);
                            },
                            icon: const Icon(Icons.picture_as_pdf, size: 16),
                            label: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('EXPORT PDF'),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('TAKEDOWN'),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
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
        ), // closes outer Container
        // Floating trash icon — top-right corner
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () async {
                if (uid == null || docId == null) return;
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF1A1A1A),
                    title: const Text('Delete Evidence'),
                    content: const Text(
                      'Remove this evidence record? This cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await DatabaseService().deleteEvidence(uid, docId);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ], // closes Stack children
    ); // closes Stack
  } // closes _buildEvidenceCard

  Future<void> _exportPdfReport(Map<String, dynamic> record) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'NYRA AI - EVIDENCE LOCKER',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.Text(
                      'LEGAL REPORT PREPARED: ${DateTime.now().toIso8601String().split('T')[0]}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Title
              pw.Text(
                'Notice of Unauthorized Likeness Use',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'This document serves as timestamped evidence of unauthorized deepfake or likeness reproduction, crawled by Nyra AI engines.',
              ),
              pw.SizedBox(height: 30),

              // Details table
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(8),
                  ),
                ),
                child: pw.Column(
                  children: [
                    _buildPdfRow(
                      'Target Identity',
                      record['target_name'] ?? 'Unknown',
                    ),
                    pw.Divider(),
                    _buildPdfRow(
                      'Platform/Domain',
                      record['platform'] ?? 'Unknown',
                    ),
                    pw.Divider(),
                    _buildPdfRow('Content Title', record['title'] ?? 'N/A'),
                    pw.Divider(),
                    _buildPdfRow(
                      'AI Score/Status',
                      record['status'] ?? 'Verified',
                    ),
                    pw.Divider(),
                    _buildPdfRow('Severity', record['severity'] ?? 'Medium'),
                    pw.Divider(),
                    _buildPdfRow('Source URL', record['url'] ?? 'N/A'),
                    pw.Divider(),
                    _buildPdfRow('Date Secured', record['date'] ?? 'Unknown'),
                    pw.Divider(),
                    _buildPdfRow('Cryptographic Hash', record['hash'] ?? 'N/A'),
                  ],
                ),
              ),
              pw.SizedBox(height: 40),

              // Signoff
              pw.Text(
                'This report was automatically synthesized by Nyra AI Deepfake Scanners.',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Nyra_Evidence_${record['target_name'] ?? 'Report'}.pdf',
    );
  }

  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(flex: 5, child: pw.Text(value)),
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
