import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StoreProductsPage extends StatefulWidget {
  const StoreProductsPage({super.key});

  @override
  State<StoreProductsPage> createState() => _StoreProductsPageState();
}

class _StoreProductsPageState extends State<StoreProductsPage> {
  final _formKey = GlobalKey<FormState>();

  // Controller for the editable fields
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();

  bool _saving = false;
  String? _storeId;
  String? _selectedProductId;

  bool _useSizes = false;
  List<Map<String, dynamic>> _sizes = [];

  @override
  void initState() {
    super.initState();
    _resolveStoreId();
  }

  Future<void> _resolveStoreId() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await FirebaseFirestore.instance
      .collection('stores')
      .where('ownerId', isEqualTo: uid)
      .limit(1)
      .get();

    if (snap.docs.isNotEmpty) {
      setState(() => _storeId = snap.docs.first.id);
    } else {
      // no store for this user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No store found for this account')),
      );
    }
  }

  void _loadProductData(Map<String, dynamic> data, String productId) {
    _selectedProductId = productId;
    _nameCtrl.text = data['name'] ?? '';
    _descCtrl.text = data['description'] ?? '';
    _imageUrlCtrl.text = data['imageUrl'] ?? '';
    
    if (data['sizes'] is Map) {
      _useSizes = true;
      _sizes = (data['sizes'] as Map<String, dynamic>)
        .entries
        .map((e) => {
          'id': e.key.isNotEmpty ? e.key : DateTime.now().millisecondsSinceEpoch.toString(),
          'name': e.value['name'] ?? '',
          'price': e.value['price'] ?? 0,
          'stock': e.value['stock'] ?? 0
          })
        .toList();
      _priceCtrl.clear();
      _stockCtrl.clear();
    } else {
      _useSizes = false;
      _priceCtrl.text =
        data['price'] != null ? (data['price'] as num).toString() : '';
      _stockCtrl.text =
        data['stock'] != null ? (data['stock'] as num).toString() : '';
      _sizes.clear();
    }
    setState(() {});
  }

  Future<void> _save() async {
    if (_storeId == null) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final data = {
      'storeId': _storeId,
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'imageUrl': _imageUrlCtrl.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (_useSizes) {
      final sizesMap = {
        for (var s in _sizes)
          s['id']: {
            'name': s['name'],
            'price': s['price'],
            'stock': s['stock'],
          }
      };
      data['sizes'] = sizesMap;
      data['price'] = FieldValue.delete();
      data['stock'] = FieldValue.delete();
    } else {
      data['price'] = double.tryParse(_priceCtrl.text.trim()) ?? 0;
      data['stock'] = int.tryParse(_stockCtrl.text.trim()) ?? 0;
    }

    final products = FirebaseFirestore.instance.collection('products');

    if (_selectedProductId == null) {
      // create new product
      await products.add({
        ...data,
        'createdAt' : FieldValue.serverTimestamp(),
      });
    } else {
      // update existing
      await products.doc(_selectedProductId).set(data, SetOptions(merge: true));
    }

    setState(() {
      _saving = false;
      _selectedProductId = null;
      _formKey.currentState!.reset();
      _nameCtrl.clear();
      _descCtrl.clear();
      _imageUrlCtrl.clear();
      _priceCtrl.clear();
      _stockCtrl.clear();
      _sizes.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product saved')),
      );
    }
  }

  Future<void> _deleteProduct(String productId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted')),
        );
      }

      if (_selectedProductId == productId) {
        setState(() {
          _selectedProductId = null;
          _formKey.currentState!.reset();
          _nameCtrl.clear();
          _descCtrl.clear();
          _imageUrlCtrl.clear();
          _priceCtrl.clear();
          _stockCtrl.clear();
          _sizes.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_storeId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      body: Column(
        children: [
          // Floating card for editing fields
          Card(
            elevation: 4,
            margin: const EdgeInsets.all(6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SizedBox(
              height: 350,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (_imageUrlCtrl.text.trim().isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _imageUrlCtrl.text.trim(),
                            height: 120,
                            width: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade300,
                              height: 120,
                              width: 120,
                              alignment: Alignment.center,
                              child: const Text('Invalid image URL'),
                            ),
                          ),
                        )
                      else
                        const Text('Select a product to edit or add a new one'),
                      
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Product Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _imageUrlCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Image URL',
                          hintText: 'Pase direct image link',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),

                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Use size variants'),
                          Switch(
                            value: _useSizes,
                            onChanged: (v) => setState(() => _useSizes = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      if (!_useSizes) ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _priceCtrl,
                                keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Price',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _stockCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Stock',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ... [
                        Column(
                          children: [
                            for (int i=0; i<_sizes.length; i++)
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      key: ValueKey(_sizes[i]['id']),
                                      initialValue: _sizes[i]['name'].toString(),
                                      decoration: const InputDecoration(labelText: 'Size name'),
                                      onChanged: (v) => _sizes[i]['name'] = v,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      key: ValueKey(_sizes[i]['id']),
                                      initialValue: _sizes[i]['price'].toString(),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(labelText: 'Price'),
                                      onChanged: (v) => _sizes[i]['price'] = double.tryParse(v) ?? 0,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      key: ValueKey(_sizes[i]['id']),
                                      initialValue: _sizes[i]['stock'].toString(),
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(labelText: 'Stock'),
                                      onChanged: (v) => _sizes[i]['stock'] = int.tryParse(v) ?? 0,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => setState(() => _sizes.removeAt(i)),
                                  ),
                                ],
                              ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Add size'),
                                onPressed: () => setState(() => _sizes.add({
                                  'id': DateTime.now().millisecondsSinceEpoch.toString(),
                                  'name': '',
                                  'price': 0,
                                  'stock': 0,
                                })),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),
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
                          label: Text(_saving
                            ? 'Saving...'
                            : _selectedProductId == null
                              ? 'Add Product'
                              : 'Save Changes'),
                          onPressed: _saving ? null : _save,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Product List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                .collection('products')
                .where('storeId', isEqualTo: _storeId)
                .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No products yet.'));
                }

                final products = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, i) {
                    final doc = products[i];
                    final data = doc.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: data['imageUrl'] != null &&
                                (data['imageUrl'] as String).isNotEmpty
                          ? Image.network(
                              data['imageUrl'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.image_not_supported),
                        title: Text(data['name'] ?? 'Unnamed'),
                        subtitle: Builder(
                          builder: (_) {
                            if (data['sizes'] is Map) {
                              final sizes = (data['sizes'] as Map<String, dynamic>).values;
                              final prices = sizes
                                .map((s) => (s['price'] ?? 0) as num)
                                .toList();
                              final stocks = sizes
                                .map((s) => (s['stock'] ?? 0) as num)
                                .toList();
                              final minPrice = prices.isEmpty ? 0 : prices.reduce((a, b) => a < b ? a : b);
                              final maxPrice = prices.isEmpty ? 0 : prices.reduce((a, b) => a > b ? a : b);
                              final totalStock = stocks.fold<num>(0, (a, b) => a + b);

                              return Text(
                                prices.isEmpty
                                  ? 'No sizes'
                                  : '₱$minPrice  - ₱$maxPrice • Total stock: $totalStock',
                              );
                            } else {
                              return Text(
                                '₱${(data['price'] ?? 0)} • Stock: ${(data['stock'] ?? 0)}',
                              );
                            }
                          },
                        ),
                        onTap: () => _loadProductData(data, doc.id),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteProduct(doc.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}