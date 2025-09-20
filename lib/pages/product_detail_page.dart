import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;
  final String productId;

  const ProductDetailPage({
    required this.product,
    required this.productId,
    super.key,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  double? _userRating;
  String? _userReviewText;
  String? _selectedSizekey;
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
    final user = FirebaseAuth.instance.currentUser;

    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to review')),
      );
      setState(() => _submitting = false);
      return;
    }

    await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId)
        .collection('reviews')
        .add({
      'rating': _userRating,
      'reviewText': _userReviewText,
      'userId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    setState(() {
      _userRating = null;
      _userReviewText = null;
      _submitting = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review submitted!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      appBar: AppBar(
        title: Text('Product Details'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------------- Product image ----------------
            product['imageUrl'] != null
                ? Image.network(product['imageUrl'], height: 220, fit: BoxFit.cover)
                : Container(
                    height: 220,
                    color: Colors.grey[300],
                    child: Icon(Icons.image, size: 80, color: Colors.grey[600]),
                  ),

            // StreamBuilder wraps the stock + buttons
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: StreamBuilder<DocumentSnapshot>(
                  // listen to the product document in real time
                  stream: FirebaseFirestore.instance
                      .collection('products')
                      .doc(widget.productId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    
                    final Map<String, dynamic> sizes =
                      (data['sizes'] != null && data['sizes'] is Map<String, dynamic>)
                        ? data['sizes'] as Map<String, dynamic>
                        : {};

                    final String? selected = _selectedSizekey;

                    final int stock = selected != null && sizes.containsKey(selected)
                      ? (sizes[selected]['stock'] ?? 0) as int
                      : (data['stock'] ?? 0) as int;

                    final double? price = selected != null && sizes.containsKey(selected)
                      ? (sizes[selected]['price'] as num?)?.toDouble()
                      : (data['price'] as num?)?.toDouble();

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name'] ?? '',
                            style: const TextStyle(
                                fontSize: 26, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            price != null
                              ? '₱${price.toStringAsFixed(2)}'
                              : '₱N/A',
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          if (sizes.isNotEmpty) ...[
                            const Text('Choose a Size:',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              children: sizes.keys.map((k) {
                                return ChoiceChip(
                                  label: Text(sizes[k]['name'] ?? 'Option $k'),
                                  selected: _selectedSizekey == k,
                                  onSelected: (sel) {
                                    setState(() {
                                      _selectedSizekey = sel ? k : null;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                          ],
                          // live stock count
                          Text(
                            'Stock left: $stock',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.redAccent),
                          ),
                          const SizedBox(height: 16),
                          Text(product['description'] ?? '',
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 20),
                          FutureBuilder<String?>(
                            future: _fetchStoreName(product['storeId']),
                            builder: (context, storeSnap) {
                              if (storeSnap.connectionState == ConnectionState.waiting) {
                                return Text('Store: ...',
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 14));
                              }
                              if (storeSnap.hasError || !storeSnap.hasData) {
                                return Text('Store: Unknown',
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 14));
                              }
                              return Text('Store: ${storeSnap.data}',
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 14));
                            },
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              const Text("Customer Reviews",
                                  style: TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                  .collection('products')
                                  .doc(widget.productId)
                                  .collection('reviews')
                                  .snapshots(),
                                builder: (context, reviewSnap) {
                                  if (reviewSnap.connectionState == ConnectionState.waiting) {
                                    return const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 1),
                                    );
                                  }
                                  if (!reviewSnap.hasData || reviewSnap.data!.docs.isEmpty) {
                                    return const Text(
                                      'No reviews',
                                      style: TextStyle(fontSize: 14, color: Colors.grey),
                                    );
                                  }

                                  double total = 0;
                                  for (var r in reviewSnap.data!.docs) {
                                    final revData = r.data() as Map<String, dynamic>;
                                    total += (revData['rating'] ?? 0).toDouble();
                                  }
                                  final avg = total / reviewSnap.data!.docs.length;

                                  return Row(
                                    children: [
                                      const Icon(Icons.star, size: 16, color: Colors.amber),
                                      const SizedBox(width: 2),
                                      Text(
                                        avg.toStringAsFixed(1),
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: _fetchReviews(),
                            builder: (context, revSnap) {
                              if (revSnap.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              if (revSnap.hasError) {
                                return const Text("Error loading reviews");
                              }
                              final reviews = revSnap.data ?? [];
                              if (reviews.isEmpty) {
                                return const Text(
                                    "No reviews yet. Be the first to review!");
                              }
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: reviews.length,
                                itemBuilder: (context, i) {
                                  final rev = reviews[i];
                                  final String? userId = rev['userId'] as String?;
                                  final double? rating = (rev['rating'] as num?)?.toDouble();
                                  final String reviewText = rev['reviewText'] ?? '';
                                  
                                  if (userId == null) {
                                    return ListTile(
                                      leading: rating != null
                                          ? const Icon(Icons.star, color: Colors.amber)
                                          : null,
                                      title: Text(reviewText),
                                      subtitle: rating != null
                                          ? Text("Rating: $rating")
                                          : null,
                                    );
                                  }

                                  return FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                                    builder: (context, userSnap) {
                                      String username = 'Anonymous';
                                      if (userSnap.hasData && userSnap.data!.exists) {
                                        final data = userSnap.data!.data() as Map<String, dynamic>;
                                        username = data['userName'] ?? 'Anonymous';
                                      }

                                      return ListTile(
                                        leading: rating != null ? const Icon(Icons.star, color: Colors.amber) : null,
                                        title: Text(reviewText),
                                        subtitle: Text(
                                          rating != null ? 'Rating: $rating • $username' : 'by $username',
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                          const Divider(height: 32),
                          const Text("Leave a Review",
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text("Rating:"),
                              const SizedBox(width: 12),
                              for (int i = 1; i <= 5; i++)
                                IconButton(
                                  icon: Icon(
                                    Icons.star,
                                    color: (_userRating ?? 0) >= i
                                        ? Colors.amber
                                        : Colors.grey,
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
                            decoration: const InputDecoration(
                              hintText: "Write your review...",
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) => _userReviewText = val,
                            controller:
                                TextEditingController(text: _userReviewText),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _submitting
                                ? null
                                : () async {
                                    if (_userRating != null &&
                                        _userReviewText != null &&
                                        _userReviewText!.trim().isNotEmpty) {
                                      await _submitReview();
                                      setState(() {});
                                    }
                                  },
                            child: _submitting
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text("Submit Review"),
                          ),
                          const SizedBox(height: 20),

                          // Buy / Add to Cart buttons react to live stock
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed:
                                      stock <= 0 ? null : () {/* buy logic */},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[700],
                                    disabledBackgroundColor: Colors.green[200],
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text(
                                      stock <= 0 ? 'Out of Stock' : 'Buy'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: stock <= 0
                                      ? null
                                      : () {/* add to cart logic */},
                                  child: const Text('Add to Cart'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
