import 'package:flutter/material.dart';
import 'package:kampus_kart/pages/seller/product_settings_page.dart';
import 'package:kampus_kart/pages/seller/store_settings_page.dart';

class StorePage extends StatefulWidget {
  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  int _selectedTab = 0;

  @override 
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      appBar: AppBar(
        title: Text('Store Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        // nav bar for Product & Store Settings
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kBottomNavigationBarHeight),
          child: NavigationBar(
            backgroundColor: Colors.white24,
            selectedIndex: _selectedTab,
            onDestinationSelected: (index) =>
              setState(() => _selectedTab = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.store_outlined),
                selectedIcon: Icon(Icons.store),
                label: 'Settings',
              ),
              NavigationDestination(
                icon: Icon(Icons.shopping_bag_outlined),
                selectedIcon: Icon(Icons.shopping_bag),
                label: 'Edit Products'
              ),
            ],
          ),
        ),
      ),
      body: _selectedTab == 0
        ? StoreSettingsPage()
        : StoreProductsPage(),
    );
  }
}

