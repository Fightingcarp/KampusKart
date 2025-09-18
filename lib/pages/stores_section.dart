import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'store_products_page.dart';

class StoresSection extends StatelessWidget {
  final String searchQuery;
  const StoresSection({super.key, this.searchQuery = ''});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('stores').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No stores found.'));
        }

        // filter by search text
        final filtered = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          return name.contains(searchQuery.toLowerCase());
        }).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('No stores match your search.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: filtered.length,
          itemBuilder: (context, i) {
            final storeDoc = filtered[i];
            final store = storeDoc.data() as Map<String, dynamic>;

            return Card(
              child: ListTile(
                leading: (store['logoUrl'] ?? '').isNotEmpty
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(store['logoUrl']),
                      )
                    : const CircleAvatar(child: Icon(Icons.store)),

                title: Text(store['name'] ?? ''),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((store['description'] ?? '').isNotEmpty)
                      Text(store['description'],
                          maxLines: 2, overflow: TextOverflow.ellipsis),

                    if ((store['contactEmail'] ?? '').isNotEmpty)
                      Text("Email: ${store['contactEmail']}"),
                    if ((store['contactPhone'] ?? '').isNotEmpty)
                      Text("Phone: ${store['contactPhone']}"),

                    // live average rating
                    _StoreAverageRating(storeId: storeDoc.id),

                    if (store['isActive'] == false)
                      const Text('Inactive', style: TextStyle(color: Colors.red)),
                  ],
                ),
                trailing: store['isActive'] == true
                    ? null
                    : const Icon(Icons.block, color: Colors.red),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StoreProductsPage(
                        storeId: storeDoc.id,
                        storeName: store['name'] ?? '',
                        storeBanner: store['bannerUrl'],
                        storeDescription: store['description'],
                        contactEmail: store['contactEmail'],
                        contactPhone: store['contactPhone'],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _StoreAverageRating extends StatelessWidget {
  final String storeId;
  const _StoreAverageRating({required this.storeId});

  @override
  Widget build(BuildContext context) {
    // listen to all products of this store
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('storeId', isEqualTo: storeId)
          .snapshots(),
      builder: (context, productSnap) {
        if (!productSnap.hasData || productSnap.data!.docs.isEmpty) {
          return const Text('No product ratings yet',
              style: TextStyle(fontSize: 12, color: Colors.grey));
        }

        final productDocs = productSnap.data!.docs;

        // 2️⃣ For every product, open its reviews subcollection and compute avg.
        //    We'll do it with Future.wait + a FutureBuilder
        return FutureBuilder<double>(
          future: _calcAverageRating(productDocs),
          builder: (context, avgSnap) {
            if (!avgSnap.hasData) {
              return const SizedBox(
                  width: 30,
                  height: 14,
                  child: Center(
                      child: SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(strokeWidth: 1))));
            }

            final avg = avgSnap.data!;
            if (avg == 0) {
              return const Text('No product ratings yet',
                  style: TextStyle(fontSize: 12, color: Colors.grey));
            }

            return Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 2),
                Text(avg.toStringAsFixed(1)),
              ],
            );
          },
        );
      },
    );
  }

  /// Helper to fetch all review docs for each product and compute the average
  Future<double> _calcAverageRating(List<QueryDocumentSnapshot> products) async {
    double total = 0;
    int count = 0;

    for (var product in products) {
      final reviews = await FirebaseFirestore.instance
          .collection('products')
          .doc(product.id)
          .collection('reviews')
          .get();

      for (var r in reviews.docs) {
        final data = r.data();
        final rating = (data['rating'] ?? 0).toDouble();
        total += rating;
        count++;
      }
    }
    return count == 0 ? 0 : total / count;
  }
}
