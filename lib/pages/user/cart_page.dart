import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('You need to be logged in to view the cart.')),
      );
    }

    final cartRef = FirebaseFirestore.instance
      .collection('carts')
      .doc(uid)
      .collection('items');

    return Scaffold(
      appBar: AppBar(title: const Text('My Cart')),
      body: StreamBuilder<QuerySnapshot>(
        stream: cartRef.orderBy('addedAt', descending: false).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Your cart is empty.'));
          }

          final cartDocs = snapshot.data!.docs;
          double total = 0;
          for (final doc in cartDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final quantity = (data['quantity'] ?? 0) as int;
            final price = (data['unitPrice'] ?? 0).toDouble();
            total += quantity * price;
          }

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartDocs.length,
                    itemBuilder: (context, index) {
                      final doc = cartDocs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final name = data['name'] ?? '';
                      final sizeName = data['sizeName'] ?? '';
                      final quantity = (data['quantity'] ?? 0) as int;
                      final price = (data['unitPrice'] ?? 0).toDouble();
            
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(name),
                          subtitle: sizeName.isEmpty
                            ? Text('₱${price.toStringAsFixed(2)} x $quantity')
                            : Text('$sizeName • ₱${price.toStringAsFixed(2)} x $quantity'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () async {
                                  if (quantity > 1) {
                                    await doc.reference.update({'quantity': quantity - 1});
                                  } else {
                                    await doc.reference.delete();
                                  }
                                },
                              ),
                              Text(quantity.toString()),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () async {
                                  final productId = data['productId'];
                                  final sizeKey = data['sizeKey'];

                                  final productDoc = await FirebaseFirestore.instance
                                    .collection('products')
                                    .doc(productId)
                                    .get();
                                  final productData = productDoc.data();
                                  if (productData == null) return;

                                  int stock;

                                  if (sizeKey != null && sizeKey.isNotEmpty) {
                                    final sizesMap = productData['sizes'] as Map<String, dynamic>? ?? {};
                                    final sizeData = sizesMap[sizeKey] as Map<String, dynamic>?;
                                    if (sizeData == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Size data not found in product')),
                                      );
                                      return;
                                    }
                                    stock = (sizeData['stock'] ?? 0) as int;
                                  } else {
                                    stock = (productData['stock'] ?? 0) as int;
                                  }

                                  if (quantity < stock) {
                                    await doc.reference.update({'quantity': quantity + 1});
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Cannot add more than available stock for this item'),
                                      ),
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  await doc.reference.delete();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    border: Border(top: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total: ₱${total.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium),
                          ElevatedButton(
                            onPressed: () {
                              // will navigate to the checkout page
                            },
                            child: const Text('Proceed to Checkout'),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}