import 'cart_tab.dart';
import 'cart_manager.dart';
import 'profile_wrapper.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'home_tab.dart';
import 'login_tab.dart';
import 'menu_tab.dart';
import 'booking_tab.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeTab(onTabChange: _changeTab),
      MenuTab(),
      BookingTab(),
      ProfileWrapper(),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: screens[_currentIndex],

      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.15), width: 1),
              ),
            ),
            child: Theme(
              data: ThemeData(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: _changeTab, // Використовуємо ту саму функцію для кнопок самої панелі
                backgroundColor: Colors.transparent,
                selectedItemColor: const Color(0xFFFFD700),
                unselectedItemColor: Colors.white70,
                type: BottomNavigationBarType.fixed,
                elevation: 0,
                selectedFontSize: 12,
                unselectedFontSize: 12,
                iconSize: 26,
                items: const [
                  BottomNavigationBarItem(
                      icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_outlined)),
                      activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home)),
                      label: 'Головна'
                  ),
                  BottomNavigationBarItem(
                      icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.restaurant_menu)),
                      label: 'Меню'
                  ),
                  BottomNavigationBarItem(
                      icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.event_seat_outlined)),
                      activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.event_seat)),
                      label: 'Бронювання'
                  ),
                  BottomNavigationBarItem(
                      icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person_outline)),
                      activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person)),
                      label: 'Акаунт'
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}