import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StoreOrdersPage extends StatelessWidget {
  const StoreOrdersPage({super.key});

  Color _statusColor(String s) {
    switch(s) {
      case 'on hold': return Colors.orange;
      case 'processing': return Colors.blue;
      case 'delivering': return Colors.purple;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sellerId = FirebaseAuth.instance.currentUser!.uid;
    final orders = FirebaseFirestore.instance
      .collection('orders')
      .where('sellerId', isEqualTo: sellerId)
      .orderBy('createdAt', descending: true);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      body: StreamBuilder<QuerySnapshot>(
        stream: orders.snapshots(),
        builder: (c, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } 
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text('No orders yet'));
          }

          return ListView(
            children: snap.data!.docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final status = d['status'] ?? 'on hold';
              final total = d['totalPrice'] ?? 0.0;
              final buyerPhone = d['buyerPhone'] ?? '';
              final delivery = d['delivery'] ?? '';
              final items = (d['items'] as List).cast<Map<String, dynamic>>();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ExpansionTile(
                  title: Text('₱${total.toStringAsFixed(2)} - $buyerPhone'),
                  subtitle: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(status),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        (d['createdAt'] as Timestamp)
                          .toDate()
                          .toLocal()
                          .toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Delivery: $delivery'),
                          const SizedBox(height: 8),
                          ...items.map((item) {
                            final productId = item['productId'] as String;

                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('products')
                                  .doc(productId)
                                  .get(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  // while loading product name, show placeholder
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 4),
                                    child: Text('Loading product...'),
                                  );
                                }

                                String productName = 'Unknown product';
                                if (snapshot.hasData && snapshot.data!.exists) {
                                  final prodData = snapshot.data!.data() as Map<String, dynamic>;
                                  productName = prodData['name'] ?? productName;
                                }

                                return Text(
                                  '${item['quantity']}x '
                                  '$productName'
                                  '${item['sizeName'] != null && item['sizeName']!.toString().isNotEmpty
                                      ? ' (${item['sizeName']})'
                                      : ''} - '
                                  '₱${item['unitPrice']}',
                                );
                              },
                            );
                          }),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text('Change status: '),
                              const SizedBox(width: 12),
                              DropdownButton<String>(
                                value: status,
                                items: const [
                                  'on hold',
                                  'processing',
                                  'delivering',
                                  'completed',
                                ].map((s) =>
                                  DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                                onChanged: (val) async {
                                  if (val == null) return;
                                  
                                  final orderRef = FirebaseFirestore.instance.collection('orders').doc(doc.id);
                                  final batch = FirebaseFirestore.instance.batch();

                                  if (val == 'completed') {
                                    final orderSnap = await orderRef.get();
                                    if (!orderSnap.exists) return;

                                    final orderData = orderSnap.data()!;
                                    orderData['status'] = 'completed';
                                    orderData['completedAt'] = FieldValue.serverTimestamp();

                                    final historyRef = FirebaseFirestore.instance.collection('history').doc(doc.id);
                                    batch.set(historyRef, orderData);

                                    batch.delete(orderRef);

                                    await batch.commit();
                                  } else {
                                    await orderRef.update({'status': val});
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}