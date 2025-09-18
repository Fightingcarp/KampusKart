import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kampus_kart/pages/product_detail_page.dart';

class ProductsSection extends StatelessWidget {
  final String searchQuery;
  const ProductsSection({super.key, required this.searchQuery});

  Future<double> _fetchAverageRating(String productId) async {
    final reviewsSnap = await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .get();

    if (reviewsSnap.docs.isEmpty) return 0.0;

    double total = 0;
    for (var doc in reviewsSnap.docs) {
      final rating = doc['rating'];
      if (rating is num) total += rating.toDouble();
    }
    return total / reviewsSnap.docs.length;
  }

  Future<String?> _fetchStoreName(String storeId) async {
    final doc =
        await FirebaseFirestore.instance.collection('stores').doc(storeId).get();
    return doc.exists ? doc['name'] as String? : null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No products found.'));
        }

        final filtered = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toLowerCase();
          return name.contains(searchQuery);
        }).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('No products match your search.'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.7,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, i) {
            final doc = filtered[i];
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProductDetailPage(product: data, productId: doc.id),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: data['imageUrl'] != null
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                              child: Image.network(
                                data['imageUrl'],
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: Icon(Icons.image,
                                  size: 50, color: Colors.grey[600]),
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Builder(
                            builder: (_) {
                              final sizes = (data['sizes'] != null && data['sizes'] is Map<String, dynamic>)
                                ? data['sizes'] as Map<String, dynamic>
                                : {};
                              
                              if (sizes.isNotEmpty) {
                                // Collect all numeric prices from size entries
                                final List<double> sizePrices = sizes.entries
                                  .map((e) => (e.value['price'] as num?)?.toDouble() ?? 0)
                                  .toList();
                                if (sizePrices.isNotEmpty) {
                                  final double minPrice = sizePrices.reduce((a, b) => a < b ? a : b);
                                  final double maxPrice = sizePrices.reduce((a, b) => a > b ? a : b);

                                  // Display as a range only if min != max
                                  if (minPrice != maxPrice) {
                                    return Text(
                                      '₱${minPrice.toStringAsFixed(2)} - ₱${maxPrice.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  } else {
                                    return Text(
                                      '₱${minPrice.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  }
                                }
                              }

                              // fallback to regular price field if no sizes or empty
                              return Text(
                                data['price'] != null
                                  ? '₱${(data['price'] as num).toStringAsFixed(2)}'
                                  : '₱N/A',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          FutureBuilder<double>(
                            future: _fetchAverageRating(doc.id),
                            builder: (context, snap) {
                              if (snap.connectionState ==
                                  ConnectionState.waiting) {
                                return Text('Rating: ...',
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 12));
                              }
                              final avg = snap.data ?? 0.0;
                              return Row(
                                children: [
                                  Icon(Icons.star,
                                      color: Colors.amber, size: 16),
                                  const SizedBox(width: 2),
                                  Text(avg.toStringAsFixed(1),
                                      style: const TextStyle(fontSize: 12)),
                                ],
                              );
                            },
                          ),
                          FutureBuilder<String?>(
                            future: _fetchStoreName(data['storeId']),
                            builder: (context, snap) {
                              if (snap.connectionState ==
                                  ConnectionState.waiting) {
                                return Text('Loading store...',
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 12));
                              }
                              if (!snap.hasData || snap.data == null) {
                                return Text('Store: Unknown',
                                    style: TextStyle(
                                        color: const Color.fromARGB(255, 68, 29, 29), fontSize: 12));
                              }
                              return Text(
                                snap.data!,
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
