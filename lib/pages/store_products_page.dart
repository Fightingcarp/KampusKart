import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kampus_kart/pages/product_detail_page.dart';

class StoreProductsPage extends StatelessWidget {
  final String storeId;
  final String storeName;
  final String? storeBanner;
  final String? storeDescription;
  final String? contactEmail;
  final String? contactPhone;

  const StoreProductsPage({
    required this.storeId,
    required this.storeName,
    this.storeBanner,
    this.storeDescription,
    this.contactEmail,
    this.contactPhone,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text(storeName)),
      body: Column(
        children: [
          if (storeBanner != null && storeBanner != "") 
            Image.network(storeBanner!, height: 150, width: double.infinity, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (storeDescription != null && storeDescription != "")
                  Text(storeDescription!, style: TextStyle(fontSize: 14, color: Colors.black87)),
                if (contactEmail != null || contactPhone != null)
                  Row(
                    children: [
                      if (contactEmail != null && contactEmail != "")
                        Expanded(
                          child: Text("Email: $contactEmail", style: TextStyle(fontSize: 12)),
                        ),
                      if (contactPhone != null && contactPhone != "")
                        Expanded(
                          child: Text("Phone: $contactPhone", style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                const Divider(height: 32),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                .collection('products')
                .where('storeId', isEqualTo: storeId)
                .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No products found for this store.'));
                }

                final products = snapshot.data!.docs;

                return GridView.builder(
                  padding: EdgeInsets.all(8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, i) {
                    final docId = products[i].id;
                    final product = products[i].data() as Map<String, dynamic>;
                    
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
                              builder: (context) => ProductDetailPage(product: product, productId: docId),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: product['imageUrl'] != null && product['imageUrl'] != ""
                                ? ClipRRect(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                  child: Image.network(
                                    product['imageUrl'],
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Container(
                                  color: Colors.grey[300],
                                  child: Icon(Icons.image, size: 50, color: Colors.grey[600]),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0), 
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product['name'] ?? '',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [

                                      Builder(
                                        builder: (_) {
                                          final sizes = (product['sizes'] != null && product['sizes'] is Map<String, dynamic>)
                                            ? product['sizes'] as Map<String, dynamic>
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
                                            product['price'] != null
                                              ? '₱${(product['price'] as num).toStringAsFixed(2)}'
                                              : '₱N/A',
                                            style: TextStyle(
                                              color: Colors.green[700],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        },
                                      ),

                                      StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('products')
                                            .doc(docId)
                                            .collection('reviews')
                                            .snapshots(),
                                        builder: (context, reviewSnapshot) {
                                          if (reviewSnapshot.connectionState == ConnectionState.waiting) {
                                            return const SizedBox(
                                                width: 30,
                                                height: 14,
                                                child: Center(
                                                    child: SizedBox(
                                                        width: 10,
                                                        height: 10,
                                                        child: CircularProgressIndicator(strokeWidth: 1))));
                                          }
                                          if (!reviewSnapshot.hasData || reviewSnapshot.data!.docs.isEmpty) {
                                            return const Text(
                                              'No reviews',
                                              style: TextStyle(fontSize: 12, color: Colors.grey),
                                            );
                                          }

                                          final reviews = reviewSnapshot.data!.docs;
                                          double total = 0;
                                          for (var r in reviews) {
                                            final data = r.data() as Map<String, dynamic>;
                                            total += (data['rating'] ?? 0).toDouble();
                                          }
                                          final avg = total / reviews.length;

                                          return Row(
                                            children: [
                                              const Icon(Icons.star, size: 14, color: Colors.amber),
                                              const SizedBox(width: 2),
                                              Text(
                                                avg.toStringAsFixed(1),
                                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  if (product['createdAt'] != null)
                                    Text(
                                      'Added: ${(product['createdAt'] as Timestamp).toDate().toString().split(' ')[0]}',
                                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}