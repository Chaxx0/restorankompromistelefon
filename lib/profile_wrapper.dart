import 'dart:async';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'profile_tab.dart';
import 'login_tab.dart';
class ProfileWrapper extends StatefulWidget {
  @override
  _ProfileWrapperState createState() => _ProfileWrapperState();
}
class _ProfileWrapperState extends State<ProfileWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }
  Future<void> _checkAuthStatus() async {
    setState(() { _isLoading = true; });
    String? userId = await ApiService.getUserId();
    setState(() {
      _isLoggedIn = userId != null;
      _isLoading = false;
    });
  }
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
    }
    if (_isLoggedIn) {
      return ProfileTab(onLogout: _checkAuthStatus);
    } else {
      return LoginTab(onLoginSuccess: _checkAuthStatus);
    }
  }
}