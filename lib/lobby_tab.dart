import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'booking_tab.dart';
import 'login_tab.dart';

class LobbyTab extends StatefulWidget {
  @override
  _LobbyTabState createState() => _LobbyTabState();
}

class _LobbyTabState extends State<LobbyTab> with SingleTickerProviderStateMixin {
  final Color primaryGold = const Color(0xFFFFD700);
  final Color surfaceDark = const Color(0xFF1A1A1A);

  bool _isCheckingAuth = true;
  bool _isLoggedIn = false;

  bool _isLoading = false;
  bool _hasError = false;
  String? _currentLobbyCode;
  Map<String, dynamic>? _lobbyData;
  List<dynamic> _menuItems = [];
  Timer? _pollingTimer;

  late TabController _tabController;
  final TextEditingController _joinCodeController = TextEditingController();

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  final ScrollController _ingredientsScrollController = ScrollController();

  final Map<int, String> _allIngredients = {
    1: "Meat", 2: "Chicken", 3: "Pork", 4: "Beef", 5: "Bacon",
    6: "Cheese", 7: "Mozzarella", 8: "Parmesan", 9: "Mushrooms", 10: "Truffle",
    11: "Garlic", 12: "Onion", 13: "Tomatoes", 14: "Olives", 15: "Basil",
    16: "Cream", 17: "Fish", 18: "Salmon", 19: "Shrimp", 20: "Seafood",
    21: "Dough", 22: "Chocolate", 23: "Berries", 24: "Honey", 25: "Nuts",
    26: "Avocado", 27: "Feta", 28: "Hot pepper", 29: "Pineapple", 30: "Potato"
  };
  Set<int> _selectedDisliked = {};

