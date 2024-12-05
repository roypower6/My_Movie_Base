import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:my_movie_base/screens/favorites_screen.dart';
import 'package:my_movie_base/screens/home_screen.dart';
import 'package:my_movie_base/screens/search_screen.dart';
import 'package:my_movie_base/screens/setting_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<GButton> tabs = [
    const GButton(
      icon: Icons.movie_outlined,
      text: 'Home',
      iconActiveColor: Colors.blue,
      textColor: Colors.blue,
      iconColor: Colors.grey,
    ),
    const GButton(
      icon: Icons.favorite_outline,
      text: 'Like',
      iconActiveColor: Colors.red,
      textColor: Colors.red,
      iconColor: Colors.grey,
    ),
    const GButton(
      icon: Icons.search_rounded,
      text: 'Movie Search',
      iconActiveColor: Colors.green,
      textColor: Colors.green,
      iconColor: Colors.grey,
    ),
    const GButton(
      icon: Icons.settings,
      text: 'App Info',
      iconActiveColor: Colors.orange,
      textColor: Colors.orange,
      iconColor: Colors.grey,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          MovieListScreen(),
          FavoritesScreen(),
          SearchScreen(),
          SettingScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(.1),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: GNav(
              tabs: tabs,
              selectedIndex: _currentIndex,
              onTabChange: (index) {
                setState(() {
                  _currentIndex = index;
                });
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.fastEaseInToSlowEaseOut,
                );
              },
              gap: 8,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: Colors.grey[850]!,
              activeColor: Colors.white,
              curve: Curves.fastOutSlowIn,
              tabBorderRadius: 16,
            ),
          ),
        ),
      ),
    );
  }
}
