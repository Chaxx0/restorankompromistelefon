import 'dart:ui';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'cart_manager.dart';
import 'cart_tab.dart';

class MenuTab extends StatefulWidget {
  @override
  _MenuTabState createState() => _MenuTabState();
}

class _MenuTabState extends State<MenuTab> {
  final Color primaryGold = const Color(0xFFFFD700);
  final Color surfaceDark = const Color(0xFF1A1A1A);

  Future<List<Map<String, dynamic>>>? _menuItemsFuture;

  List<Map<String, dynamic>> _allItems = [];
  List<int> _favoriteIds = [];
  String _selectedCategory = 'УСЕ';
  List<String> _categories = ['УСЕ'];

  @override
  void initState() {
    super.initState();
    _menuItemsFuture = _loadMenuAndFavorites();
  }

  Future<List<Map<String, dynamic>>> _loadMenuAndFavorites() async {
    var rawItems = await ApiService.fetchMenu();
    List<Map<String, dynamic>> typedItems = List<Map<String, dynamic>>.from(rawItems);
    _allItems = typedItems;

    String? userId = await ApiService.getUserId();
    if (userId != null) {
      _favoriteIds = await ApiService.getFavoriteIds(userId);
    }

    Set<String> uniqueCategories = {};
    for (var item in typedItems) {
      String cat = item['category']?.toString() ?? item['Category']?.toString() ?? 'УСЕ';
      uniqueCategories.add(cat);
    }

    if (mounted) {
      setState(() {
        _categories = ['УСЕ', ...uniqueCategories.toList()];
      });
    }

    return typedItems;
  }

  void _toggleFavorite(int dishId) async {
    if (dishId == 0) return;

    String? userId = await ApiService.getUserId();

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Увійдіть в акаунт, щоб додавати в улюблене!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    bool? isNowFavorite = await ApiService.toggleFavorite(userId, dishId);

    if (isNowFavorite != null) {
      setState(() {
        if (isNowFavorite) {
          _favoriteIds.add(dishId);
        } else {
          _favoriteIds.remove(dishId);
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Помилка сервера. Спробуйте пізніше.'), backgroundColor: Colors.redAccent),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredItems {
    if (_selectedCategory == 'УСЕ') {
      return _allItems;
    }
    return _allItems.where((item) {
      String cat = item['category']?.toString() ?? item['Category']?.toString() ?? '';
      return cat == _selectedCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
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
      ),

      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 20, left: 20, right: 20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'МЕНЮ',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: primaryGold, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2.0),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => CartTab(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                            transitionDuration: const Duration(milliseconds: 300),
                          ),
                        );
                      },
                      child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                        valueListenable: CartManager.cartItems,
                        builder: (context, items, child) {
                          return Badge(
                            isLabelVisible: items.isNotEmpty,
                            label: Text(
                                items.fold(0, (sum, item) => sum + ((item['quantity'] ?? 1) as int)).toString(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                            ),
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                                border: Border.all(color: primaryGold.withOpacity(0.3)),
                              ),
                              child: Icon(Icons.shopping_cart_outlined, color: primaryGold, size: 24),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(
              height: 40,
              child: FutureBuilder(
                  future: _menuItemsFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData && _categories.length <= 1) return const SizedBox();
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        String categoryName = _categories[index];
                        return _buildCategoryChip(categoryName, categoryName == _selectedCategory);
                      },
                    );
                  }
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _menuItemsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: primaryGold));
                  }
                  else if (snapshot.hasError) {
                    return const Center(child: Text('Помилка завантаження меню', style: TextStyle(color: Colors.white70)));
                  }
                  else if (snapshot.hasData) {
                    final itemsToDisplay = _filteredItems;

                    if (itemsToDisplay.isEmpty) {
                      return const Center(child: Text('У цій категорії поки що порожньо', style: TextStyle(color: Colors.white54)));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      physics: const BouncingScrollPhysics(),
                      itemCount: itemsToDisplay.length,
                      itemBuilder: (context, index) {
                        return _buildMenuItemCard(itemsToDisplay[index]);
                      },
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String title, bool isActive) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = title;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? primaryGold : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isActive ? primaryGold : Colors.white38),
        ),
        child: Center(
          child: Text(
            title.toUpperCase(),
            style: TextStyle(color: isActive ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItemCard(Map<String, dynamic> item) {
    int dishId = int.tryParse(item['id']?.toString() ?? item['Id']?.toString() ?? '0') ?? 0;
    String name = item['name']?.toString() ?? item['Name']?.toString() ?? 'Назва страви';
    String desc = item['description']?.toString() ?? item['Description']?.toString() ?? '';
    String price = item['price']?.toString() ?? item['Price']?.toString() ?? '0';
    String imageUrl = item['imageUrl']?.toString() ?? item['ImageUrl']?.toString() ?? '';

    bool isFavorite = _favoriteIds.contains(dishId);

    if (imageUrl.startsWith('/')) {
      imageUrl = '${ApiService.baseUrl}$imageUrl';
    } else if (imageUrl.isEmpty) {
      imageUrl = 'https://via.placeholder.com/400x200.png?text=No+Image';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => _toggleFavorite(dishId),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            key: ValueKey<bool>(isFavorite),
                            color: isFavorite ? Colors.redAccent : primaryGold,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(desc, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.4)),
                    const SizedBox(height: 20),
                    Text('$price ₴', style: TextStyle(color: primaryGold, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () {
                          CartManager.addItem(item);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$name додано в кошик!'), backgroundColor: Colors.green, duration: const Duration(seconds: 1)),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryGold,
                          side: BorderSide(color: primaryGold, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text('ДОДАТИ В КОШИК', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
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
    {'role': 'ai', 'text': 'Привіт! Я ваш цифровий сомельє та помічник по меню. Що вам порадити сьогодні?'}
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
                        const Text('ШІ-Офіціант', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
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
                    child: Text('ШІ-Офіціант друкує...', style: TextStyle(color: primaryGold, fontSize: 13, fontStyle: FontStyle.italic)),
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
                          hintText: 'Запитайте про меню...',
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