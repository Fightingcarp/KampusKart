import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StoreHistoryPage extends StatelessWidget {
  const StoreHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your order history.')),
      );
    }

    final historyQuery = FirebaseFirestore.instance
        .collection('history')
        .where('sellerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      body: StreamBuilder<QuerySnapshot>(
        stream: historyQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No order history yet.'));
          }

          final historyOrders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: historyOrders.length,
            itemBuilder: (context, i) {
              final orderDoc = historyOrders[i];
              final data = orderDoc.data() as Map<String, dynamic>;

              final status = data['status'] as String? ?? 'unknown';
              final storeName = data['storeName'] ?? 'Unknown store';
              final total = (data['totalPrice'] as num?)?.toDouble() ?? 0.0;
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
              final items = (data['items'] as List).cast<Map<String, dynamic>>();
              final buyerId = data['buyerId'] as String? ?? '';
              final buyerPhone = data['buyerPhone'] as String? ?? '';

              final statusColor = {
                'on hold': Colors.orange,
                'processing': Colors.blue,
                'delivering': Colors.purple,
                'completed': Colors.green,
                'cancelled': Colors.red,
              }[status] ?? Colors.grey;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ExpansionTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(storeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(status.toUpperCase(),
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  subtitle: Text(
                    createdAt != null
                        ? 'Placed: ${createdAt.toLocal()}'
                        : 'Placed: -',
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(buyerId)
                                .get(),
                            builder: (context, userSnap) {
                              if (userSnap.connectionState == ConnectionState.waiting) {
                                return const Text('Loading buyer info...');
                              }
                              if (!userSnap.hasData || !userSnap.data!.exists) {
                                return const Text('Buyer information not found.');
                              }
                              final buyerData =
                                  userSnap.data!.data() as Map<String, dynamic>;
                              final buyerName = buyerData['userName'] ?? 'No name';
                              final buyerEmail = buyerData['email'] ?? 'No email';
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Buyer Details:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text('Name: $buyerName'),
                                  Text('Email: $buyerEmail'),
                                  Text('Phone: $buyerPhone'),
                                  const SizedBox(height: 12),
                                ],
                              );
                            },
                          ),

                          const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ...items.map((item) {
                            final productId = item['productId'] as String;
                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('products')
                                  .doc(productId)
                                  .get(),
                              builder: (context, prodSnap) {
                                String productName = 'Unknown product';
                                if (prodSnap.hasData && prodSnap.data!.exists) {
                                  final prodData =
                                      prodSnap.data!.data() as Map<String, dynamic>;
                                  productName = prodData['name'] ?? productName;
                                }
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    '${item['quantity']}x $productName'
                                    '${(item['sizeName'] != null && item['sizeName']!.toString().isNotEmpty)
                                        ? ' (${item['sizeName']})'
                                        : ''} - ₱${item['unitPrice']}',
                                  ),
                                );
                              },
                            );
                          }),
                          const SizedBox(height: 12),
                          ListTile(
                            title: Text('Total: ₱${total.toStringAsFixed(2)}'),
                            subtitle: const Text('Order details'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
