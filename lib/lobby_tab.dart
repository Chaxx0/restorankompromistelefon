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
    1: "М'ясо", 2: "Курка", 3: "Свинина", 4: "Яловичина", 5: "Бекон",
    6: "Сир", 7: "Моцарела", 8: "Пармезан", 9: "Гриби", 10: "Трюфель",
    11: "Часник", 12: "Цибуля", 13: "Томати", 14: "Оливки", 15: "Базилік",
    16: "Вершки", 17: "Риба", 18: "Лосось", 19: "Креветки", 20: "Морепродукти",
    21: "Тісто", 22: "Шоколад", 23: "Ягоди", 24: "Мед", 25: "Горіхи",
    26: "Авокадо", 27: "Фета", 28: "Гострий перець", 29: "Ананас", 30: "Картопля"
  };
  Set<int> _selectedDisliked = {};
  // Локальна база тегів (зв'язок: ID страви -> теги)
  final Map<int, Map<String, List<String>>> _dishTags = {

    1: {'tastes': ['Пряне', 'Ситне', 'Пікантне'], 'ings': ["М'ясо", "Курка", "Сир", "Моцарела", "Ягоди"]},
    2: {'tastes': ['Вегетаріанське', 'Пряне', 'Ситне', 'Пікантне'], 'ings': ["Сир", "Горіхи"]},
    3: {'tastes': ['Пряне', 'Ситне', 'Грибне', 'Пікантне'], 'ings': ["Сир", "Пармезан", "Гриби", "Трюфель"]},
    4: {'tastes': ['Пряне', 'Ситне', 'Пікантне'], 'ings': ["М'ясо"]},
    5: {'tastes': ['Пряне', 'Ситне', 'Пікантне'], 'ings': ["М'ясо", "Морепродукти", "Авокадо"]},
    6: {'tastes': ['Пряне', 'Ситне', 'Грибне', 'Пікантне'], 'ings': ["М'ясо", "Гриби", "Трюфель"]},
    7: {'tastes': ['Пряне', 'Ситне', 'Пікантне'], 'ings': ["М'ясо", "Яловичина"]},
    8: {'tastes': ['Пряне', 'Ситне', 'Грибне', 'Пікантне'], 'ings': ["М'ясо", "Яловичина", "Сир", "Гриби", "Трюфель"]},
    9: {'tastes': ['Пряне', 'Холодне', 'Ситне', 'Пікантне'], 'ings': ["Риба", "Лосось", "Авокадо"]},
    10: {'tastes': ['Пряне', 'Ситне', 'Грибне', 'Пікантне'], 'ings': ["Гриби", "Трюфель", "Вершки"]},
    11: {'tastes': ['Пряне', 'Ситне', 'Пікантне'], 'ings': ["М'ясо", "Морепродукти", "Тісто", "Авокадо"]},
    12: {'tastes': ['Пряне', 'Ситне', 'Пікантне'], 'ings': ["Морепродукти"]},
    13: {'tastes': ['Пряне', 'Ситне', 'Пікантне'], 'ings': ["Сир"]},
    14: {'tastes': ['Пряне', 'Ситне', 'Грибне', 'Пікантне'], 'ings': ["Гриби", "Трюфель", "Шоколад"]},
    15: {'tastes': ['Пряне', 'Ситне', 'Пікантне'], 'ings': ["Вершки", "Ягоди"]},
    16: {'tastes': ['Вегетаріанське', 'Пряне', 'Ситне', 'Пікантне'], 'ings': ["М'ясо", "Яловичина", "Сир"]},
    17: {'tastes': ['Пряне', 'Ситне', 'Пікантне'], 'ings': []},
    18: {'tastes': ['Пряне', 'Холодне', 'Ситне', 'Пікантне'], 'ings': ["М'ясо", "Свинина"]},
    19: {'tastes': ['Пряне', 'Ситне', 'Пікантне'], 'ings': ["Сир"]},
    20: {'tastes': ['Пряне', 'Ситне', 'Пікантне'], 'ings': ["М'ясо", "Риба", "Лосось"]},

    // 21-40 (Піца)
    21: {'tastes': ['Гостре', 'Ситне', 'Хрустке', 'Пікантне'], 'ings': ["Сир", "Моцарела", "Томати", "Тісто", "Гострий перець"]},
    22: {'tastes': ['Ситне', 'Грибне', 'Хрустке', 'Пікантне'], 'ings': ["Сир", "Гриби", "Риба", "Тісто"]},
    23: {'tastes': ['Ситне', 'Хрустке', 'Пікантне'], 'ings': ["Курка", "Сир", "Тісто", "Ананас"]},
    24: {'tastes': ['Вегетаріанське', 'Ситне', 'Хрустке', 'Пікантне'], 'ings': ["Сир", "Цибуля", "Тісто", "Фета", "Гострий перець"]},
    25: {'tastes': ['Ситне', 'Хрустке', 'Пікантне'], 'ings': ["М'ясо", "Свинина", "Бекон", "Сир", "Тісто"]},
    26: {'tastes': ['Ситне', 'Хрустке', 'Пікантне'], 'ings': ["Сир", "Томати", "Тісто"]},
    27: {'tastes': ['Вегетаріанське', 'Ситне', 'Хрустке', 'Пікантне'], 'ings': ["Сир", "Моцарела", "Базилік", "Тісто"]},
    28: {'tastes': ['Ситне', 'Хрустке', 'Пікантне'], 'ings': ["Сир", "Томати", "Оливки", "Тісто", "Фета"]},
    29: {'tastes': ['Ситне', 'Хрустке', 'Пікантне'], 'ings': ["Сир", "Тісто"]},
    30: {'tastes': ['Ситне', 'Грибне', 'Хрустке', 'Пікантне'], 'ings': ["М'ясо", "Свинина", "Бекон", "Сир", "Гриби", "Вершки", "Риба", "Тісто"]},
    31: {'tastes': ['Гостре', 'Ситне', 'Хрустке', 'Пікантне'], 'ings': ["Сир", "Тісто", "Гострий перець"]},
    32: {'tastes': ['Ситне', 'Хрустке', 'Пікантне'], 'ings': ["Сир", "Оливки", "Тісто"]},
    33: {'tastes': ['Ситне', 'Хрустке', 'Пікантне'], 'ings': ["Сир", "Цибуля", "Оливки", "Риба", "Тісто"]},
    34: {'tastes': ['Ситне', 'Хрустке', 'Пікантне'], 'ings': ["Курка", "Сир", "Цибуля", "Тісто"]},
    35: {'tastes': ['Вегетаріанське', 'Ситне', 'Хрустке', 'Пікантне'], 'ings': ["Сир", "Вершки", "Тісто"]},
    36: {'tastes': ['Ситне', 'Хрустке', 'Пікантне'], 'ings': ["Сир", "Вершки", "Риба", "Лосось", "Тісто"]},
    37: {'tastes': ['Ситне', 'Грибне', 'Хрустке', 'Пікантне'], 'ings': ["Сир", "Гриби", "Томати", "Риба", "Тісто"]},
    38: {'tastes': ['Ситне', 'Грибне', 'Хрустке', 'Пікантне'], 'ings': ["Курка", "Сир", "Гриби", "Вершки", "Риба", "Тісто"]},
    39: {'tastes': ['Вегетаріанське', 'Ситне', 'Хрустке', 'Пікантне'], 'ings': ["Сир", "Тісто", "Фета"]},
    40: {'tastes': ['Ситне', 'Хрустке', 'Пікантне'], 'ings': ["М'ясо", "Свинина", "Бекон", "Сир", "Цибуля", "Тісто"]},

    // 41-60 (М'ясні страви)
    41: {'tastes': ['Гостре', 'Пряне', 'Ситне', 'Димне'], 'ings': ["М'ясо", "Яловичина"]},
    42: {'tastes': ['Пряне', 'Ситне', 'Димне'], 'ings': ["М'ясо", "Свинина"]},
    43: {'tastes': ['Гостре', 'Пряне', 'Ситне', 'Димне'], 'ings': ["М'ясо", "Курка"]},
    44: {'tastes': ['Пряне', 'Ситне', 'Димне'], 'ings': ["М'ясо", "Яловичина"]},
    45: {'tastes': ['Пряне', 'Ситне', 'Димне'], 'ings': ["М'ясо", "Свинина"]},
    46: {'tastes': ['Пряне', 'Ситне', 'Димне'], 'ings': ["М'ясо", "Курка", "Цибуля", "Вершки"]},
    47: {'tastes': ['Пряне', 'Ситне', 'Димне'], 'ings': ["М'ясо", "Часник"]},
    48: {'tastes': ['Пряне', 'Ситне', 'Димне'], 'ings': ["М'ясо", "Яловичина"]},
    49: {'tastes': ['Пряне', 'Ситне', 'Димне'], 'ings': ["М'ясо", "Курка"]},
    50: {'tastes': ['Пряне', 'Ситне', 'Димне'], 'ings': ["М'ясо", "Свинина", "Сир"]},
    51: {'tastes': ['Вегетаріанське', 'Пряне', 'Ситне', 'Димне', 'Грибне'], 'ings': ["М'ясо", "Яловичина", "Гриби", "Риба"]},
    52: {'tastes': ['Пряне', 'Ситне', 'Димне'], 'ings': ["М'ясо", "Курка", "Часник", "Вершки"]},
    53: {'tastes': ['Пряне', 'Ситне', 'Димне'], 'ings': ["М'ясо", "Мед"]},
    54: {'tastes': ['Пряне', 'Ситне', 'Димне'], 'ings': ["М'ясо", "Яловичина"]},
    55: {'tastes': ['Гостре', 'Пряне', 'Ситне', 'Димне'], 'ings': ["М'ясо", "Курка", "Гострий перець"]},
    56: {'tastes': ['Пряне', 'Ситне', 'Димне'], 'ings': ["М'ясо", "Яловичина"]},
    57: {'tastes': ['Пряне', 'Ситне', 'Димне'], 'ings': ["М'ясо", "Свинина"]},
    58: {'tastes': ['Пряне', 'Ситне', 'Димне'], 'ings': ["М'ясо", "Курка"]},
    59: {'tastes': ['Пряне', 'Ситне', 'Димне'], 'ings': ["М'ясо", "Яловичина"]},
    60: {'tastes': ['Пряне', 'Ситне', 'Димне'], 'ings': ["М'ясо"]},

    // 61-80 (Салати)
    61: {'tastes': ['Холодне', 'Легке', 'Дієтичне'], 'ings': ["Риба", "Картопля"]},
    62: {'tastes': ['Холодне', 'Легке', 'Дієтичне'], 'ings': ["Морепродукти"]},
    63: {'tastes': ['Вегетаріанське', 'Холодне', 'Легке', 'Дієтичне'], 'ings': ["Сир"]},
    64: {'tastes': ['Холодне', 'Легке', 'Дієтичне'], 'ings': ["Морепродукти"]},
    65: {'tastes': ['Холодне', 'Легке', 'Грибне', 'Дієтичне'], 'ings': ["Гриби", "Цибуля", "Риба"]},
    66: {'tastes': ['Холодне', 'Ситне', 'Легке', 'Дієтичне'], 'ings': ["М'ясо", "Яловичина"]},
    67: {'tastes': ['Холодне', 'Ситне', 'Легке', 'Дієтичне'], 'ings': ["Курка", "Сир", "Ананас"]},
    68: {'tastes': ['Холодне', 'Ситне', 'Легке', 'Дієтичне'], 'ings': ["М'ясо", "Свинина", "Бекон"]},
    69: {'tastes': ['Холодне', 'Легке', 'Дієтичне'], 'ings': ["Сир", "Моцарела", "Томати"]},
    70: {'tastes': ['Холодне', 'Легке', 'Дієтичне'], 'ings': ["Сир", "Пармезан"]},
    71: {'tastes': ['Холодне', 'Легке', 'Дієтичне'], 'ings': ["Риба"]},
    72: {'tastes': ['Холодне', 'Легке', 'Дієтичне'], 'ings': ["Сир", "Оливки", "Фета"]},
    73: {'tastes': ['Холодне', 'Легке', 'Дієтичне'], 'ings': ["Креветки", "Морепродукти", "Авокадо"]},
    74: {'tastes': ['Вегетаріанське', 'Холодне', 'Легке', 'Дієтичне'], 'ings': ["Сир", "Фета"]},
    75: {'tastes': ['Холодне', 'Легке', 'Дієтичне'], 'ings': ["Риба", "Лосось"]},
    76: {'tastes': ['Холодне', 'Легке', 'Дієтичне'], 'ings': ["Курка", "Ягоди", "Горіхи"]},
    77: {'tastes': ['Вегетаріанське', 'Холодне', 'Легке', 'Дієтичне'], 'ings': []},
    78: {'tastes': ['Холодне', 'Легке', 'Дієтичне'], 'ings': []},
    79: {'tastes': ['Холодне', 'Легке', 'Дієтичне'], 'ings': ["Сир", "Горіхи", "Фета"]},
    80: {'tastes': ['Холодне', 'Легке', 'Дієтичне'], 'ings': ["Морепродукти"]},

    // 81-90 (Супи)
    81: {'tastes': ['Вегетаріанське', 'Пряне', 'Ситне', 'Вершкове'], 'ings': ["Вершки"]},
    82: {'tastes': ['Пряне', 'Ситне', 'Вершкове'], 'ings': []},
    83: {'tastes': ['Пряне', 'Ситне', 'Вершкове'], 'ings': ["Курка"]},
    84: {'tastes': ['Вегетаріанське', 'Пряне', 'Ситне', 'Вершкове', 'Грибне'], 'ings': ["Гриби", "Риба", "Картопля"]},
    85: {'tastes': ['Вегетаріанське', 'Пряне', 'Ситне', 'Вершкове'], 'ings': ["Томати", "Базилік"]},
    86: {'tastes': ['Пряне', 'Ситне', 'Вершкове'], 'ings': ["Вершки", "Риба", "Лосось"]},
    87: {'tastes': ['Пряне', 'Ситне', 'Вершкове'], 'ings': ["Сир", "Пармезан"]},
    88: {'tastes': ['Пряне', 'Ситне', 'Вершкове'], 'ings': ["Курка"]},
    89: {'tastes': ['Пряне', 'Ситне', 'Вершкове'], 'ings': ["Вершки", "Горіхи"]},
    90: {'tastes': ['Вегетаріанське', 'Пряне', 'Ситне', 'Вершкове'], 'ings': ["Сир", "Вершки"]},

    // 91-100 (Бургери)
    91: {'tastes': ['Ситне', 'Димне', 'Хрустке'], 'ings': ["М'ясо", "Яловичина", "Томати", "Тісто"]},
    92: {'tastes': ['Ситне', 'Димне', 'Хрустке'], 'ings': ["М'ясо", "Курка", "Сир", "Тісто"]},
    93: {'tastes': ['Ситне', 'Димне', 'Хрустке'], 'ings': ["М'ясо", "Свинина", "Бекон", "Тісто"]},
    94: {'tastes': ['Ситне', 'Димне', 'Грибне', 'Хрустке'], 'ings': ["М'ясо", "Гриби", "Риба", "Тісто"]},
    95: {'tastes': ['Вегетаріанське', 'Ситне', 'Димне', 'Хрустке'], 'ings': ["М'ясо", "Сир", "Тісто"]},
    96: {'tastes': ['Ситне', 'Димне', 'Хрустке'], 'ings': ["М'ясо", "Риба", "Лосось", "Тісто"]},
    97: {'tastes': ['Ситне', 'Димне', 'Хрустке'], 'ings': ["М'ясо", "Тісто"]},
    98: {'tastes': ['Вегетаріанське', 'Ситне', 'Димне', 'Хрустке'], 'ings': ["М'ясо", "Тісто", "Авокадо"]},
    99: {'tastes': ['Ситне', 'Димне', 'Хрустке'], 'ings': ["М'ясо", "Свинина", "Бекон", "Тісто"]},
    100: {'tastes': ['Ситне', 'Димне', 'Хрустке'], 'ings': ["М'ясо", "Курка", "Тісто"]},

    // 101-110 (Паста)
    101: {'tastes': ['Ситне', 'Вершкове', 'Пікантне'], 'ings': ["Томати", "Тісто"]},
    102: {'tastes': ['Ситне', 'Вершкове', 'Пікантне'], 'ings': ["Сир", "Гриби", "Вершки", "Риба", "Тісто", "Фета"]},
    103: {'tastes': ['Гостре', 'Ситне', 'Вершкове', 'Пікантне'], 'ings': ["Томати", "Тісто", "Гострий перець"]},
    104: {'tastes': ['Ситне', 'Вершкове', 'Пікантне'], 'ings': ["Креветки", "Морепродукти", "Тісто"]},
    105: {'tastes': ['Ситне', 'Вершкове', 'Пікантне'], 'ings': ["М'ясо", "Свинина", "Бекон", "Тісто"]},
    106: {'tastes': ['Ситне', 'Вершкове', 'Пікантне'], 'ings': ["Вершки", "Риба", "Лосось", "Тісто"]},
    107: {'tastes': ['Ситне', 'Вершкове', 'Пікантне'], 'ings': ["Курка", "Базилік", "Тісто"]},
    108: {'tastes': ['Ситне', 'Вершкове', 'Грибне', 'Пікантне'], 'ings': ["Гриби", "Вершки", "Риба", "Тісто"]},
    109: {'tastes': ['Ситне', 'Вершкове', 'Пікантне'], 'ings': ["Томати", "Базилік", "Тісто"]},
    110: {'tastes': ['Ситне', 'Вершкове', 'Пікантне'], 'ings': ["Сир", "Моцарела", "Томати", "Тісто"]},

    // 111-120 (Десерти)
    111: {'tastes': ['Холодне', 'Солодке', 'Легке', 'Фруктове'], 'ings': ["Сир", "Вершки"]},
    112: {'tastes': ['Солодке', 'Легке', 'Фруктове'], 'ings': ["Сир", "Тісто"]},
    113: {'tastes': ['Солодке', 'Легке', 'Фруктове'], 'ings': ["Сир", "Вершки", "Тісто"]},
    114: {'tastes': ['Солодке', 'Легке', 'Фруктове'], 'ings': ["Сир"]},
    115: {'tastes': ['Солодке', 'Легке', 'Фруктове'], 'ings': ["Сир", "Ягоди"]},
    116: {'tastes': ['Солодке', 'Легке', 'Фруктове'], 'ings': ["Сир"]},
    117: {'tastes': ['Солодке', 'Легке', 'Фруктове'], 'ings': ["Сир"]},
    118: {'tastes': ['Солодке', 'Легке', 'Фруктове'], 'ings': ["Сир", "Ягоди"]},
    119: {'tastes': ['Солодке', 'Легке', 'Фруктове'], 'ings': ["Сир", "Шоколад"]},
    120: {'tastes': ['Солодке', 'Легке', 'Фруктове'], 'ings': ["Сир", "Мед"]},

    // 121-130 (Безалкогольні напої)
    121: {'tastes': ['Солодке', 'Легке', 'Фруктове'], 'ings': []},
    122: {'tastes': ['Солодке', 'Легке', 'Фруктове'], 'ings': []},
    123: {'tastes': ['Солодке', 'Легке', 'Фруктове'], 'ings': ["Сир"]}, // Той самий баг сайту з сиропом
    124: {'tastes': ['Солодке', 'Легке', 'Фруктове'], 'ings': ["Ягоди"]},
    125: {'tastes': ['Солодке', 'Легке', 'Фруктове'], 'ings': []},
    126: {'tastes': ['Солодке', 'Легке', 'Фруктове'], 'ings': []},
    127: {'tastes': ['Холодне', 'Солодке', 'Легке', 'Фруктове'], 'ings': []},
    128: {'tastes': ['Солодке', 'Легке', 'Фруктове'], 'ings': []},
    129: {'tastes': ['Солодке', 'Легке', 'Фруктове'], 'ings': []},
    130: {'tastes': ['Солодке', 'Легке', 'Фруктове'], 'ings': ["Вершки", "Шоколад"]},

    // 131-180 (Пиво, Вино, Алкоголь, Коктейлі)
    131: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': []},
    132: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': []},
    133: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': []},
    134: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': []},
    135: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': []},
    136: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': []},
    137: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': ["Ягоди"]},
    138: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': []},
    139: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': []},
    140: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': []},
    141: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': []},
    142: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': []},
    143: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': ["Ягоди"]},
    144: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': []},
    145: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': []},
    146: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': []},
    147: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': []},
    148: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': []},
    149: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': []},
    150: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': []},
    151: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': []},
    152: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': []},
    153: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': []},
    154: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': []},
    155: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': []},
    156: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': []},
    157: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': []},
    158: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': []},
    159: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': []},
    160: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': []},
    161: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': []},
    162: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': []},
    163: {'tastes': ['Гостре', 'Холодне', 'Легке', 'Пікантне'], 'ings': ["Томати"]},
    164: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': ["Ягоди"]},
    165: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': []},
    166: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': ["Сир", "Ягоди"]},
    167: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': ["Ананас"]},
    168: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': []},
    169: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': []},
    170: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': ["Вершки"]},
    171: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': []},
    172: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': []},
    173: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': []},
    174: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': []},
    175: {'tastes': ['Гостре', 'Холодне', 'Легке', 'Пікантне'], 'ings': ["Томати"]},
    176: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': ["Ягоди"]},
    177: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': ["Ягоди"]},
    178: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': ["Вершки"]},
    179: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': ["Оливки"]},
    180: {'tastes': ['Холодне', 'Легке', 'Пікантне'], 'ings': ["Ягоди"]},
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
        _showError('Помилка сервера. Спробуйте ще раз.');
      }
    } else {
      _showError('Будь ласка, увійдіть в акаунт.');
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
        _showError('Лобі не знайдено або помилка входу.');
      }
    } else {
      _showError('Будь ласка, увійдіть в акаунт.');
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
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: primaryGold),
        title: Text('Компроміс', style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
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
            Tab(icon: Icon(Icons.info_outline), text: 'Статус'),
            Tab(icon: Icon(Icons.restaurant_menu), text: 'Меню'),
            Tab(icon: Icon(Icons.shopping_cart), text: 'Кошик'),
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
                  Text('Потрібна авторизація', textAlign: TextAlign.center, style: TextStyle(color: primaryGold, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Для доступу до Спільного Лоббі, будь ласка, увійдіть в акаунт або зареєструйтесь.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14)),
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
                      child: const Text('УВІЙТИ / ЗАРЕЄСТРУВАТИСЬ', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
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
                  const Text('Спільне замовлення', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Об\'єднайте бюджети та обирайте страви разом із друзями!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 32),
                  SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _createLobby, style: ElevatedButton.styleFrom(backgroundColor: primaryGold, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: const Text('СТВОРИТИ НОВЕ ЛОБІ', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)))),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('АБО', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold))),
                  TextField(controller: _joinCodeController, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 5.0, fontWeight: FontWeight.bold), textCapitalization: TextCapitalization.characters, decoration: InputDecoration(hintText: 'КОД ЛОБІ', filled: true, fillColor: Colors.black.withOpacity(0.5), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
                  const SizedBox(height: 16),
                  SizedBox(width: double.infinity, height: 50, child: OutlinedButton(onPressed: _joinLobby, style: OutlinedButton.styleFrom(foregroundColor: primaryGold, side: BorderSide(color: primaryGold, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: const Text('ПРИЄДНАТИСЯ', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)))),
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
          const Text('Втрачено зв\'язок з лобі', style: TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() { _isLoading = true; });
              _loadInitialData().then((_) => setState(() { _isLoading = false; }));
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryGold, foregroundColor: Colors.black),
            child: const Text('ОНОВИТИ'),
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
              child: Text('Код лобі: $_currentLobbyCode', style: TextStyle(color: primaryGold, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
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
                    const Text('Загальний бюджет', style: TextStyle(color: Colors.white54, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('$totalBudget ₴', style: TextStyle(color: primaryGold, fontSize: 28, fontWeight: FontWeight.bold)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showBudgetDialog,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white12, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Мій внесок'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text('Компанія (${members.length})', style: TextStyle(color: primaryGold, fontSize: 18, fontWeight: FontWeight.bold)),
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
                      Text(m['fullName'] ?? m['name'] ?? 'Гість', style: const TextStyle(color: Colors.white, fontSize: 16))
                    ]),
                    Text('${m['budget']} ₴', style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
                  ],
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 24),

          Text('Налаштування: Я НЕ їм', style: TextStyle(color: primaryGold, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildGlassCard(
            child: Column(
              children: [
                if (disliked.isNotEmpty) ...[
                  const Align(alignment: Alignment.centerLeft, child: Text('Група не їсть:', style: TextStyle(color: Colors.redAccent, fontSize: 14))),
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

                const Align(alignment: Alignment.centerLeft, child: Text('Ваші вподобання:', style: TextStyle(color: Colors.white54, fontSize: 14))),
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
                        const SnackBar(content: Text('Вподобання оновлено! Небажані страви приховано з меню.'), backgroundColor: Colors.green),
                      );
                      _tabController.animateTo(1);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: primaryGold, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    child: const Text('ОНОВИТИ МЕНЮ', style: TextStyle(fontWeight: FontWeight.bold)),
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
    // 1. Отримуємо назви інгредієнтів, які ти відмітив галочками
    Set<String> dislikedNames = _selectedDisliked.map((id) => _allIngredients[id]!.toLowerCase()).toSet();

    // 2. Додаємо сюди ж те, що не їсть група (якщо такі дані прийшли з сервера)
    List groupDisliked = _lobbyData?['dislikedIngredients'] ?? _lobbyData?['DislikedIngredients'] ?? [];
    for (var d in groupDisliked) {
      String dName = _extractName(d);
      if (dName.isNotEmpty) dislikedNames.add(dName.toLowerCase());
    }

    // 3. Фільтруємо страви перед виведенням на екран
    List<dynamic> filteredMenu = _menuItems.where((item) {
      // Пошук по введеному тексту
      String name = (item['name'] ?? item['Name'] ?? '').toLowerCase();
      if (_searchQuery.isNotEmpty && !name.contains(_searchQuery.toLowerCase())) {
        return false;
      }

      // Беремо ID страви та шукаємо її склад у нашому новому локальному словнику
      int dishId = int.tryParse(item['id']?.toString() ?? item['Id']?.toString() ?? '0') ?? 0;
      var localTags = _dishTags[dishId];

      if (localTags != null) {
        List<String> dishIngs = localTags['ings'] ?? [];
        for (String ing in dishIngs) {
          // Якщо страва містить інгредієнт, який ми не їмо — ховаємо її
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
                hintText: 'Пошук страви...',
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
                Text('За запитом нічого не знайдено', style: const TextStyle(color: Colors.white54)),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: filteredMenu.length,
            itemBuilder: (context, index) {
              var item = filteredMenu[index];
              String name = item['name'] ?? item['Name'] ?? 'Страва';
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

                            // Генеруємо теги з локального словника!
                            Wrap(
                              spacing: 6, runSpacing: 6,
                              children: _buildTagsForDish(dishId),
                            ),

                            const SizedBox(height: 12),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${item['price']} ₴', style: TextStyle(color: primaryGold, fontSize: 16, fontWeight: FontWeight.bold)),
                                ElevatedButton(
                                  onPressed: () async {
                                    bool success = await ApiService.addToLobbyCart(_currentLobbyCode!, dishId);
                                    if (success) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name додано!'), backgroundColor: Colors.green, duration: const Duration(seconds: 1)));
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
                                  child: Text('В кошик', style: TextStyle(color: primaryGold, fontSize: 12, fontWeight: FontWeight.bold)),
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

  // Функція яка витягує теги з нашого локального масиву
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
      tags.add(_buildTasteTag('Фірмове'));
    }

    return tags;
  }

  Widget _buildTasteTag(String tasteName) {
    IconData icon = Icons.local_dining;
    Color color = Colors.white70;

    switch (tasteName.toLowerCase()) {
      case 'гостре': icon = Icons.local_fire_department; color = Colors.redAccent; break;
      case 'вегетаріанське': icon = Icons.eco; color = Colors.green; break;
      case 'пряне': icon = Icons.whatshot; color = Colors.deepOrangeAccent; break;
      case 'холоднe': case 'холодне': icon = Icons.ac_unit; color = Colors.lightBlueAccent; break;
      case 'солодкe': case 'солодке': icon = Icons.icecream; color = Colors.pinkAccent; break;
      case 'кисле': icon = Icons.sentiment_dissatisfied; color = Colors.limeAccent; break;
      case 'ситне': icon = Icons.lunch_dining; color = Colors.orangeAccent; break;
      case 'легке': icon = Icons.spa; color = Colors.lightGreenAccent; break;
      case 'димне': icon = Icons.cloud; color = Colors.grey; break;
      case 'вершкове': icon = Icons.water_drop; color = Colors.yellow[200]!; break;
      case 'фруктове': icon = Icons.apple; color = Colors.red; break;
      case 'грибне': icon = Icons.park; color = Colors.brown[300]!; break;
      case 'дієтичне': icon = Icons.fitness_center; color = Colors.tealAccent; break;
      case 'хрустке': icon = Icons.bolt; color = Colors.yellowAccent; break;
      case 'пікантне': icon = Icons.star; color = Colors.amber; break;
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
                      const Text('Залишок грошей:', style: TextStyle(color: Colors.white54, fontSize: 16)),
                      Text('$remaining ₴', style: TextStyle(
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
                      child: Text('Спільний кошик порожній', style: TextStyle(color: Colors.white54, fontSize: 16))
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
                            Text('${(double.tryParse(c['price']?.toString() ?? '0') ?? 0) * c['quantity']} ₴', style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold, fontSize: 16)),
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
                    const Text('СУМА ЛОБІ:', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    Text('$currentCartTotal ₴', style: TextStyle(color: primaryGold, fontSize: 28, fontWeight: FontWeight.bold)),
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
                        remaining >= 0 ? 'ПЕРЕЙТИ ДО БРОНЮВАННЯ' : 'НЕ ВИСТАЧАЄ БЮДЖЕТУ',
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
          title: Text('Ваш бюджет', style: TextStyle(color: primaryGold)),
          content: TextField(
            controller: budgetController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(hintText: 'Введіть суму', hintStyle: const TextStyle(color: Colors.white38), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryGold)), focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryGold))),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('СКАСУВАТИ', style: TextStyle(color: Colors.grey))),
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
              child: const Text('ЗБЕРЕГТИ'),
            ),
          ],
        );
      },
    );
  }
}