  // Local tags database (relation: Dish ID -> tags)
  final Map<int, Map<String, List<String>>> _dishTags = {
    1: {'tastes': ['Savory', 'Hearty', 'Piquant'], 'ings': ["Meat", "Chicken", "Cheese", "Mozzarella", "Berries"]},
    2: {'tastes': ['Vegetarian', 'Savory', 'Hearty', 'Piquant'], 'ings': ["Cheese", "Nuts"]},
    3: {'tastes': ['Savory', 'Hearty', 'Mushroom', 'Piquant'], 'ings': ["Cheese", "Parmesan", "Mushrooms", "Truffle"]},
    4: {'tastes': ['Savory', 'Hearty', 'Piquant'], 'ings': ["Meat"]},
    5: {'tastes': ['Savory', 'Hearty', 'Piquant'], 'ings': ["Meat", "Seafood", "Avocado"]},
    6: {'tastes': ['Savory', 'Hearty', 'Mushroom', 'Piquant'], 'ings': ["Meat", "Mushrooms", "Truffle"]},
    7: {'tastes': ['Savory', 'Hearty', 'Piquant'], 'ings': ["Meat", "Beef"]},
    8: {'tastes': ['Savory', 'Hearty', 'Mushroom', 'Piquant'], 'ings': ["Meat", "Beef", "Cheese", "Mushrooms", "Truffle"]},
    9: {'tastes': ['Savory', 'Cold', 'Hearty', 'Piquant'], 'ings': ["Fish", "Salmon", "Avocado"]},
    10: {'tastes': ['Savory', 'Hearty', 'Mushroom', 'Piquant'], 'ings': ["Mushrooms", "Truffle", "Cream"]},
    11: {'tastes': ['Savory', 'Hearty', 'Piquant'], 'ings': ["Meat", "Seafood", "Dough", "Avocado"]},
    12: {'tastes': ['Savory', 'Hearty', 'Piquant'], 'ings': ["Seafood"]},
    13: {'tastes': ['Savory', 'Hearty', 'Piquant'], 'ings': ["Cheese"]},
    14: {'tastes': ['Savory', 'Hearty', 'Mushroom', 'Piquant'], 'ings': ["Mushrooms", "Truffle", "Chocolate"]},
    15: {'tastes': ['Savory', 'Hearty', 'Piquant'], 'ings': ["Cream", "Berries"]},
    16: {'tastes': ['Vegetarian', 'Savory', 'Hearty', 'Piquant'], 'ings': ["Meat", "Beef", "Cheese"]},
    17: {'tastes': ['Savory', 'Hearty', 'Piquant'], 'ings': []},
    18: {'tastes': ['Savory', 'Cold', 'Hearty', 'Piquant'], 'ings': ["Meat", "Pork"]},
    19: {'tastes': ['Savory', 'Hearty', 'Piquant'], 'ings': ["Cheese"]},
    20: {'tastes': ['Savory', 'Hearty', 'Piquant'], 'ings': ["Meat", "Fish", "Salmon"]},

    // 21-40 (Pizza)
    21: {'tastes': ['Spicy', 'Hearty', 'Crispy', 'Piquant'], 'ings': ["Cheese", "Mozzarella", "Tomatoes", "Dough", "Hot pepper"]},
    22: {'tastes': ['Hearty', 'Mushroom', 'Crispy', 'Piquant'], 'ings': ["Cheese", "Mushrooms", "Fish", "Dough"]},
    23: {'tastes': ['Hearty', 'Crispy', 'Piquant'], 'ings': ["Chicken", "Cheese", "Dough", "Pineapple"]},
    24: {'tastes': ['Vegetarian', 'Hearty', 'Crispy', 'Piquant'], 'ings': ["Cheese", "Onion", "Dough", "Feta", "Hot pepper"]},
    25: {'tastes': ['Hearty', 'Crispy', 'Piquant'], 'ings': ["Meat", "Pork", "Bacon", "Cheese", "Dough"]},
    26: {'tastes': ['Hearty', 'Crispy', 'Piquant'], 'ings': ["Cheese", "Tomatoes", "Dough"]},
    27: {'tastes': ['Vegetarian', 'Hearty', 'Crispy', 'Piquant'], 'ings': ["Cheese", "Mozzarella", "Basil", "Dough"]},
    28: {'tastes': ['Hearty', 'Crispy', 'Piquant'], 'ings': ["Cheese", "Tomatoes", "Olives", "Dough", "Feta"]},
    29: {'tastes': ['Hearty', 'Crispy', 'Piquant'], 'ings': ["Cheese", "Dough"]},
    30: {'tastes': ['Hearty', 'Mushroom', 'Crispy', 'Piquant'], 'ings': ["Meat", "Pork", "Bacon", "Cheese", "Mushrooms", "Cream", "Fish", "Dough"]},
    31: {'tastes': ['Spicy', 'Hearty', 'Crispy', 'Piquant'], 'ings': ["Cheese", "Dough", "Hot pepper"]},
    32: {'tastes': ['Hearty', 'Crispy', 'Piquant'], 'ings': ["Cheese", "Olives", "Dough"]},
    33: {'tastes': ['Hearty', 'Crispy', 'Piquant'], 'ings': ["Cheese", "Onion", "Olives", "Fish", "Dough"]},
    34: {'tastes': ['Hearty', 'Crispy', 'Piquant'], 'ings': ["Chicken", "Cheese", "Onion", "Dough"]},
    35: {'tastes': ['Vegetarian', 'Hearty', 'Crispy', 'Piquant'], 'ings': ["Cheese", "Cream", "Dough"]},
    36: {'tastes': ['Hearty', 'Crispy', 'Piquant'], 'ings': ["Cheese", "Cream", "Fish", "Salmon", "Dough"]},
    37: {'tastes': ['Hearty', 'Mushroom', 'Crispy', 'Piquant'], 'ings': ["Cheese", "Mushrooms", "Tomatoes", "Fish", "Dough"]},
    38: {'tastes': ['Hearty', 'Mushroom', 'Crispy', 'Piquant'], 'ings': ["Chicken", "Cheese", "Mushrooms", "Cream", "Fish", "Dough"]},
    39: {'tastes': ['Vegetarian', 'Hearty', 'Crispy', 'Piquant'], 'ings': ["Cheese", "Dough", "Feta"]},
    40: {'tastes': ['Hearty', 'Crispy', 'Piquant'], 'ings': ["Meat", "Pork", "Bacon", "Cheese", "Onion", "Dough"]},

    // 41-60 (Meat Dishes)
    41: {'tastes': ['Spicy', 'Savory', 'Hearty', 'Smoky'], 'ings': ["Meat", "Beef"]},
    42: {'tastes': ['Savory', 'Hearty', 'Smoky'], 'ings': ["Meat", "Pork"]},
    43: {'tastes': ['Spicy', 'Savory', 'Hearty', 'Smoky'], 'ings': ["Meat", "Chicken"]},
    44: {'tastes': ['Savory', 'Hearty', 'Smoky'], 'ings': ["Meat", "Beef"]},
    45: {'tastes': ['Savory', 'Hearty', 'Smoky'], 'ings': ["Meat", "Pork"]},
    46: {'tastes': ['Savory', 'Hearty', 'Smoky'], 'ings': ["Meat", "Chicken", "Onion", "Cream"]},
    47: {'tastes': ['Savory', 'Hearty', 'Smoky'], 'ings': ["Meat", "Garlic"]},
    48: {'tastes': ['Savory', 'Hearty', 'Smoky'], 'ings': ["Meat", "Beef"]},
    49: {'tastes': ['Savory', 'Hearty', 'Smoky'], 'ings': ["Meat", "Chicken"]},
    50: {'tastes': ['Savory', 'Hearty', 'Smoky'], 'ings': ["Meat", "Pork", "Cheese"]},
    51: {'tastes': ['Vegetarian', 'Savory', 'Hearty', 'Smoky', 'Mushroom'], 'ings': ["Meat", "Beef", "Mushrooms", "Fish"]},
    52: {'tastes': ['Savory', 'Hearty', 'Smoky'], 'ings': ["Meat", "Chicken", "Garlic", "Cream"]},
    53: {'tastes': ['Savory', 'Hearty', 'Smoky'], 'ings': ["Meat", "Honey"]},
    54: {'tastes': ['Savory', 'Hearty', 'Smoky'], 'ings': ["Meat", "Beef"]},
    55: {'tastes': ['Spicy', 'Savory', 'Hearty', 'Smoky'], 'ings': ["Meat", "Chicken", "Hot pepper"]},
    56: {'tastes': ['Savory', 'Hearty', 'Smoky'], 'ings': ["Meat", "Beef"]},
    57: {'tastes': ['Savory', 'Hearty', 'Smoky'], 'ings': ["Meat", "Pork"]},
    58: {'tastes': ['Savory', 'Hearty', 'Smoky'], 'ings': ["Meat", "Chicken"]},
    59: {'tastes': ['Savory', 'Hearty', 'Smoky'], 'ings': ["Meat", "Beef"]},
    60: {'tastes': ['Savory', 'Hearty', 'Smoky'], 'ings': ["Meat"]},

    // 61-80 (Salads)
    61: {'tastes': ['Cold', 'Light', 'Dietary'], 'ings': ["Fish", "Potato"]},
    62: {'tastes': ['Cold', 'Light', 'Dietary'], 'ings': ["Seafood"]},
    63: {'tastes': ['Vegetarian', 'Cold', 'Light', 'Dietary'], 'ings': ["Cheese"]},
    64: {'tastes': ['Cold', 'Light', 'Dietary'], 'ings': ["Seafood"]},
    65: {'tastes': ['Cold', 'Light', 'Mushroom', 'Dietary'], 'ings': ["Mushrooms", "Onion", "Fish"]},
    66: {'tastes': ['Cold', 'Hearty', 'Light', 'Dietary'], 'ings': ["Meat", "Beef"]},
    67: {'tastes': ['Cold', 'Hearty', 'Light', 'Dietary'], 'ings': ["Chicken", "Cheese", "Pineapple"]},
    68: {'tastes': ['Cold', 'Hearty', 'Light', 'Dietary'], 'ings': ["Meat", "Pork", "Bacon"]},
    69: {'tastes': ['Cold', 'Light', 'Dietary'], 'ings': ["Cheese", "Mozzarella", "Tomatoes"]},
    70: {'tastes': ['Cold', 'Light', 'Dietary'], 'ings': ["Cheese", "Parmesan"]},
    71: {'tastes': ['Cold', 'Light', 'Dietary'], 'ings': ["Fish"]},
    72: {'tastes': ['Cold', 'Light', 'Dietary'], 'ings': ["Cheese", "Olives", "Feta"]},
    73: {'tastes': ['Cold', 'Light', 'Dietary'], 'ings': ["Shrimp", "Seafood", "Avocado"]},
    74: {'tastes': ['Vegetarian', 'Cold', 'Light', 'Dietary'], 'ings': ["Cheese", "Feta"]},
    75: {'tastes': ['Cold', 'Light', 'Dietary'], 'ings': ["Fish", "Salmon"]},
    76: {'tastes': ['Cold', 'Light', 'Dietary'], 'ings': ["Chicken", "Berries", "Nuts"]},
    77: {'tastes': ['Vegetarian', 'Cold', 'Light', 'Dietary'], 'ings': []},
    78: {'tastes': ['Cold', 'Light', 'Dietary'], 'ings': []},
    79: {'tastes': ['Cold', 'Light', 'Dietary'], 'ings': ["Cheese", "Nuts", "Feta"]},
    80: {'tastes': ['Cold', 'Light', 'Dietary'], 'ings': ["Seafood"]},

    // 81-90 (Soups)
    81: {'tastes': ['Vegetarian', 'Savory', 'Hearty', 'Creamy'], 'ings': ["Cream"]},
    82: {'tastes': ['Savory', 'Hearty', 'Creamy'], 'ings': []},
    83: {'tastes': ['Savory', 'Hearty', 'Creamy'], 'ings': ["Chicken"]},
    84: {'tastes': ['Vegetarian', 'Savory', 'Hearty', 'Creamy', 'Mushroom'], 'ings': ["Mushrooms", "Fish", "Potato"]},
    85: {'tastes': ['Vegetarian', 'Savory', 'Hearty', 'Creamy'], 'ings': ["Tomatoes", "Basil"]},
    86: {'tastes': ['Savory', 'Hearty', 'Creamy'], 'ings': ["Cream", "Fish", "Salmon"]},
    87: {'tastes': ['Savory', 'Hearty', 'Creamy'], 'ings': ["Cheese", "Parmesan"]},
    88: {'tastes': ['Savory', 'Hearty', 'Creamy'], 'ings': ["Chicken"]},
    89: {'tastes': ['Savory', 'Hearty', 'Creamy'], 'ings': ["Cream", "Nuts"]},
    90: {'tastes': ['Vegetarian', 'Savory', 'Hearty', 'Creamy'], 'ings': ["Cheese", "Cream"]},

    // 91-100 (Burgers)
    91: {'tastes': ['Hearty', 'Smoky', 'Crispy'], 'ings': ["Meat", "Beef", "Tomatoes", "Dough"]},
    92: {'tastes': ['Hearty', 'Smoky', 'Crispy'], 'ings': ["Meat", "Chicken", "Cheese", "Dough"]},
    93: {'tastes': ['Hearty', 'Smoky', 'Crispy'], 'ings': ["Meat", "Pork", "Bacon", "Dough"]},
    94: {'tastes': ['Hearty', 'Smoky', 'Mushroom', 'Crispy'], 'ings': ["Meat", "Mushrooms", "Fish", "Dough"]},
    95: {'tastes': ['Vegetarian', 'Hearty', 'Smoky', 'Crispy'], 'ings': ["Meat", "Cheese", "Dough"]},
    96: {'tastes': ['Hearty', 'Smoky', 'Crispy'], 'ings': ["Meat", "Fish", "Salmon", "Dough"]},
    97: {'tastes': ['Hearty', 'Smoky', 'Crispy'], 'ings': ["Meat", "Dough"]},
    98: {'tastes': ['Vegetarian', 'Hearty', 'Smoky', 'Crispy'], 'ings': ["Meat", "Dough", "Avocado"]},
    99: {'tastes': ['Hearty', 'Smoky', 'Crispy'], 'ings': ["Meat", "Pork", "Bacon", "Dough"]},
    100: {'tastes': ['Hearty', 'Smoky', 'Crispy'], 'ings': ["Meat", "Chicken", "Dough"]},

    // 101-110 (Pasta)
    101: {'tastes': ['Hearty', 'Creamy', 'Piquant'], 'ings': ["Tomatoes", "Dough"]},
    102: {'tastes': ['Hearty', 'Creamy', 'Piquant'], 'ings': ["Cheese", "Mushrooms", "Cream", "Fish", "Dough", "Feta"]},
    103: {'tastes': ['Spicy', 'Hearty', 'Creamy', 'Piquant'], 'ings': ["Tomatoes", "Dough", "Hot pepper"]},
    104: {'tastes': ['Hearty', 'Creamy', 'Piquant'], 'ings': ["Shrimp", "Seafood", "Dough"]},
    105: {'tastes': ['Hearty', 'Creamy', 'Piquant'], 'ings': ["Meat", "Pork", "Bacon", "Dough"]},
    106: {'tastes': ['Hearty', 'Creamy', 'Piquant'], 'ings': ["Cream", "Fish", "Salmon", "Dough"]},
    107: {'tastes': ['Hearty', 'Creamy', 'Piquant'], 'ings': ["Chicken", "Basil", "Dough"]},
    108: {'tastes': ['Hearty', 'Creamy', 'Mushroom', 'Piquant'], 'ings': ["Mushrooms", "Cream", "Fish", "Dough"]},
    109: {'tastes': ['Hearty', 'Creamy', 'Piquant'], 'ings': ["Tomatoes", "Basil", "Dough"]},
    110: {'tastes': ['Hearty', 'Creamy', 'Piquant'], 'ings': ["Cheese", "Mozzarella", "Tomatoes", "Dough"]},

    // 111-120 (Desserts)
    111: {'tastes': ['Cold', 'Sweet', 'Light', 'Fruity'], 'ings': ["Cheese", "Cream"]},
    112: {'tastes': ['Sweet', 'Light', 'Fruity'], 'ings': ["Cheese", "Dough"]},
    113: {'tastes': ['Sweet', 'Light', 'Fruity'], 'ings': ["Cheese", "Cream", "Dough"]},
    114: {'tastes': ['Sweet', 'Light', 'Fruity'], 'ings': ["Cheese"]},
    115: {'tastes': ['Sweet', 'Light', 'Fruity'], 'ings': ["Cheese", "Berries"]},
    116: {'tastes': ['Sweet', 'Light', 'Fruity'], 'ings': ["Cheese"]},
    117: {'tastes': ['Sweet', 'Light', 'Fruity'], 'ings': ["Cheese"]},
    118: {'tastes': ['Sweet', 'Light', 'Fruity'], 'ings': ["Cheese", "Berries"]},
    119: {'tastes': ['Sweet', 'Light', 'Fruity'], 'ings': ["Cheese", "Chocolate"]},
    120: {'tastes': ['Sweet', 'Light', 'Fruity'], 'ings': ["Cheese", "Honey"]},

    // 121-130 (Non-alcoholic drinks)
    121: {'tastes': ['Sweet', 'Light', 'Fruity'], 'ings': []},
    122: {'tastes': ['Sweet', 'Light', 'Fruity'], 'ings': []},
    123: {'tastes': ['Sweet', 'Light', 'Fruity'], 'ings': ["Cheese"]},
    124: {'tastes': ['Sweet', 'Light', 'Fruity'], 'ings': ["Berries"]},
    125: {'tastes': ['Sweet', 'Light', 'Fruity'], 'ings': []},
    126: {'tastes': ['Sweet', 'Light', 'Fruity'], 'ings': []},
    127: {'tastes': ['Cold', 'Sweet', 'Light', 'Fruity'], 'ings': []},
    128: {'tastes': ['Sweet', 'Light', 'Fruity'], 'ings': []},
    129: {'tastes': ['Sweet', 'Light', 'Fruity'], 'ings': []},
    130: {'tastes': ['Sweet', 'Light', 'Fruity'], 'ings': ["Cream", "Chocolate"]},

    // 131-180 (Beer, Wine, Alcohol, Cocktails)
    131: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': []},
    132: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': []},
    133: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': []},
    134: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': []},
    135: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': []},
    136: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': []},
    137: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': ["Berries"]},
    138: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': []},
    139: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': []},
    140: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': []},
    141: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': []},
    142: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': []},
    143: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': ["Berries"]},
    144: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': []},
    145: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': []},
    146: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': []},
    147: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': []},
    148: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': []},
    149: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': []},
    150: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': []},
    151: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': []},
    152: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': []},
    153: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': []},
    154: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': []},
    155: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': []},
    156: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': []},
    157: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': []},
    158: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': []},
    159: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': []},
    160: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': []},
    161: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': []},
    162: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': []},
    163: {'tastes': ['Spicy', 'Cold', 'Light', 'Piquant'], 'ings': ["Tomatoes"]},
    164: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': ["Berries"]},
    165: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': []},
    166: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': ["Cheese", "Berries"]},
    167: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': ["Pineapple"]},
    168: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': []},
    169: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': []},
    170: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': ["Cream"]},
    171: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': []},
    172: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': []},
    173: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': []},
    174: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': []},
    175: {'tastes': ['Spicy', 'Cold', 'Light', 'Piquant'], 'ings': ["Tomatoes"]},
    176: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': ["Berries"]},
    177: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': ["Berries"]},
    178: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': ["Cream"]},
    179: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': ["Olives"]},
    180: {'tastes': ['Cold', 'Light', 'Piquant'], 'ings': ["Berries"]},
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    String? userId = await ApiService.getUserId();
    if (mounted) {
      setState(() {
        _isLoggedIn = userId != null;
        _isCheckingAuth = false;
      });
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _joinCodeController.dispose();
    _searchController.dispose();
    _ingredientsScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _createLobby() async {
    setState(() { _isLoading = true; _hasError = false; });
    String? userId = await ApiService.getUserId();

    if (userId != null) {
      var result = await ApiService.createLobby(userId);
      if (result != null && result['code'] != null) {
        _currentLobbyCode = result['code'];
        await _loadInitialData();
      } else {
        _showError('Server error. Please try again.');
      }
    } else {
      _showError('Please log in.');
    }
    setState(() { _isLoading = false; });
  }

  Future<void> _joinLobby() async {
    String code = _joinCodeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() { _isLoading = true; _hasError = false; });
    String? userId = await ApiService.getUserId();

    if (userId != null) {
      bool success = await ApiService.joinLobby(userId, code);
      if (success) {
        _currentLobbyCode = code;
        await _loadInitialData();
      } else {
        _showError('Lobby not found or login error.');
      }
    } else {
      _showError('Please log in.');
    }
    setState(() { _isLoading = false; });
  }

  Future<void> _loadInitialData() async {
    var menu = await ApiService.fetchMenu();
    setState(() { _menuItems = menu; });

    await _fetchLobbyStatus();
    if (_lobbyData != null) {
      _startPolling();
    } else {
      setState(() { _hasError = true; });
    }
  }

  Future<void> _fetchLobbyStatus() async {
    if (_currentLobbyCode == null) return;
    var data = await ApiService.getLobbyStatus(_currentLobbyCode!);
    if (mounted) {
      setState(() {
        _lobbyData = data;
        _hasError = data == null;
      });
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      _fetchLobbyStatus();
    });
  }

