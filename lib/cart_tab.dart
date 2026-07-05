import 'dart:ui';
import 'package:flutter/material.dart';
import 'cart_manager.dart';
import 'api_service.dart';
import 'booking_tab.dart';

class CartTab extends StatefulWidget {
  @override
  _CartTabState createState() => _CartTabState();
}

class _CartTabState extends State<CartTab> {
  final Color primaryGold = const Color(0xFFFFD700);
  final Color surfaceDark = const Color(0xFF1A1A1A);

  Future<void> _handleCheckout() async {
    String? userId = await ApiService.getUserId();

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to place an order!'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingTab(isFromCart: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1514933651103-005eec06c04b?q=80&w=2000',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.75)),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 20, left: 10, right: 20),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          'CART',
                          style: TextStyle(color: primaryGold, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2.0),
                        ),
                      ),
                    ],
                  ),
                ),

                // List of items
                Expanded(
                  child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                    valueListenable: CartManager.cartItems,
                    builder: (context, items, child) {
                      if (items.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.remove_shopping_cart_outlined, color: Colors.white24, size: 80),
                              SizedBox(height: 16),
                              Text('Your cart is empty', style: TextStyle(color: Colors.white54, fontSize: 18)),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _buildCartItem(item, index);
                        },
                      );
                    },
                  ),
                ),

                // Bottom summary panel
                ValueListenableBuilder<List<Map<String, dynamic>>>(
                  valueListenable: CartManager.cartItems,
                  builder: (context, items, child) {
                    if (items.isEmpty) return const SizedBox();

                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: surfaceDark,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                        border: Border(top: BorderSide(color: primaryGold.withOpacity(0.3))),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('TOTAL:', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                              Text('\$${CartManager.getTotalPrice()}', style: TextStyle(color: primaryGold, fontSize: 28, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _handleCheckout,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGold,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                              child: const Text('PROCEED TO BOOKING', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, int index) {
    int quantity = item['quantity'] ?? 1;
    double rowTotal = (item['price'] as num).toDouble() * quantity;

    String imageUrl = item['imageUrl']?.toString() ?? '';
    if (imageUrl.startsWith('/')) {
      imageUrl = '${ApiService.baseUrl}$imageUrl';
    } else if (imageUrl.isEmpty) {
      imageUrl = 'https://via.placeholder.com/80.png?text=No+Image';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceDark.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 80, height: 80, color: Colors.grey[800], child: const Icon(Icons.fastfood, color: Colors.white54),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(item['name'] ?? item['Name'] ?? 'Dish', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    if (quantity > 1)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryGold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('x$quantity', style: TextStyle(color: primaryGold, fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('\$$rowTotal', style: TextStyle(color: primaryGold, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => CartManager.removeItem(index),
          ),
        ],
      ),
    );
  }
}