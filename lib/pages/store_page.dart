import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'store_products_page.dart';

class StorePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      appBar: AppBar(
        title: Text("Stores"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('stores').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No stores found.'));
          }
          final stores = snapshot.data!.docs;
          return ListView.builder(
            padding: EdgeInsets.all(8.0),
            itemCount: stores.length,
            itemBuilder: (context, i) {
              final store = stores[i].data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  leading: store['logoUrl'] != null && store['logoUrl'] != ""
                    ? CircleAvatar(
                      backgroundImage: NetworkImage(store['logoUrl']),
                    )
                    : CircleAvatar(child: Icon(Icons.store)),
                  title: Text(store['name'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (store['description'] != null && store['description'] != "")
                        Text(store['description'], maxLines: 2, overflow: TextOverflow.ellipsis),
                      if (store['contactEmail'] != null && store['contactEmail'] != "")
                        Text("Email: ${store['contactEmail']}"),
                      if (store['contactPhone'] != null && store['contactPhone'] != "")
                        Text("Phone: ${store['contactPhone']}"),
                      if (store['rating'] != null)
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            SizedBox(width: 2),
                            Text(store['rating'].toString()),
                          ],
                        ),
                      if (store['isActive'] == false)
                        Text('Inactive', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  trailing: store['isActive'] == true
                    ? null
                    : Icon(Icons.block, color: Colors.red),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StoreProductsPage(
                          storeId: stores[i].id,
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
      ),
    );
  }
}