  void _leaveLobby() {
    _pollingTimer?.cancel();
    setState(() {
      _currentLobbyCode = null;
      _lobbyData = null;
      _joinCodeController.clear();
      _searchController.clear();
      _searchQuery = "";
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  String _extractName(dynamic obj) {
    if (obj is String) return obj;
    if (obj is Map) {
      if (obj['name'] != null) return obj['name'].toString();
      if (obj['Name'] != null) return obj['Name'].toString();

      if (obj['tasteTag'] is Map && obj['tasteTag']['name'] != null) return obj['tasteTag']['name'].toString();
      if (obj['TasteTag'] is Map && obj['TasteTag']['Name'] != null) return obj['TasteTag']['Name'].toString();
      if (obj['ingredient'] is Map && obj['ingredient']['name'] != null) return obj['ingredient']['name'].toString();
      if (obj['Ingredient'] is Map && obj['Ingredient']['Name'] != null) return obj['Ingredient']['Name'].toString();
    }
    return obj.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      // Додана кнопка AI Waiter
      floatingActionButton: (_currentLobbyCode != null && !_hasError && _lobbyData != null && _isLoggedIn)
          ? Padding(
        padding: const EdgeInsets.only(bottom: 20.0), // Трішки піднята над табами
        child: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const AiChatModal(),
            );
          },
          backgroundColor: primaryGold,
          elevation: 10,
          child: const Icon(Icons.auto_awesome, color: Colors.black, size: 28),
        ),
      )
          : null,

      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: primaryGold),
        title: Text('Compromise', style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          if (_currentLobbyCode != null && _isLoggedIn)
            IconButton(icon: const Icon(Icons.exit_to_app, color: Colors.redAccent), onPressed: _leaveLobby)
        ],
        bottom: _currentLobbyCode != null && !_hasError && _lobbyData != null && _isLoggedIn
            ? TabBar(
          controller: _tabController,
          indicatorColor: primaryGold,
          labelColor: primaryGold,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline), text: 'Status'),
            Tab(icon: Icon(Icons.restaurant_menu), text: 'Menu'),
            Tab(icon: Icon(Icons.shopping_cart), text: 'Cart'),
          ],
        )
            : null,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: Image.network('https://images.unsplash.com/photo-1555396273-367ea4eb4db5?q=80&w=2000', fit: BoxFit.cover)),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.85))),

          SafeArea(
            child: _isCheckingAuth
                ? Center(child: CircularProgressIndicator(color: primaryGold))
                : (!_isLoggedIn
                ? _buildGuestScreen()
                : (_isLoading
                ? Center(child: CircularProgressIndicator(color: primaryGold))
                : (_currentLobbyCode == null
                ? _buildJoinScreen()
                : (_hasError || _lobbyData == null)
                ? _buildErrorScreen()
                : TabBarView(
              controller: _tabController,
              children: [
                _buildStatusTab(),
                _buildMenuTab(),
                _buildCartTab(),
              ],
            )
            )
            )
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                  color: surfaceDark.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: primaryGold.withOpacity(0.3))
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, color: primaryGold, size: 64),
                  const SizedBox(height: 16),
                  Text('Authorization required', textAlign: TextAlign.center, style: TextStyle(color: primaryGold, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('To access the Shared Lobby, please log in or register.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Scaffold(
                              appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
                              extendBodyBehindAppBar: true,
                              body: LoginTab(
                                onLoginSuccess: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          ),
                        ).then((_) {
                          setState(() { _isCheckingAuth = true; });
                          _checkAuth();
                        });
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: primaryGold, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                      child: const Text('LOG IN / REGISTER', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJoinScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: surfaceDark.withOpacity(0.8), borderRadius: BorderRadius.circular(24), border: Border.all(color: primaryGold.withOpacity(0.3))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.group_add, color: primaryGold, size: 64),
                  const SizedBox(height: 16),
                  const Text('Shared Order', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Combine budgets and choose dishes together with friends!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 32),
                  SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _createLobby, style: ElevatedButton.styleFrom(backgroundColor: primaryGold, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: const Text('CREATE NEW LOBBY', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)))),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('OR', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold))),
                  TextField(controller: _joinCodeController, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 5.0, fontWeight: FontWeight.bold), textCapitalization: TextCapitalization.characters, decoration: InputDecoration(hintText: 'LOBBY CODE', filled: true, fillColor: Colors.black.withOpacity(0.5), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
                  const SizedBox(height: 16),
                  SizedBox(width: double.infinity, height: 50, child: OutlinedButton(onPressed: _joinLobby, style: OutlinedButton.styleFrom(foregroundColor: primaryGold, side: BorderSide(color: primaryGold, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: const Text('JOIN', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, color: Colors.redAccent, size: 64),
          const SizedBox(height: 16),
          const Text('Lost connection to the lobby', style: TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() { _isLoading = true; });
              _loadInitialData().then((_) => setState(() { _isLoading = false; }));
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryGold, foregroundColor: Colors.black),
            child: const Text('REFRESH'),
          )
        ],
      ),
    );
  }

  Widget _buildStatusTab() {
    List members = _lobbyData!['members'] ?? _lobbyData!['users'] ?? [];
    List disliked = _lobbyData!['dislikedIngredients'] ?? [];
    double totalBudget = double.tryParse(_lobbyData!['totalBudget']?.toString() ?? '0') ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(color: primaryGold.withOpacity(0.2), borderRadius: BorderRadius.circular(30), border: Border.all(color: primaryGold)),
              child: Text('Lobby code: $_currentLobbyCode', style: TextStyle(color: primaryGold, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
            ),
          ),
          const SizedBox(height: 24),

          _buildGlassCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total budget', style: TextStyle(color: Colors.white54, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('\$$totalBudget', style: TextStyle(color: primaryGold, fontSize: 28, fontWeight: FontWeight.bold)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showBudgetDialog,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white12, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('My contribution'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text('Company (${members.length})', style: TextStyle(color: primaryGold, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildGlassCard(
            child: Column(
              children: members.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      const Icon(Icons.person, color: Colors.white54),
                      const SizedBox(width: 12),
                      Text(m['fullName'] ?? m['name'] ?? 'Guest', style: const TextStyle(color: Colors.white, fontSize: 16))
                    ]),
                    Text('\$${m['budget']}', style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
                  ],
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 24),

          Text('Settings: I DO NOT eat', style: TextStyle(color: primaryGold, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildGlassCard(
            child: Column(
              children: [
                if (disliked.isNotEmpty) ...[
                  const Align(alignment: Alignment.centerLeft, child: Text('The group does not eat:', style: TextStyle(color: Colors.redAccent, fontSize: 14))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: disliked.map((i) => Chip(
                      label: Text(i['name'], style: const TextStyle(color: Colors.white, fontSize: 12)),
                      backgroundColor: Colors.redAccent.withOpacity(0.2),
                      side: const BorderSide(color: Colors.redAccent),
                    )).toList(),
                  ),
                  const Divider(color: Colors.white24, height: 30),
                ],

                const Align(alignment: Alignment.centerLeft, child: Text('Your preferences:', style: TextStyle(color: Colors.white54, fontSize: 14))),
                const SizedBox(height: 10),

                SizedBox(
                  height: 200,
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      scrollbarTheme: ScrollbarThemeData(
                        thumbColor: WidgetStateProperty.all(primaryGold),
                        thickness: WidgetStateProperty.all(6),
                        radius: const Radius.circular(10),
                      ),
                    ),
                    child: Scrollbar(
                      controller: _ingredientsScrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      child: ListView.builder(
                        controller: _ingredientsScrollController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _allIngredients.length,
                        itemBuilder: (context, index) {
                          int key = _allIngredients.keys.elementAt(index);
                          String name = _allIngredients[key]!;
                          return CheckboxListTile(
                            title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                            value: _selectedDisliked.contains(key),
                            activeColor: Colors.redAccent,
                            checkColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            contentPadding: const EdgeInsets.only(right: 20),
                            visualDensity: VisualDensity.compact,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedDisliked.add(key);
                                } else {
                                  _selectedDisliked.remove(key);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Preferences updated! Unwanted dishes are hidden from the menu.'), backgroundColor: Colors.green),
                      );
                      _tabController.animateTo(1);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: primaryGold, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    child: const Text('UPDATE MENU', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTab() {
    Set<String> dislikedNames = _selectedDisliked.map((id) => _allIngredients[id]!.toLowerCase()).toSet();

    List groupDisliked = _lobbyData?['dislikedIngredients'] ?? _lobbyData?['DislikedIngredients'] ?? [];
    for (var d in groupDisliked) {
      String dName = _extractName(d);
      if (dName.isNotEmpty) dislikedNames.add(dName.toLowerCase());
    }

    List<dynamic> filteredMenu = _menuItems.where((item) {
      String name = (item['name'] ?? item['Name'] ?? '').toLowerCase();
      if (_searchQuery.isNotEmpty && !name.contains(_searchQuery.toLowerCase())) {
        return false;
      }

      int dishId = int.tryParse(item['id']?.toString() ?? item['Id']?.toString() ?? '0') ?? 0;
      var localTags = _dishTags[dishId];

      if (localTags != null) {
        List<String> dishIngs = localTags['ings'] ?? [];
        for (String ing in dishIngs) {
          if (dislikedNames.contains(ing.toLowerCase())) {
            return false;
          }
        }
      }

      return true;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              color: surfaceDark.withOpacity(0.8),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: primaryGold.withOpacity(0.5)),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search for a dish...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),

        Expanded(
          child: filteredMenu.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 60, color: Colors.white24),
                const SizedBox(height: 16),
                const Text('Nothing found for your request', style: TextStyle(color: Colors.white54)),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: filteredMenu.length,
            itemBuilder: (context, index) {
              var item = filteredMenu[index];
              String name = item['name'] ?? item['Name'] ?? 'Dish';
              int dishId = item['id'] ?? item['Id'] ?? 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: surfaceDark.withOpacity(0.8), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.1))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                      child: Image.network(
                        (item['imageUrl'] != null && item['imageUrl'].toString().startsWith('/')) ? '${ApiService.baseUrl}${item['imageUrl']}' : 'https://via.placeholder.com/120',
                        width: 100, height: 160, fit: BoxFit.cover,
                        errorBuilder: (c,e,s) => Container(width: 100, height: 160, color: Colors.grey[800], child: const Icon(Icons.fastfood, color: Colors.white)),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),

                            Wrap(
                              spacing: 6, runSpacing: 6,
                              children: _buildTagsForDish(dishId),
                            ),

                            const SizedBox(height: 12),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('\$${item['price']}', style: TextStyle(color: primaryGold, fontSize: 16, fontWeight: FontWeight.bold)),
                                ElevatedButton(
                                  onPressed: () async {
                                    bool success = await ApiService.addToLobbyCart(_currentLobbyCode!, dishId);
                                    if (success) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name added!'), backgroundColor: Colors.green, duration: const Duration(seconds: 1)));
                                      _fetchLobbyStatus();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      side: BorderSide(color: primaryGold),
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      minimumSize: const Size(0, 32),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                                  ),
                                  child: Text('Add to cart', style: TextStyle(color: primaryGold, fontSize: 12, fontWeight: FontWeight.bold)),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _buildTagsForDish(int dishId) {
    List<Widget> tags = [];
    var dishData = _dishTags[dishId];

    if (dishData != null) {
      for (String taste in dishData['tastes'] ?? []) {
        tags.add(_buildTasteTag(taste));
      }
      for (String ing in dishData['ings'] ?? []) {
        tags.add(_buildIngredientTag(ing));
      }
    }

    if (tags.isEmpty) {
      tags.add(_buildTasteTag('Signature'));
    }

    return tags;
  }

  Widget _buildTasteTag(String tasteName) {
    IconData icon = Icons.local_dining;
    Color color = Colors.white70;

    switch (tasteName.toLowerCase()) {
      case 'spicy': icon = Icons.local_fire_department; color = Colors.redAccent; break;
      case 'vegetarian': icon = Icons.eco; color = Colors.green; break;
      case 'savory': icon = Icons.whatshot; color = Colors.deepOrangeAccent; break;
      case 'cold': icon = Icons.ac_unit; color = Colors.lightBlueAccent; break;
      case 'sweet': icon = Icons.icecream; color = Colors.pinkAccent; break;
      case 'sour': icon = Icons.sentiment_dissatisfied; color = Colors.limeAccent; break;
      case 'hearty': icon = Icons.lunch_dining; color = Colors.orangeAccent; break;
      case 'light': icon = Icons.spa; color = Colors.lightGreenAccent; break;
      case 'smoky': icon = Icons.cloud; color = Colors.grey; break;
      case 'creamy': icon = Icons.water_drop; color = Colors.yellow[200]!; break;
      case 'fruity': icon = Icons.apple; color = Colors.red; break;
      case 'mushroom': icon = Icons.park; color = Colors.brown[300]!; break;
      case 'dietary': icon = Icons.fitness_center; color = Colors.tealAccent; break;
      case 'crispy': icon = Icons.bolt; color = Colors.yellowAccent; break;
      case 'piquant': icon = Icons.star; color = Colors.amber; break;
      default: icon = Icons.star; color = primaryGold;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white24)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(tasteName, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildIngredientTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(10), border: Border.all(color: primaryGold.withOpacity(0.8), width: 1)),
      child: Text(text, style: TextStyle(color: primaryGold, fontSize: 10)),
    );
  }

  Widget _buildCartTab() {
    List cart = _lobbyData!['cart'] ?? [];
    double totalBudget = double.tryParse(_lobbyData!['totalBudget']?.toString() ?? '0') ?? 0.0;

    double currentCartTotal = cart.fold(0.0, (sum, item) => sum + ((double.tryParse(item['price']?.toString() ?? '0') ?? 0) * (item['quantity'] ?? 1)));
    double remaining = totalBudget - currentCartTotal;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildGlassCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Remaining balance:', style: TextStyle(color: Colors.white54, fontSize: 16)),
                      Text('\$$remaining', style: TextStyle(
                          color: remaining >= 0 ? Colors.greenAccent : Colors.redAccent,
                          fontSize: 20,
                          fontWeight: FontWeight.bold
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (cart.isEmpty)
                  const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Text('The shared cart is empty', style: TextStyle(color: Colors.white54, fontSize: 16))
                  )
                else
                  _buildGlassCard(
                    child: Column(
                      children: cart.map<Widget>((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: primaryGold.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                              child: Text('x${c['quantity']}', style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text('${c['name']}', style: const TextStyle(color: Colors.white, fontSize: 16))),
                            Text('\$${(double.tryParse(c['price']?.toString() ?? '0') ?? 0) * c['quantity']}', style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),

        if (cart.isNotEmpty)
          Container(
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
                    const Text('LOBBY TOTAL:', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    Text('\$$currentCartTotal', style: TextStyle(color: primaryGold, fontSize: 28, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: remaining >= 0 ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingTab(
                            isFromLobby: true,
                            lobbyCart: cart,
                            lobbyTotal: currentCartTotal,
                            lobbyCode: _currentLobbyCode,
                          ),
                        ),
                      );
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGold,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.grey[800],
                      disabledForegroundColor: Colors.white38,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(
                        remaining >= 0 ? 'PROCEED TO BOOKING' : 'INSUFFICIENT BUDGET',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.0)
                    ),
                  ),
                ),
              ],
            ),
          )
      ],
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: surfaceDark.withOpacity(0.6), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.1))),
          child: child,
        ),
      ),
    );
  }

  void _showBudgetDialog() {
    TextEditingController budgetController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: surfaceDark,
          title: Text('Your budget', style: TextStyle(color: primaryGold)),
          content: TextField(
            controller: budgetController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(hintText: 'Enter amount', hintStyle: TextStyle(color: Colors.white38), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFD700))), focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFD700)))),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryGold, foregroundColor: Colors.black),
              onPressed: () async {
                Navigator.pop(context);
                double? newBudget = double.tryParse(budgetController.text);
                String? userId = await ApiService.getUserId();

                if (newBudget != null && userId != null) {
                  await ApiService.updateLobbyBudget(userId, _currentLobbyCode!, newBudget);
                  _fetchLobbyStatus();
                }
              },
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );
  }
}

