import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "http://kompromis.somee.com";

  // Local storage
  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
  }

  // Authentication
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'Email': email, 'Password': password}),
      );

      var data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        await saveUserId(data['userId']);
        return {'success': true, 'message': 'Login successful!'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Invalid login or password.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Server connection error.'};
    }
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password, String phone, String dob) async {
    try {
      final response = await http.post(
        // 🔥 ПОВЕРНУЛИ ПРАВИЛЬНИЙ МАРШРУТ ДО ТВОГО AuthApiController.cs:
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'Name': name,
          'Email': email,
          'Password': password,
          'Phone': phone,
          'Dob': dob
        }),
      );

      var data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Success! Please check your email for confirmation.'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Registration error. Email might already be taken.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Server connection error.'};
    }
  }

  static Future<bool> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'Email': email}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Menu
  static Future<List<dynamic>> fetchMenu() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/menu'));
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Profile and History
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/profile/$userId'));
      if (response.statusCode == 200) return json.decode(utf8.decode(response.bodyBytes));
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/profile/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<dynamic>> getOrderHistory(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/cart/history/$userId'));
      if (response.statusCode == 200) return json.decode(utf8.decode(response.bodyBytes));
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getFavorites(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/interactions/favorites/$userId'));
      if (response.statusCode == 200) {
        var data = json.decode(utf8.decode(response.bodyBytes));
        if (data is List) return data;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Interactions
  static Future<List<int>> getFavoriteIds(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/interactions/favorites/$userId'));
      if (response.statusCode == 200) {
        var data = json.decode(utf8.decode(response.bodyBytes));
        if (data is List) {
          return data.map((e) {
            var id = e['dishId'] ?? e['DishId'];
            return int.tryParse(id.toString()) ?? 0;
          }).where((id) => id > 0).toList().cast<int>();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool?> toggleFavorite(String userId, int dishId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/interactions/favorite/toggle'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'UserId': userId, 'DishId': dishId}),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        return data['isFavorite'] ?? data['IsFavorite'] ?? true;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<dynamic>> getReviews() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/interactions/reviews'));
      if (response.statusCode == 200) return json.decode(utf8.decode(response.bodyBytes));
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> addReview(String userId, String text, int rating) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/interactions/review/add'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': userId, 'text': text, 'rating': rating}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Cart and Checkout
  static Future<bool> addToCart(String userId, int dishId, int quantity) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/cart/add'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'UserId': userId, 'DishId': dishId, 'Quantity': quantity}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<dynamic>> getCart(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/cart/$userId'));
      if (response.statusCode == 200) return json.decode(utf8.decode(response.bodyBytes));
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> checkout(String userId, double totalPrice, List<Map<String, dynamic>> items) async {
    try {
      List<Map<String, dynamic>> formattedItems = items.map((item) => {
        'name': item['name']?.toString() ?? item['Name']?.toString() ?? 'Dish',
        'quantity': item['quantity'] ?? 1,
        'price': double.tryParse(item['price']?.toString() ?? item['Price']?.toString() ?? '0') ?? 0.0
      }).toList();

      final response = await http.post(
        Uri.parse('$baseUrl/api/cart/checkout'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'totalPrice': totalPrice,
          'items': formattedItems
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // AI Waiter
  static Future<String> askAiWaiter(List<Map<String, String>> history) async {
    try {
      List<Map<String, String>> formattedHistory = history.map((m) {
        return {
          'role': m['role'] == 'ai' ? 'model' : m['role']!,
          'text': m['text'] ?? ''
        };
      }).toList();

      final response = await http.post(
        Uri.parse('$baseUrl/Home/AskAiWaiter'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'history': formattedHistory}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['reply'] == "LIMIT_REACHED") return "The AI needs a break. Try again in a minute!";
        String replyText = data['reply'] ?? "The waiter is thinking...";
        replyText = replyText.replaceAll(RegExp(r'<[^>]*>'), '');
        return replyText;
      }
      return "AI connection error";
    } catch (e) {
      return "AI server is temporarily unavailable";
    }
  }

  // Shared Lobby
  static Future<Map<String, dynamic>?> createLobby(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/lobby/create'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'UserId': userId}),
      );
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        data['code'] = data['code'] ?? data['joinCode'];
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> joinLobby(String userId, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/lobby/join'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'UserId': userId, 'JoinCode': code}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getLobbyStatus(String code) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/lobby/status/$code'));
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> updateLobbyBudget(String userId, String code, double budget) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/lobby/update-budget'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'UserId': userId, 'JoinCode': code, 'Budget': budget}),
      );
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  static Future<bool> addToLobbyCart(String code, int dishId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/lobby/add-item'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'JoinCode': code, 'DishId': dishId}),
      );
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  static Future<bool> updateLobbyDisliked(String code, List<int> ingredientIds) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/lobby/update-disliked'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'JoinCode': code, 'IngredientIds': ingredientIds}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Booking
  static Future<bool> createBooking(Map<String, dynamic> bookingData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/booking/create'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(bookingData),
      );
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<int, List<String>>> getDailySchedule(String date) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/booking/schedule?date=$date'));

      if (response.statusCode == 200) {
        if (response.body.trim().startsWith('<')) {
          print('Server returned HTML. Cookies might be required for this request.');
          return {};
        }

        var decoded = json.decode(utf8.decode(response.bodyBytes));
        Map<int, List<String>> schedule = {};

        if (decoded is Map) {
          decoded.forEach((key, value) {
            int? tableId = int.tryParse(key.toString());
            if (tableId != null && value is List) {
              schedule[tableId] = value.map((e) => e.toString()).toList();
            }
          });
        }
        return schedule;
      }
      return {};
    } catch (e) {
      print('Schedule error: $e');
      return {};
    }
  }
}