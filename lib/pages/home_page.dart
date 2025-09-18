import 'package:flutter/material.dart';
import 'products_section.dart';
import 'stores_section.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  String searchQuery = '';
  int _selectedTab = 0; // 0 = Products, 1 = Stores

  void updateSearch(String value) {
    setState(() => searchQuery = value.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      appBar: AppBar(
        title: SizedBox(
          height: 40,
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: _selectedTab == 0
                ? 'Search Products'
                : 'Search Stores',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey[300],
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: updateSearch,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Cart page coming soon!")),
              );
            },
          ),
        ],
        // put the nav bar right **under** the search bar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kBottomNavigationBarHeight),
          child: NavigationBar(
            backgroundColor: Colors.white24,
            selectedIndex: _selectedTab,
            onDestinationSelected: (index) =>
                setState(() => _selectedTab = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.shopping_bag_outlined),
                selectedIcon: Icon(Icons.shopping_bag),
                label: 'Products',
              ),
              NavigationDestination(
                icon: Icon(Icons.store_outlined),
                selectedIcon: Icon(Icons.store),
                label: 'Stores',
              ),
            ],
          ),
        ),
      ),
      body: _selectedTab == 0
          ? ProductsSection(searchQuery: searchQuery)
          : StoresSection(searchQuery: searchQuery)
    );
  }
}
