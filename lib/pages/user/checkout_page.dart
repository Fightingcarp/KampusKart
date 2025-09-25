import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:kampus_kart/pages/me_page.dart';

class CartItem {
  final String productId;
  final String? sizeKey;
  final String? sizeName;
  final int quantity;
  final double unitPrice;
  final String storeId;
  final String sellerId;

  CartItem({
    required this.productId,
    this.sizeKey,
    this.sizeName,
    required this.quantity,
    required this.unitPrice,
    required this.storeId,
    required this.sellerId,
  });
}

class CheckoutPage extends StatefulWidget {
  final List<CartItem> items;
  final bool? isSingle;

  const CheckoutPage({
    super.key,
    required this.items,
    this.isSingle,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String? _phone;
  final _locationController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadUserPhone();
  }

  Future<void> _loadUserPhone() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (doc.exists) {
      setState(() {
        _phone = doc.data()?['phone'];
      });
    }
  }

  Future<void> _placeOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter delivery location')));
      return;
    }

    setState(() => _submitting = true);

    final total = widget.items.fold<double>(
      0,
      (sum, i) => sum + (i.unitPrice * i.quantity),
    );
    final ordersRef = FirebaseFirestore.instance.collection('orders').doc();

    final cartItemSnap = await FirebaseFirestore.instance
      .collection('carts')
      .doc(user.uid)
      .collection('items')
      .get();

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final productSnapshots = <String, DocumentSnapshot>{};
        String? storeName;

        for (final item in widget.items) {
          final productRef = FirebaseFirestore.instance.collection('products').doc(item.productId);
          productSnapshots[item.productId] = await transaction.get(productRef);

          if (storeName == null) {
            final storeRef = FirebaseFirestore.instance.collection('stores').doc(item.storeId);
            final storeSnap = await transaction.get(storeRef);
            storeName = storeSnap.data()?['name'] as String?;
          }
        }

        for (final item in widget.items) {
          final productRef = FirebaseFirestore.instance.collection('products').doc(item.productId);
          final data = productSnapshots[item.productId]!.data() as Map<String, dynamic>;

          if (item.sizeKey == null || item.sizeKey!.isEmpty) {
            final current = (data['stock'] ?? 0) as int;
            if (current < item.quantity) throw Exception('Not enough stock');
            transaction.update(productRef, {'stock': current - item.quantity});
          } else {
            final sizePath = 'sizes.${item.sizeKey}.stock';
            final current = ((data['sizes'] ?? const {})[item.sizeKey]['stock'] ?? 0) as int;
            if (current < item.quantity) throw Exception('Not enough stock');
            transaction.update(productRef, {sizePath: current - item.quantity});
          }
        }
        
        transaction.set(ordersRef, {
          'buyerId': user.uid,
          'buyerPhone': _phone,
          'deliveryLocation': _locationController.text.trim(),
          'storeId': widget.items.first.storeId,
          'storeName': storeName,
          'sellerId': widget.items.first.sellerId,
          'items': widget.items
            .map((i) => {
              'productId': i.productId,
              'sizeKey': i.sizeKey,
              'sizeName': i.sizeName,
              'quantity': i.quantity,
              'unitPrice': i.unitPrice,
            }).toList(),
          'status': 'on hold',
          'totalPrice': total,
          'createdAt': FieldValue.serverTimestamp(),
        });

        for (final doc in cartItemSnap.docs) {
          transaction.delete(doc.reference);
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Order placed!')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final total = widget.items.fold<double>(
      0,
      (sum, i) => sum + (i.unitPrice * i.quantity),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: widget.items.length,
                  itemBuilder: (context, index) {
                    final item = widget.items[index];

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('products')
                          .doc(item.productId)
                          .get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final data = snapshot.data!.data() as Map<String, dynamic>;
                        final productName = data['name'] ?? 'Unnamed product';
                        final imageUrl = data['imageUrl'];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: imageUrl != null
                                ? Image.network(
                                    imageUrl,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.image_not_supported),
                            title: Text(
                              productName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '₱${item.unitPrice.toStringAsFixed(2)} each\n'
                              'Qty: ${item.quantity}'
                              '${(item.sizeName?.isNotEmpty ?? false)
                                  ? ' | Size: ${item.sizeName}'
                                  : ''}',
                            ),
                            trailing: Text(
                              '₱${(item.unitPrice * item.quantity).toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              ListTile(
                leading: const Icon(Icons.phone),
                title: Text(
                  _phone ?? 'Loading...',
                  maxLines: 1,
                ),
                subtitle: const Text('Your phone number'),
                trailing: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => MePage()),
                    );
                  },
                  child: const Text('Edit in Settings'),
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Delivery location',
                  border: OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 20),

              Text(
                'Total: ₱${total.toStringAsFixed(2)}',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: _submitting ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Place Order'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}