import 'dart:ui';
import 'package:flutter/material.dart';
import 'api_service.dart';

class ProfileTab extends StatefulWidget {
  final VoidCallback onLogout;

  const ProfileTab({Key? key, required this.onLogout}) : super(key: key);

  @override
  _ProfileTabState createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final Color primaryGold = const Color(0xFFFFD700);
  final Color surfaceDark = const Color(0xFF1A1A1A);

  bool _isLoadingData = true;
  bool _isSaving = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  List<dynamic> _favorites = [];
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    String? userId = await ApiService.getUserId();

    if (userId != null) {
      final userData = await ApiService.getUserProfile(userId);
      final favs = await ApiService.getFavorites(userId);
      final history = await ApiService.getOrderHistory(userId);

      if (mounted) {
        setState(() {
          if (userData != null) {
            _emailController.text = userData['email'] ?? userData['Email'] ?? '';
            _nameController.text = userData['name'] ?? userData['FullName'] ?? '';
            _phoneController.text = userData['phone'] ?? userData['PhoneNumber'] ?? '';

            String rawDob = userData['dob'] ?? userData['Dob'] ?? '';
            if (rawDob.length >= 10) {
              try {
                final dobDate = DateTime.parse(rawDob.substring(0, 10));
                _dobController.text = '${dobDate.month.toString().padLeft(2, '0')}/${dobDate.day.toString().padLeft(2, '0')}/${dobDate.year}';
              } catch (e) {
                _dobController.text = rawDob.substring(0, 10);
              }
            } else {
              _dobController.text = rawDob;
            }
          }

          _favorites = favs;
          _orders = history;
          _isLoadingData = false;
        });
      }
    } else {
      if (mounted) setState(() { _isLoadingData = false; });
    }
  }

  Future<void> _handleSave() async {
    setState(() { _isSaving = true; });

    String? userId = await ApiService.getUserId();

    if (userId != null) {
      String finalDobForBackend = _dobController.text.trim();
      // Конвертуємо назад для бекенду (з MM/DD/YYYY у YYYY-MM-DD)
      try {
        var parts = finalDobForBackend.split('/');
        if (parts.length == 3) {
          finalDobForBackend = '${parts[2]}-${parts[0]}-${parts[1]}';
        }
      } catch (e) {}

      bool success = await ApiService.updateUserProfile(userId, {
        'FullName': _nameController.text.trim(),
        'PhoneNumber': _phoneController.text.trim(),
        'Dob': finalDobForBackend, // Відправляємо перероблений формат
      });

      setState(() { _isSaving = false; });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Changes saved successfully!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save changes.'), backgroundColor: Colors.redAccent),
        );
      }
    } else {
      setState(() { _isSaving = false; });
    }
  }

  void _handleLogout() async {
    await ApiService.logout();
    widget.onLogout();
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return '${date.month.toString().padLeft(2,'0')}/${date.day.toString().padLeft(2,'0')}/${date.year} ${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')}';
    } catch(e) {
      return isoDate;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
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

        if (_isLoadingData)
          Center(child: CircularProgressIndicator(color: primaryGold))
        else
          SafeArea(
            child: RefreshIndicator(
              color: primaryGold,
              backgroundColor: surfaceDark,
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0, bottom: 100.0),
                child: Column(
                  children: [
                    _buildGlassCard(
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Icon(Icons.account_circle, color: primaryGold, size: 80),
                              Container(
                                width: 18, height: 18,
                                margin: const EdgeInsets.only(bottom: 6, right: 6),
                                decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 2)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text('Your Profile', style: TextStyle(color: primaryGold, fontSize: 24, fontWeight: FontWeight.bold)),
                          const Text('Personal details and settings', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 8),
                          const Text('Pull down to refresh data ⬇', style: TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic)),
                          const SizedBox(height: 30),

                          _buildReadOnlyField(label: 'EMAIL', controller: _emailController),
                          const SizedBox(height: 20),
                          _buildEditableField(label: 'FULL NAME', controller: _nameController, icon: Icons.person_outline),
                          const SizedBox(height: 20),
                          _buildEditableField(label: 'PHONE NUMBER', controller: _phoneController, icon: Icons.phone_outlined),
                          const SizedBox(height: 20),
                          _buildEditableField(label: 'DATE OF BIRTH', controller: _dobController, icon: Icons.calendar_today_outlined),
                          const SizedBox(height: 30),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _handleSave,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGold,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                              child: _isSaving
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                                  : const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SECTION: FAVORITES
                    _buildGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: primaryGold.withOpacity(0.1), shape: BoxShape.circle),
                                child: Icon(Icons.favorite, color: primaryGold, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Text('Favorites', style: TextStyle(color: primaryGold, fontSize: 22, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (_favorites.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Column(
                                  children: [
                                    Icon(Icons.heart_broken, color: Colors.white24, size: 64),
                                    SizedBox(height: 16),
                                    Text('You haven\'t added any dishes yet', style: TextStyle(color: Colors.white70, fontSize: 16)),
                                  ],
                                ),
                              ),
                            )
                          else
                            Column(
                              children: _favorites.map((fav) => _buildFavoriteItem(fav)).toList(),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: primaryGold.withOpacity(0.1), shape: BoxShape.circle),
                                child: Icon(Icons.shopping_bag, color: primaryGold, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Text('Order History', style: TextStyle(color: primaryGold, fontSize: 22, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (_orders.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Column(
                                  children: [
                                    Icon(Icons.receipt_long, color: Colors.white24, size: 64),
                                    SizedBox(height: 16),
                                    Text('You haven\'t placed any orders yet', style: TextStyle(color: Colors.white70, fontSize: 16)),
                                  ],
                                ),
                              ),
                            )
                          else
                            Column(
                              children: _orders.map((order) => _buildOrderItem(order)).toList(),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _handleLogout,
                        icon: const Icon(Icons.logout, color: Colors.redAccent),
                        label: const Text('LOG OUT', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFavoriteItem(Map<String, dynamic> fav) {
    String dishName = fav['dishName'] ?? fav['DishName'] ?? 'Dish';
    String price = fav['price']?.toString() ?? fav['Price']?.toString() ?? '0';
    String imageUrl = fav['imageUrl'] ?? fav['ImageUrl'] ?? '';

    if (imageUrl.startsWith('/')) {
      imageUrl = '${ApiService.baseUrl}$imageUrl';
    } else if (imageUrl.isEmpty) {
      imageUrl = 'https://via.placeholder.com/60.png?text=No+Image';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              width: 60, height: 60, fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(width: 60, height: 60, color: Colors.grey[800], child: const Icon(Icons.fastfood, color: Colors.white54)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dishName, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('\$$price', style: TextStyle(color: primaryGold, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Icon(Icons.favorite, color: Colors.redAccent, size: 24),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> order) {
    String date = _formatDate(order['createdAt'] ?? order['CreatedAt'] ?? '');
    String total = order['totalPrice']?.toString() ?? order['TotalPrice']?.toString() ?? '0';
    String count = order['itemsCount']?.toString() ?? order['ItemsCount']?.toString() ?? '0';
    String orderId = order['id']?.toString() ?? order['Id']?.toString() ?? '#';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order #$orderId', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(date, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 2),
              Text('Items in receipt: $count', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          Text('\$$total', style: TextStyle(color: primaryGold, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: surfaceDark.withOpacity(0.75),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: primaryGold.withOpacity(0.3)),
            boxShadow: [BoxShadow(color: primaryGold.withOpacity(0.05), blurRadius: 20, spreadRadius: 1)],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({required String label, required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: primaryGold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: true,
          style: const TextStyle(color: Colors.white54, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableField({required String label, required TextEditingController controller, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: primaryGold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white54, size: 20),
            filled: true,
            fillColor: Colors.black.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: primaryGold)),
          ),
        ),
      ],
    );
  }
}