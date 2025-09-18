import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:kampus_kart/pages/login_page.dart';
import 'package:kampus_kart/pages/home_page.dart';
import 'package:kampus_kart/pages/me_page.dart';
import 'package:kampus_kart/pages/store_homepage.dart';

class MyNavRail extends StatefulWidget {
  final bool showLogin;
  final bool showSignUp;
  const MyNavRail({
    this.showLogin = false,
    this.showSignUp = false,
    super.key,
  });

  @override
  State<MyNavRail> createState() => _MyNavRailState();
}

class _MyNavRailState extends State<MyNavRail> {
  var selectedIndex = 0;
  bool? isSeller; // null = loading, true/false = result

  @override
  void initState() {
    super.initState();

    if (widget.showLogin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showTopMessage(context, 'Login Succesful!');
      });
    } else if (widget.showSignUp) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showTopMessage(context, 'Sign Up Successful! You can now Login.');
      });
    }

    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => isSeller = false);
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      // OPTION 1: check explicit role
      if (userDoc.exists && userDoc.data()?['role'] == 'seller') {
        setState(() => isSeller = true);
        return;
      }

      // OPTION 2: check if user owns a store document
      final storeSnap = await FirebaseFirestore.instance
          .collection('stores')
          .where('ownerId', isEqualTo: user.uid)
          .limit(1)
          .get();

      setState(() => isSeller = storeSnap.docs.isNotEmpty);
    } catch (e) {
      // if something goes wrong, fall back to normal user
      setState(() => isSeller = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // wait until Firestore finished loading
    if (isSeller == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ----- decide which destinations to show -----
    final destinations = isSeller!
        ? const [
            NavigationRailDestination(
              icon: Icon(Icons.store_outlined),
              selectedIcon: Icon(Icons.store),
              label: Text('Store'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: Text('Orders'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.chat_outlined),
              selectedIcon: Icon(Icons.chat),
              label: Text('Chat'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: Text('Me'),
            ),
          ]
        : const [
            NavigationRailDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: Text('Home'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.chat_outlined),
              selectedIcon: Icon(Icons.chat),
              label: Text('Chat'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications),
              label: Text('Notifications'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: Text('Me'),
            ),
          ];

    // map each index to a page
    Widget page;
    if (isSeller!) {
      switch (selectedIndex) {
        case 0:
          page = StorePage(); // Store page
        case 1:
          page = const Placeholder(); // Orders page
        case 2:
          page = const Placeholder(); // Chat page
        case 3:
          page = const MePage();
        default:
          throw UnimplementedError('No page for $selectedIndex');
      }
    } else {
      switch (selectedIndex) {
        case 0:
          page = HomePage();
        case 1:
          page = const Placeholder(); // Chat page
        case 2:
          page = const Placeholder(); // Notifications page
        case 3:
          page = MePage(); 
        default:
          throw UnimplementedError('No page for $selectedIndex');
      }
    }

    var mainArea = ColoredBox(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: page,
      ),
    );

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {

          // --------- MOBILE: bottom navigation ----------
          if (constraints.maxWidth < 450) {
            return Column(
              children: [
                Expanded(child: mainArea),
                SafeArea(
                  top: false,
                  child: BottomNavigationBar(
                    showUnselectedLabels: true,
                    selectedItemColor: Colors.black,
                    unselectedItemColor: Colors.grey,
                    items: destinations
                        .map((d) => BottomNavigationBarItem(
                              icon: d.icon,
                              label: (d.label as Text).data ?? '',
                            ))
                        .toList(),
                    currentIndex: selectedIndex,
                    onTap: (value) => setState(() => selectedIndex = value),
                  ),
                ),
              ],
            );
          }

          // --------- DESKTOP: side navigation rail ----------
          return Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  extended: constraints.maxWidth >= 600,
                  destinations: destinations,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) =>
                      setState(() => selectedIndex = value),
                ),
              ),
              Expanded(child: mainArea),
            ],
          );
        },
      ),
    );
  }
}
