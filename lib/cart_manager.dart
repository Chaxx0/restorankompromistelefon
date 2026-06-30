import 'package:flutter/material.dart';

class CartManager {
  static final ValueNotifier<List<Map<String, dynamic>>> cartItems = ValueNotifier([]);
  static void addItem(Map<String, dynamic> item) {
    final newList = List<Map<String, dynamic>>.from(cartItems.value);

    int existingIndex = newList.indexWhere((element) => element['name'] == item['name']);
    if (existingIndex != -1) {
      int currentQuantity = newList[existingIndex]['quantity'] ?? 1;
      newList[existingIndex] = {
        ...newList[existingIndex],
        'quantity': currentQuantity + 1,
      };
    } else {
      newList.add({
        ...item,
        'quantity': 1,
      });
    }
    cartItems.value = newList;
  }
  static void removeItem(int index) {
    final newList = List<Map<String, dynamic>>.from(cartItems.value);
    newList.removeAt(index);
    cartItems.value = newList;
  }

  static void clearCart() {
    cartItems.value = [];
  }
  static double getTotalPrice() {
    return cartItems.value.fold(0, (sum, item) {
      int quantity = item['quantity'] ?? 1;
      return sum + ((item['price'] as num) * quantity);
    });
  }
}