import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConversationListPage extends StatelessWidget {
  const ConversationListPage({super.key});

  Future<Map<String, String?>> _fetchOtherInfo({
    required String otherUserId,
    required bool isBuyer,
  }) async {
    final firestore = FirebaseFirestore.instance;

    if (isBuyer) {
      // current user is buyer, so other participant is a seller -> store info
      final storeSnap = await firestore
          .collection('stores')
          .where('ownerId', isEqualTo: otherUserId)
          .limit(1)
          .get();
      if (storeSnap.docs.isNotEmpty) {
        final data = storeSnap.docs.first.data();
        return {
          'name': data['name'] as String? ?? 'Seller',
          'photoUrl': data['logoUrl'] as String?, // store logo if exists
        };
      }
      return {'name': 'Seller', 'photoUrl': null};
    } else {
      // current user is seller, so other participant is a buyer -> user info
      final userSnap =
          await firestore.collection('users').doc(otherUserId).get();
      if (userSnap.exists) {
        final data = userSnap.data() as Map<String, dynamic>;
        return {
          'name': data['userName'] as String? ?? 'Buyer',
          'photoUrl': data['photoUrl'] as String?,
        };
      }
      return {'name': 'Buyer', 'photoUrl': null};
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view messages.')),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Messages')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('conversations')
            .where('participants', arrayContains: currentUser.uid)
            .orderBy('updatedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final convDocs = snapshot.data!.docs;

          if (convDocs.isEmpty) {
            return const Center(child: Text('No conversations yet.'));
          }

          return ListView.builder(
            itemCount: convDocs.length,
            itemBuilder: (context, index) {
              final convData = convDocs[index].data() as Map<String, dynamic>;
              final participants = List<String>.from(convData['participants']);
              final otherUserId =
                  participants.firstWhere((id) => id != currentUser.uid);
              final bool isBuyer = convData['buyerId'] == currentUser.uid;
              final lastMessage = convData['lastMessage'] as String? ?? 'No messages sent.';

              return FutureBuilder<Map<String, String?>>(
                future: _fetchOtherInfo(
                  otherUserId: otherUserId,
                  isBuyer: isBuyer,
                ),
                builder: (context, infoSnapshot) {
                  if (!infoSnapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Card(
                        child: ListTile(title: Text('Loading...')),
                      ),
                    );
                  }

                  final otherName = infoSnapshot.data!['name'] ??
                      (isBuyer ? 'Seller' : 'Buyer');
                  final photoUrl = infoSnapshot.data!['photoUrl'];

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 4.0, horizontal: 8.0),
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundImage: (photoUrl != null &&
                                  photoUrl.isNotEmpty)
                              ? NetworkImage(photoUrl)
                              : null,
                          child: (photoUrl == null || photoUrl.isEmpty)
                              ? Text(otherName.isNotEmpty
                                  ? otherName[0].toUpperCase()
                                  : '?')
                              : null,
                        ),
                        title: Text(
                          otherName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          // TODO: Navigate to ChatPage with conversation ID
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
