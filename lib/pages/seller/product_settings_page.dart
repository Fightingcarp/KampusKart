import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StoreProductsPage extends StatefulWidget {
  const StoreProductsPage({super.key});

  @override
  State<StoreProductsPage> createState() => _StoreProductsPageState();
}

class _StoreProductsPageState extends State<StoreProductsPage> {
  String? _storeId;

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No store found for this account')),
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
      await FirebaseFirestore.instance.collection('products').doc(productId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted')),
        );
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
      body: StreamBuilder<QuerySnapshot>(
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
                  leading: data['imageUrl'] != null && (data['imageUrl'] as String).isNotEmpty
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
                        final prices = sizes.map((s) => (s['price'] ?? 0) as num).toList();
                        final stocks = sizes.map((s) => (s['stock'] ?? 0) as num).toList();
                        final minPrice = prices.isEmpty ? 0 : prices.reduce((a, b) => a < b ? a : b);
                        final maxPrice = prices.isEmpty ? 0 : prices.reduce((a, b) => a > b ? a : b);
                        final totalStock = stocks.fold<num>(0, (a, b) => a + b);
                        return Text(
                          prices.isEmpty
                              ? 'No sizes'
                              : '₱$minPrice  - ₱$maxPrice • stock: $totalStock',
                        );
                      } else {
                        return Text(
                          '₱${(data['price'] ?? 0)} • Stock: ${(data['stock'] ?? 0)}',
                        );
                      }
                    },
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductEditPage(
                                productId: doc.id,
                                initialData: data,
                                storeId: _storeId!,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteProduct(doc.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductEditPage(
                productId: null,
                initialData: null,
                storeId: _storeId!,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ProductEditPage extends StatefulWidget {
  final String? productId;
  final Map<String, dynamic>? initialData;
  final String storeId;
  const ProductEditPage({super.key, required this.productId, required this.initialData, required this.storeId});

  @override
  State<ProductEditPage> createState() => _ProductEditPageState();
}

class _ProductEditPageState extends State<ProductEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  bool _saving = false;
  bool _useSizes = false;
  List<Map<String, dynamic>> _sizes = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      final d = widget.initialData!;
      _nameCtrl.text = d['name'] ?? '';
      _descCtrl.text = d['description'] ?? '';
      _imageUrlCtrl.text = d['imageUrl'] ?? '';
      if (d['sizes'] is Map) {
        _useSizes = true;
        _sizes = (d['sizes'] as Map<String, dynamic>).entries
            .map((e) => {
                  'id': e.key,
                  'name': e.value['name'],
                  'price': e.value['price'],
                  'stock': e.value['stock'],
                })
            .toList();
      } else {
        _priceCtrl.text = (d['price'] ?? 0).toString();
        _stockCtrl.text = (d['stock'] ?? 0).toString();
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {
      'storeId': widget.storeId,
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
    if (widget.productId == null) {
      final createData = {...data, 'createdAt': FieldValue.serverTimestamp()};
      if (_useSizes) {
        createData.remove('price');
        createData.remove('stock');
      }
      await products.add(createData);
    } else {
      await products.doc(widget.productId).set(data, SetOptions(merge: true));
    }
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.productId == null ? 'Add Product' : 'Edit Product')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_imageUrlCtrl.text.trim().isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _imageUrlCtrl.text.trim(),
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
                const Text('No image preview'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
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
              if (!_useSizes)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                )
              else
                Column(
                  children: [
                    for (int i = 0; i < _sizes.length; i++)
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              key: ValueKey('${_sizes[i]['id']}-name'),
                              initialValue: _sizes[i]['name'].toString(),
                              decoration: const InputDecoration(labelText: 'Size name'),
                              onChanged: (v) => _sizes[i]['name'] = v,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              key: ValueKey('${_sizes[i]['id']}-price'),
                              initialValue: _sizes[i]['price'].toString(),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Price'),
                              onChanged: (v) => _sizes[i]['price'] = double.tryParse(v) ?? 0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              key: ValueKey('${_sizes[i]['id']}-stock'),
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
                      : widget.productId == null
                          ? 'Add Product'
                          : 'Save Changes'),
                  onPressed: _saving ? null : _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
