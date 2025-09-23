import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:kampus_kart/pages/login_page.dart';
import 'package:kampus_kart/pages/customer_order_page.dart';

class MePage extends StatefulWidget {
  final bool isSeller;
  final bool ownsStore;
  final bool viewAsUser;
  final ValueChanged<bool>? onViewToggle;

  const MePage({
    super.key,
    this.isSeller = false,
    this.ownsStore = false,
    this.viewAsUser = false,
    this.onViewToggle,
  });

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _imageUrlController = TextEditingController();

  bool _loading = true;
  String? _photoUrl;
  late bool _viewAsUser;

  @override
  void initState() {
    super.initState();
    _viewAsUser = widget.viewAsUser;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser!;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = doc.data() ?? {};
    _nameController.text = data['userName'] ?? user.displayName ?? '';
    _phoneController.text = data['phone'] ?? '';
    _photoUrl = data['photoUrl'] ?? user.photoURL ?? '';
    _imageUrlController.text = _photoUrl ?? '';

    setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser!;
    final trimmedName = _nameController.text.trim();
    final trimmedPhone = _phoneController.text.trim();
    final trimmedPhoto = _imageUrlController.text.trim();

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'userName': trimmedName,
      'phone': trimmedPhone,
      'photoUrl': trimmedPhoto,
    }, SetOptions(merge: true));

    await user.updateDisplayName(trimmedName);
    await user.updatePhotoURL(trimmedPhoto);

    setState(() => _photoUrl = trimmedPhoto);

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated')));
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.isSeller && widget.ownsStore)
              Card(
                color: Colors.grey.shade100,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Store View'),
                      Switch(
                        value: _viewAsUser,
                        onChanged: (val) {
                          setState(() => _viewAsUser = val);
                          if (widget.onViewToggle != null) {
                            widget.onViewToggle!(val);
                          }
                        },
                      ),
                      const Text('User View'),
                    ],
                  ),
                ),
              ),

            Card(
              margin: const EdgeInsets.symmetric(vertical: 12),
              child: ListTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text('My orders'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CustomerOrdersPage()),
                  );
                },
              ),
            ),
            // Profile Picture
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: 
                (_photoUrl != null && _photoUrl!.isNotEmpty)
                    ? NetworkImage(_photoUrl!)
                    : null,
              child: (_photoUrl == null || _photoUrl!.isEmpty)
                  ? const Icon(Icons.person, size: 60, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 16),

            // Name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),

            // Phone
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),

            // Image URL 
            TextField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Profile Image URL',
                hintText: 'https://example.com/photo.jpg',
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save Changes'),
              onPressed: _saveProfile,
            ),
          ],
        ),
      ),
    );
  }
}
