import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;
  final String productId; 

  const ProductDetailPage({required this.product, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  double? _userRating;
  String? _userReviewText;
  bool _submitting = false;

  Future<String?> _fetchStoreName(String storeId) async {
    final doc = await FirebaseFirestore.instance.collection('stores').doc(storeId).get();
    return doc.exists ? doc['name'] as String? : null;
  }

  Future<List<Map<String, dynamic>>> _fetchReviews() async {
    final snap = await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((doc) => doc.data()).toList();
  }

  Future<void> _submitReview() async {
    if (_userRating == null || (_userReviewText?.trim().isEmpty ?? true)) return;
    setState(() => _submitting = true);
    await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId)
        .collection('reviews')
        .add({
      'rating': _userRating,
      'reviewText': _userReviewText,
      'createdAt': FieldValue.serverTimestamp(),
    });
    setState(() {
      _userRating = null;
      _userReviewText = null;
      _submitting = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Review submitted!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      appBar: AppBar(
        title: Text(product['name'] ?? 'Product Details'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product Image
            product['imageUrl'] != null
                ? Image.network(product['imageUrl'], height: 220, fit: BoxFit.cover)
                : Container(
                    height: 220,
                    color: Colors.grey[300],
                    child: Icon(Icons.image, size: 80, color: Colors.grey[600]),
                  ),
            // Product Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'] ?? '',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '₱${product['price'] != null ? product['price'].toStringAsFixed(2) : 'N/A'}',
                        style: TextStyle(
                            fontSize: 22,
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      Text(product['description'] ?? '',
                          style: TextStyle(fontSize: 16)),
                      SizedBox(height: 20),
                      FutureBuilder<String?>(
                        future: _fetchStoreName(product['storeId']),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Text('Store: ...', style: TextStyle(color: Colors.grey[600], fontSize: 14));
                          }
                          if (snapshot.hasError || !snapshot.hasData) {
                            return Text('Store: Unknown', style: TextStyle(color: Colors.grey[600], fontSize: 14));
                          }
                          return Text('Store: ${snapshot.data}',
                              style: TextStyle(color: Colors.grey[600], fontSize: 14));
                        },
                      ),
                      SizedBox(height: 32),
                      Text("Customer Reviews", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _fetchReviews(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) return Text("Error loading reviews");
                          final reviews = snapshot.data ?? [];
                          if (reviews.isEmpty) {
                            return Text("No reviews yet. Be the first to review!");
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: reviews.length,
                            itemBuilder: (context, i) {
                              final rev = reviews[i];
                              return ListTile(
                                leading: rev['rating'] != null
                                    ? Icon(Icons.star, color: Colors.amber)
                                    : null,
                                title: Text(rev['reviewText'] ?? ''),
                                subtitle: rev['rating'] != null
                                    ? Text("Rating: ${rev['rating'].toString()}")
                                    : null,
                              );
                            },
                          );
                        },
                      ),
                      Divider(height: 32),
                      Text("Leave a Review", style: TextStyle(fontWeight: FontWeight.w600)),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Text("Rating:"),
                          SizedBox(width: 12),
                          for (int i = 1; i <= 5; i++)
                            IconButton(
                              icon: Icon(
                                Icons.star,
                                color: (_userRating ?? 0) >= i ? Colors.amber : Colors.grey,
                              ),
                              onPressed: () {
                                setState(() => _userRating = i.toDouble());
                              },
                            ),
                        ],
                      ),
                      TextField(
                        minLines: 1,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: "Write your review...",
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) => _userReviewText = val,
                        controller: TextEditingController(text: _userReviewText),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _submitting
                            ? null
                            : () async {
                                if (_userRating != null &&
                                    _userReviewText != null &&
                                    _userReviewText!.trim().isNotEmpty) {
                                  await _submitReview();
                                  setState(() {}); // refresh reviews
                                }
                              },
                        child: _submitting
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text("Submit Review"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: null, // Inert for now
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        disabledBackgroundColor: Colors.green[200],
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Buy'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: null, // Inert for now
                      child: Text('Add to Cart'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}