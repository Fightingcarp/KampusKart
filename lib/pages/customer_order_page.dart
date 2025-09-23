import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomerOrdersPage extends StatelessWidget {
  const CustomerOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your orders.')),
      );
    }

    final ordersQuery = FirebaseFirestore.instance
        .collection('orders')
        .where('buyerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: StreamBuilder<QuerySnapshot>(
        stream: ordersQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No orders yet.'));
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, i) {
              final data = orders[i].data() as Map<String, dynamic>;
              final orderId = orders[i].id;
              final status = data['status'] as String? ?? 'unknown';
              final storeName = data['storeName'] ?? 'Unknown store';
              final total = (data['totalPrice'] as num?)?.toDouble() ?? 0.0;
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

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
                    ListTile(
                      title: Text('Total: ₱${total.toStringAsFixed(2)}'),
                      subtitle: const Text('Tap to see order details here if needed'),
                    ),
                    if (status == 'on_hold')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Center(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Cancel order?'),
                                  content: const Text(
                                    'Are you sure you want to cancel this order?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('No'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Yes, cancel'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await FirebaseFirestore.instance
                                    .collection('orders')
                                    .doc(orderId)
                                    .update({'status': 'cancelled'});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Order cancelled.')),
                                );
                              }
                            },
                            child: const Text('Cancel Order'),
                          ),
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
