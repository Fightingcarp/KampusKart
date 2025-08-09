import 'package:flutter/material.dart';
import 'package:kampus_kart/pages/store_page.dart';

class MyNavRail extends StatefulWidget {
  @override
  State<MyNavRail> createState() => _MyNavRailState();
}

class _MyNavRailState extends State<MyNavRail> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    
    @override
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = Placeholder();
      case 1:
        page = Placeholder();
      case 2:
        page = Placeholder();
      case 3:
        page = Placeholder();
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    var mainArea = ColoredBox(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 1000),
        child: page,
      ),
    );

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 450) {
            return Column(
              children: [
                Expanded(child: mainArea),
                SafeArea(
                  child: BottomNavigationBar(
                    items: [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home),
                        label: 'Home',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.favorite),
                        label: 'Favorites',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.chat),
                        label: 'Messages',
                      ),
                    ],
                    currentIndex: selectedIndex,
                    onTap: (value) {
                      setState(() {
                        selectedIndex = value;
                      });
                    }
                  ),
                ),
              ],
            );
          } else {
            return Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    extended: constraints.maxWidth >= 600,
                    destinations: [
                      NavigationRailDestination(
                        icon: Icon(Icons.store),
                        label: Text('Store'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.person),
                        label: Text('Seller'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.chat),
                        label: Text('Messages'),
                      ),
                    ],
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (value) {
                      setState(() {
                        selectedIndex = value;
                      });
                    }
                  ),
                ),
                Expanded(child: mainArea)
              ],
            );
          }
        }
      ),
    );
  }
}