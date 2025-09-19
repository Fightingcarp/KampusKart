import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kampus_kart/pages/product_detail_page.dart';

class ProductsSection extends StatelessWidget {
  final String searchQuery;
  const ProductsSection({super.key, required this.searchQuery});

  // 🔹 No _fetchAverageRating needed anymore
  Future<String?> _fetchStoreName(String storeId) async {
    final doc = await FirebaseFirestore.instance
        .collection('stores')
        .doc(storeId)
        .get();
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
          return name.contains(searchQuery.toLowerCase());
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
            final docId = doc.id;

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
                          ProductDetailPage(product: data, productId: docId),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: data['imageUrl'] != null && data['imageUrl'] != ""
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

                          // ---------- Price (handles sizes or single price)
                          Builder(
                            builder: (_) {
                              final sizes = (data['sizes'] != null &&
                                      data['sizes'] is Map<String, dynamic>)
                                  ? data['sizes'] as Map<String, dynamic>
                                  : {};
                              if (sizes.isNotEmpty) {
                                final sizePrices = sizes.entries
                                    .map((e) =>
                                        (e.value['price'] as num?)?.toDouble() ?? 0)
                                    .toList();
                                if (sizePrices.isNotEmpty) {
                                  final minPrice = sizePrices.reduce((a, b) => a < b ? a : b);
                                  final maxPrice = sizePrices.reduce((a, b) => a > b ? a : b);
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

                          // ---------- ✅ Reviews: Same "No reviews" pattern as StoreProductsPage
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('products')
                                .doc(docId)
                                .collection('reviews')
                                .snapshots(),
                            builder: (context, reviewSnapshot) {
                              if (reviewSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox(
                                  width: 30,
                                  height: 14,
                                  child: Center(
                                    child: SizedBox(
                                      width: 10,
                                      height: 10,
                                      child: CircularProgressIndicator(strokeWidth: 1),
                                    ),
                                  ),
                                );
                              }
                              if (!reviewSnapshot.hasData ||
                                  reviewSnapshot.data!.docs.isEmpty) {
                                return const Text(
                                  'No reviews',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                );
                              }

                              final reviews = reviewSnapshot.data!.docs;
                              double total = 0;
                              for (var r in reviews) {
                                final reviewData = r.data() as Map<String, dynamic>;
                                total += (reviewData['rating'] ?? 0).toDouble();
                              }
                              final avg = total / reviews.length;

                              return Row(
                                children: [
                                  const Icon(Icons.star,
                                      size: 14, color: Colors.amber),
                                  const SizedBox(width: 2),
                                  Text(
                                    avg.toStringAsFixed(1),
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black87),
                                  ),
                                ],
                              );
                            },
                          ),

                          // ---------- Store name
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
                                return const Text(
                                  'Store: Unknown',
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 68, 29, 29),
                                      fontSize: 12),
                                );
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