// Клас чату з AI
class AiChatModal extends StatefulWidget {
  const AiChatModal({Key? key}) : super(key: key);

  @override
  _AiChatModalState createState() => _AiChatModalState();
}

class _AiChatModalState extends State<AiChatModal> {
  final Color primaryGold = const Color(0xFFFFD700);
  final Color surfaceDark = const Color(0xFF1A1A1A);

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isTyping = false;

  List<Map<String, String>> _messages = [
    {'role': 'ai', 'text': 'Hello! I am your digital sommelier and menu assistant. What can I recommend you today?'}
  ];

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    String userText = _controller.text.trim();
    setState(() {
      _messages.add({'role': 'user', 'text': userText});
      _isTyping = true;
    });

    _controller.clear();
    _scrollToBottom();

    String aiResponse = await ApiService.askAiWaiter(_messages);

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add({'role': 'ai', 'text': aiResponse});
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: surfaceDark.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: primaryGold.withOpacity(0.3)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, color: primaryGold, size: 28),
                        const SizedBox(width: 12),
                        const Text('AI Waiter', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    bool isUser = msg['role'] == 'user';

                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isUser ? primaryGold : Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(0),
                            bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(20),
                          ),
                          border: isUser ? null : Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Text(
                          msg['text']!,
                          style: TextStyle(
                            color: isUser ? Colors.black : Colors.white,
                            fontSize: 15,
                            fontWeight: isUser ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              if (_isTyping)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('AI Waiter is typing...', style: TextStyle(color: primaryGold, fontSize: 13, fontStyle: FontStyle.italic)),
                  ),
                ),

              Container(
                padding: EdgeInsets.only(left: 20, right: 20, top: 12, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Ask about the menu...',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: surfaceDark,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _isTyping ? null : _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _isTyping ? Colors.grey : primaryGold,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send, color: Colors.black, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}