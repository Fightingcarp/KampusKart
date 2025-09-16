import 'package:flutter/material.dart';
import 'package:kampus_kart/pages/login_page.dart';
import 'package:kampus_kart/pages/home_page.dart';
import 'package:kampus_kart/pages/store_page.dart';

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
  }

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
                    showUnselectedLabels: true,
                    selectedItemColor: Colors.black,
                    unselectedItemColor: Colors.grey,
                    items: [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home),
                        label: 'Home',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.favorite),
                        label: 'Store',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.store),
                        label: 'Seller',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.chat),
                        label: 'Chat',
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
                        label: Text('Home'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.person),
                        label: Text('Store'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.chat),
                        label: Text('Seller'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.chat),
                        label: Text('Chat'),
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