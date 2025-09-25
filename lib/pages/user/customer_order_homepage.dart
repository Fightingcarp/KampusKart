import 'package:flutter/material.dart';

import 'package:kampus_kart/pages/user/customer_order_page.dart';
import 'package:kampus_kart/pages/user/customer_history_page.dart';

class CustomerOrderHomePage extends StatefulWidget {
  @override
  State<CustomerOrderHomePage> createState() => _CustomerOrderHomePage();
}

class _CustomerOrderHomePage extends State<CustomerOrderHomePage> {

  int _selectedTab = 0; // 0 = Products, 1 = Stores

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
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
          ? CustomerOrdersPage()
          : CustomerHistoryPage()
    );
  }
}
