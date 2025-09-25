import 'package:flutter/material.dart';
import 'package:kampus_kart/pages/seller/store_history_page.dart';

import 'package:kampus_kart/pages/seller/store_order_page.dart';

class StoreOrderHomePage extends StatefulWidget {
  @override
  State<StoreOrderHomePage> createState() => _StoreOrderHomePage();
}

class _StoreOrderHomePage extends State<StoreOrderHomePage> {

  int _selectedTab = 0; // 0 = Products, 1 = Stores

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Orders and History"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kBottomNavigationBarHeight),
          child: NavigationBar(
            backgroundColor: Colors.white24,
            selectedIndex: _selectedTab,
            onDestinationSelected: (index) =>
                setState(() => _selectedTab = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Orders',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: 'History',
              ),
            ],
          ),
        ),
      ),
      body: _selectedTab == 0
          ? StoreOrdersPage()
          : StoreHistoryPage()
    );
  }
}
