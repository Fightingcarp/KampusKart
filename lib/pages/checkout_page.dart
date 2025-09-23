import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:kampus_kart/pages/me_page.dart';

class CheckoutPage extends StatefulWidget {
  final String productId;
  final String? sizeKey;
  final String? sizeName;    // for display
  final int quantity;
  final double unitPrice;
  final String storeId;
  final String sellerId;    // ownerId of the store

  const CheckoutPage({
    super.key,
    required this.productId,
    required this.sizeKey,
    required this.sizeName,
    required this.quantity,
    required this.unitPrice,
    required this.storeId,
    required this.sellerId,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String? _phone;                // fetched from users collection
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

    final total = widget.unitPrice * widget.quantity;
    final productRef =
        FirebaseFirestore.instance.collection('products').doc(widget.productId);
    final storeRef =
        FirebaseFirestore.instance.collection('stores').doc(widget.storeId);
    final ordersRef = FirebaseFirestore.instance.collection('orders').doc();

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(productRef);
        if (!snapshot.exists) {
          throw Exception('Product not found');
        }

        final storeSnap = await transaction.get(storeRef);
        if (!storeSnap.exists) {
          throw Exception('Store not found');
        }
        final storeName = (storeSnap.data() as Map<String, dynamic>)['name'];

        final data = snapshot.data() as Map<String, dynamic>;

        if (widget.sizeKey == null || widget.sizeKey!.isEmpty) {
          final current = (data['stock'] ?? 0) as int;
          if (current < widget.quantity) {
            throw Exception('Not enough stock');
          }
          transaction.update(productRef, {'stock': current - widget.quantity});
        } else {
          final sizePath = 'sizes.${widget.sizeKey}.stock';
          final current =
              ((data['sizes'] ?? const {})[widget.sizeKey]['stock'] ?? 0) as int;
          if (current < widget.quantity) {
            throw Exception('Not enough stock');
          }
          transaction.update(productRef, {sizePath: current - widget.quantity});
        }

        transaction.set(ordersRef, {
          'buyerId': user.uid,
          'buyerPhone': _phone,
          'deliveryLocation': _locationController.text.trim(),
          'storeId': widget.storeId,
          'storeName': storeName,
          'sellerId': widget.sellerId,
          'items': [
            {
              'productId': widget.productId,
              'sizeKey': widget.sizeKey,
              'sizeName': widget.sizeName,
              'quantity': widget.quantity,
              'unitPrice': widget.unitPrice,
            },
          ],
          'totalPrice': total,
          'status': 'on hold',
          'createdAt': FieldValue.serverTimestamp(),
        });
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
    final total = widget.unitPrice * widget.quantity;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product summary card
              Card(
                margin: const EdgeInsets.only(bottom: 20),
                child: ListTile(
                  title: Text('Quantity: ${widget.quantity}${widget.sizeName != null ? ' |  Size: ${widget.sizeName}' : ''}'),
                  subtitle: Text('₱${widget.unitPrice.toStringAsFixed(2)} each'),
                  trailing: Text(
                    '₱${total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // Prefilled phone number
              ListTile(
                leading: const Icon(Icons.phone),
                title: Text(_phone ?? 'Loading...'),
                subtitle: const Text('Your phone number'),
                trailing: TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => MePage()));
                  },
                  child: const Text('Edit in Settings'),
                ),
              ),
              const SizedBox(height: 20),

              // Delivery location field
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Delivery location',
                  border: OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const Spacer(),

              // Place Order button
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
