import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:kampus_kart/pages/product_page.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String searchQuery = '';
  final TextEditingController _controller = TextEditingController();

  void updateSearch(String value) {
    setState(() {
      searchQuery = value.toLowerCase();
    });
  }

  Future<double> _fetchAverageRating(String productId) async {
    final reviewsSnap = await FirebaseFirestore.instance
      .collection('products')
      .doc(productId)
      .collection('reviews')
      .get();

    if (reviewsSnap.docs.isEmpty) return 0.0;

    double total = 0;
    int count = 0;
    for (var doc in reviewsSnap.docs) {
      final rating = doc['rating'];
      if (rating is num) {
        total += rating.toDouble();
        count++;
      }
    }
    return count == 0 ? 0.0 : total / count;
  }

  // Helper to asynchronously fetch the store name for each product
  Future<String?> _fetchStoreName(String storeId) async {
    final doc = await FirebaseFirestore.instance.collection('stores').doc(storeId).get();
    return doc.exists ? doc['name'] as String? : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      appBar: AppBar(
        title: SizedBox(
          height: 40,
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Search Products',
              prefixIcon: Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey[300],
              contentPadding: EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: updateSearch,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              // TODO: Implement cart page
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Cart page coming soon!")),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Products Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No products found.'));
                }
                // Search filtering by search query
                final docs = snapshot.data!.docs;
                final filtered = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name']?.toLowerCase() ?? '';
                  return name.contains(searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(child: Text('No products match your search.'));
                }

                return GridView.builder(
                  padding: EdgeInsets.all(8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // Number of columns in the grid
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
                              builder: (context) => ProductDetailPage(
                                product: data,
                                productId: doc.id,
                              ),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Product Image
                            Expanded(
                              child: data['imageUrl'] != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                      child: Image.network(
                                        data['imageUrl'],
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Container(
                                      color: Colors.grey[300],
                                      child: Icon(Icons.image, size: 50, color: Colors.grey[600]),
                                    ),
                            ),
                            // Product Info
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['name'] ?? '',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '₱${data['price'] != null ? data['price'].toStringAsFixed(2) : 'N/A'}',
                                    style: TextStyle(
                                      color: Colors.green[700], fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),

                                  // Show average rating for each product
                                  FutureBuilder<double>(
                                    future: _fetchAverageRating(doc.id),
                                    builder: (context, snap) {
                                      if (snap.connectionState == ConnectionState.waiting) {
                                        return Text('Rating: ...',
                                          style: TextStyle(color: Colors.grey[600], fontSize: 12));
                                      }
                                      final avg = snap.data ?? 0.0;
                                      return Row(
                                        children: [
                                          Icon(Icons.star,
                                            color: Colors.amber[700], size: 16),
                                          const SizedBox(width: 2),
                                          Text(
                                            avg.toStringAsFixed(1),
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      );
                                    }
                                  ),
                                  // Show store name asynchronously for each product
                                  FutureBuilder<String?>(
                                    future: _fetchStoreName(data['storeId']),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return Text('Loading store...', style: TextStyle(color: Colors.grey[600], fontSize: 12));
                                      }
                                      if (!snapshot.hasData || snapshot.data == null) {
                                        return Text('Store: Unknown', style: TextStyle(color: Colors.grey[600], fontSize: 12));
                                      }
                                      return Text(
                                        snapshot.data!,
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}