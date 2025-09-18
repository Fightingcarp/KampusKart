import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StoreSettingsPage extends StatefulWidget {
  const StoreSettingsPage({super.key});

  @override
  State<StoreSettingsPage> createState() => _StoreSettingsPageState();
}

// Controller for editable fields
class _StoreSettingsPageState extends State<StoreSettingsPage> {
    final _formKey = GlobalKey<FormState>();
    final _nameCtrl = TextEditingController();
    final _descCtrl = TextEditingController();
    final _logoUrlCtrl = TextEditingController();
    final _bannerUrlCtrl = TextEditingController();
    final _contactPhoneCtrl = TextEditingController();
    final _contactEmailCtrl = TextEditingController();

    bool _saving = false;
    String? _storeDocId; 

    @override
    void initState() {
      super.initState();
      _loadStoreData();
    }

    Future<void> _loadStoreData() async {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // 🔑 Query using the ownerId field
      final snap = await FirebaseFirestore.instance
          .collection('stores')
          .where('ownerId', isEqualTo: uid)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final doc = snap.docs.first;
        final data = doc.data();

        _storeDocId = doc.id;               
        _nameCtrl.text = data['name'] ?? '';
        _descCtrl.text = data['description'] ?? '';
        _logoUrlCtrl.text = data['logoUrl'] ?? '';
        _bannerUrlCtrl.text = data['bannerUrl'] ?? '';
        _contactEmailCtrl.text = data['contactEmail'] ?? '';
        _contactPhoneCtrl.text = data['contactPhone'] ?? '';
        setState(() {});
      } else {
        // No store yet — leave fields blank
        _storeDocId = null;
      }
    }

    Future<void> _save() async {
      if (!_formKey.currentState!.validate()) return;

      setState(() => _saving = true);

      final uid = FirebaseAuth.instance.currentUser!.uid;
      final data = {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'logoUrl': _logoUrlCtrl.text.trim(),
        'bannerUrl': _bannerUrlCtrl.text.trim(),
        'contactEmail': _contactPhoneCtrl.text.trim(),
        'contactPhone': _contactEmailCtrl.text.trim(),
        'ownerId': uid, // always ensure ownerId is set
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final stores = FirebaseFirestore.instance.collection('stores');

      if (_storeDocId == null) {
        // Create a new store document
        final newDoc = await stores.add(data);
        _storeDocId = newDoc.id;
      } else {
        // Update the existing store document
        await stores.doc(_storeDocId).set(data, SetOptions(merge: true));
      }

      setState(() => _saving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Store settings saved!')),
        );
      }
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center( 
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600), 
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Edit Store Information',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Store Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _logoUrlCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Logo Image URL',
                          hintText: 'Paste a direct link from your image host',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final uri = Uri.tryParse(v.trim());
                          return (uri == null || !uri.isAbsolute)
                              ? 'Enter a valid URL'
                              : null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),

                      if (_logoUrlCtrl.text.trim().isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _logoUrlCtrl.text.trim(),
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, st) => Container(
                              color: Colors.grey.shade300,
                              height: 150,
                              width: double.infinity,
                              alignment: Alignment.center,
                              child: const Text('Invalid image URL'),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _logoUrlCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Banner Image URL',
                          hintText: 'Paste a direct link from your image host',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final uri = Uri.tryParse(v.trim());
                          return (uri == null || !uri.isAbsolute)
                              ? 'Enter a valid URL'
                              : null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),

                      if (_bannerUrlCtrl.text.trim().isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _bannerUrlCtrl.text.trim(),
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, st) => Container(
                              color: Colors.grey.shade300,
                              height: 150,
                              width: double.infinity,
                              alignment: Alignment.center,
                              child: const Text('Invalid image URL'),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _contactEmailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _contactPhoneCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(_saving ? 'Saving...' : 'Save Changes'),
                          onPressed: _saving ? null : _save,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
