import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kampus_kart/pages/product_page.dart';

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
                                  Text(
                                    '₱${product['price'] != null ? product['price'].toString() : 'N/A'}',
                                    style: TextStyle(
                                      color: Colors.green[700], fontWeight: FontWeight.bold,
                                    ),
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