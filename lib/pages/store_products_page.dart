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
        ]
      ),
    );
  }
}