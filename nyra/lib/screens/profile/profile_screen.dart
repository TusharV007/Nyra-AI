import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _alertsEnabled = true;
  bool _isUploading = false;
  final _picker = ImagePicker();
  final User? user = FirebaseAuth.instance.currentUser;

  Future<void> _uploadPhoto() async {
    if (user == null) return;

    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final file = File(pickedFile.path);
      final downloadUrl = await StorageService().uploadProfilePhoto(
        user!.uid,
        file,
      );

      if (downloadUrl != null) {
        await user!.updatePhotoURL(downloadUrl);
        await DatabaseService().updateProfilePhoto(user!.uid, downloadUrl);
        await user!.reload(); // Reload user to update photoURL in UI

        if (mounted) {
          setState(() {}); // Trigger rebuild to show new photo
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading photo: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Identity'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfileHeader(context),
              const SizedBox(height: 32),
              _buildPhotoUploadSection(context),
              const SizedBox(height: 32),
              _buildSettingsSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: const Color(0xFF1A1A1A),
          backgroundImage: user?.photoURL != null
              ? NetworkImage(user!.photoURL!)
              : null,
          child: user?.photoURL == null
              ? const Icon(Icons.person, size: 50, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          user?.displayName ?? 'Anonymous User',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          user?.email ?? 'No email',
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildPhotoUploadSection(BuildContext context) {
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
          Text(
            'Identity Reference Photo',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Upload a clear photo of your face. This is used by our AI to scan the internet for unauthorized deepfakes matching your likeness.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _isUploading ? null : _uploadPhoto,
            icon: _isUploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.camera_alt_outlined),
            label: Text(_isUploading ? 'UPLOADING...' : 'UPDATE PHOTO'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Preferences', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Scan Frequency'),
          subtitle: const Text('Daily'),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () {},
        ),
        const Divider(color: Color(0xFF333333)),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Alert Notifications'),
          subtitle: const Text('Email & Push'),
          trailing: Switch(
            value: _alertsEnabled,
            activeThumbColor: Colors.white,
            onChanged: (val) async {
              setState(() => _alertsEnabled = val);
              if (user != null) {
                try {
                  await DatabaseService().updatePreferences(user!.uid, val);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Preferences updated successfully'),
                      ),
                    );
                  }
                } catch (e) {
                  setState(() => _alertsEnabled = !val); // Revert on failure
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update preferences: $e'),
                      ),
                    );
                  }
                }
              }
            },
          ),
        ),
      ],
    );
  }
}
