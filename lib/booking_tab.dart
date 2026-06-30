import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
import 'cart_manager.dart';
import 'login_tab.dart';
import 'payment_screen.dart';

class RestTable {
  final int id; final int num; final double x; final double y; final int seats; final bool isVip;
  final String zone; final String imageUrl;
  RestTable(this.id, this.num, this.x, this.y, this.seats, this.isVip, this.zone, this.imageUrl);
}

class BookingTab extends StatefulWidget {
  final bool isFromCart;
  final bool isFromLobby;
  final List<dynamic>? lobbyCart;
  final double? lobbyTotal;
  final String? lobbyCode;

  const BookingTab({
    Key? key,
    this.isFromCart = false,
    this.isFromLobby = false,
    this.lobbyCart,
    this.lobbyTotal,
    this.lobbyCode,
  }) : super(key: key);

  @override
  _BookingTabState createState() => _BookingTabState();
}

class _BookingTabState extends State<BookingTab> {
  final Color primaryGold = const Color(0xFFFFD700);
  final Color surfaceDark = const Color(0xFF1A1A1A);

  bool _isCheckingAuth = true;
  bool _isLoggedIn = false;

  bool _isSubmitting = false;
  DateTime _selectedDate = DateTime.now();
  String _selectedTimeRange = "19:00-21:00";
  int? _selectedTableId;
  final TextEditingController _wishesController = TextEditingController();

  Timer? _pollingTimer;

  Map<int, List<String>> _dailySchedules = {};

  final List<String> availableTimes = ["10:00", "11:00", "12:00", "13:00", "14:00", "15:00", "16:00", "17:00", "18:00", "19:00", "20:00", "21:00", "22:00", "23:00"];

  final List<RestTable> tables = [
    RestTable(1, 1, 12, 18, 6, true, 'Внутрішній зал', '/images/table1.jpg'),
    RestTable(2, 2, 28, 18, 6, true, 'Внутрішній зал', '/images/table2.jpg'),
    RestTable(3, 3, 10, 35, 4, false, 'Внутрішній зал', '/images/table3.jpg'),
    RestTable(4, 4, 22, 35, 4, false, 'Внутрішній зал', '/images/table4.jpg'),
    RestTable(5, 5, 34, 35, 2, false, 'Внутрішній зал', '/images/table5.jpg'),
    RestTable(6, 6, 46, 35, 4, false, 'Внутрішній зал', '/images/table6.jpg'),
    RestTable(7, 7, 10, 50, 4, false, 'Внутрішній зал', '/images/table7.jpg'),
    RestTable(8, 8, 22, 50, 4, false, 'Внутрішній зал', '/images/table8.jpg'),
    RestTable(9, 9, 34, 50, 2, false, 'Внутрішній зал', '/images/table9.jpg'),
    RestTable(10, 10, 46, 50, 4, false, 'Внутрішній зал', '/images/table10.jpg'),
    RestTable(11, 11, 15, 68, 6, false, 'Внутрішній зал', '/images/table11.jpg'),
    RestTable(12, 12, 30, 68, 4, false, 'Внутрішній зал', '/images/table12.jpg'),
    RestTable(13, 13, 42, 68, 2, false, 'Внутрішній зал', '/images/table13.jpg'),
    RestTable(14, 14, 52, 15, 2, false, 'Внутрішній зал', '/images/table14.jpg'),
    RestTable(15, 15, 52, 25, 2, false, 'Внутрішній зал', '/images/table15.jpg'),
    RestTable(16, 16, 52, 60, 2, false, 'Внутрішній зал', '/images/table16.jpg'),
    RestTable(17, 17, 75, 15, 4, false, 'Тераса', '/images/table17.jpg'),
    RestTable(18, 18, 90, 15, 4, false, 'Тераса', '/images/table18.jpg'),
    RestTable(19, 19, 75, 35, 2, false, 'Тераса', '/images/table19.jpg'),
    RestTable(20, 20, 90, 35, 4, false, 'Тераса', '/images/table20.jpg'),
    RestTable(21, 21, 82, 55, 6, false, 'Тераса', '/images/table21.jpg'),
    RestTable(22, 22, 75, 75, 4, false, 'Тераса', '/images/table22.jpg'),
    RestTable(23, 23, 90, 75, 4, false, 'Тераса', '/images/table23.jpg'),
    RestTable(24, 24, 82, 90, 2, false, 'Тераса', '/images/table24.jpg'),
    RestTable(25, 25, 15, 85, 4, false, 'Вулиця', '/images/table25.jpg'),
    RestTable(26, 26, 28, 85, 4, false, 'Вулиця', '/images/table26.jpg'),
    RestTable(27, 27, 41, 85, 4, false, 'Вулиця', '/images/table27.jpg'),
    RestTable(28, 28, 15, 96, 6, false, 'Вулиця', '/images/table28.jpg'),
    RestTable(29, 29, 30, 96, 2, false, 'Вулиця', '/images/table29.jpg'),
    RestTable(30, 30, 45, 96, 2, false, 'Вулиця', '/images/table30.jpg'),
  ];

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _fetchOccupiedTables();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _wishesController.dispose();
    super.dispose();
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

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchOccupiedTables();
    });
  }

  Future<void> _fetchOccupiedTables() async {
    String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    var schedules = await ApiService.getDailySchedule(formattedDate);

    if (mounted) {
      setState(() {
        _dailySchedules = schedules;

        // 🔥 МАГІЯ ДЛЯ ПРЕЗЕНТАЦІЇ: Примусово робимо 10-й столик зайнятим
        if (_dailySchedules.containsKey(10)) {
          if (!_dailySchedules[10]!.contains("19:00-21:00")) {
            _dailySchedules[10]!.add("19:00-21:00");
          }
        } else {
          _dailySchedules[10] = ["19:00-21:00"];
        }
      });
    }
  }

  void _showTableModal(RestTable table) {
    String tempStartTime = _selectedTimeRange.split('-')[0];
    String tempEndTime = _selectedTimeRange.split('-').length > 1 ? _selectedTimeRange.split('-')[1] : "21:00";
    List<String> busySlots = _dailySchedules[table.id] ?? [];

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (context, setStateModal) {
                return Dialog(
                  backgroundColor: surfaceDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: primaryGold, width: 1.5)),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(18.5)),
                              child: Image.network('${ApiService.baseUrl}${table.imageUrl}', height: 180, width: double.infinity, fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(height: 180, color: Colors.grey[900], child: const Icon(Icons.restaurant, size: 50, color: Colors.white24)),
                              ),
                            ),
                            Positioned(top: 10, right: 10, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 28), onPressed: () => Navigator.pop(context))),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(table.isVip ? 'VIP Стіл №${table.num}' : 'Стіл №${table.num}', style: TextStyle(color: primaryGold, fontSize: 24, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text('Зона: ${table.zone}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                              Text('Макс. кількість гостей: ${table.seats}', style: TextStyle(color: primaryGold, fontSize: 14, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),

                              Container(
                                width: double.infinity, padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(10), border: Border(left: BorderSide(color: primaryGold, width: 4))),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Зайняті години:', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    if (busySlots.isEmpty)
                                      Row(children: const [Icon(Icons.check_circle, color: Colors.greenAccent, size: 16), SizedBox(width: 8), Text('Стіл повністю вільний сьогодні!', style: TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold))])
                                    else
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: busySlots.map((slot) => Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.2), border: Border.all(color: Colors.redAccent), borderRadius: BorderRadius.circular(8)),
                                          child: Text(slot, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        )).toList(),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text('Оберіть час візиту', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const Divider(color: Colors.white24),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Початок', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                        const SizedBox(height: 4),
                                        _buildTimeDropdown(tempStartTime, (val) => setStateModal(() => tempStartTime = val!)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Завершення', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                        const SizedBox(height: 4),
                                        _buildTimeDropdown(tempEndTime, (val) => setStateModal(() => tempEndTime = val!)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity, height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: primaryGold, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  onPressed: () {
                                    if (tempStartTime.compareTo(tempEndTime) >= 0) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Час завершення має бути пізніше часу початку!'), backgroundColor: Colors.redAccent));
                                      return;
                                    }
                                    bool hasOverlap = false;
                                    for (String slot in busySlots) {
                                      var parts = slot.split('-');
                                      if (parts.length == 2) {
                                        if (tempStartTime.compareTo(parts[1]) < 0 && tempEndTime.compareTo(parts[0]) > 0) {
                                          hasOverlap = true;
                                          break;
                                        }
                                      }
                                    }

                                    if (hasOverlap) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ой! Цей час перетинається із зайнятими годинами. Оберіть інший.'), backgroundColor: Colors.redAccent));
                                      return;
                                    }

                                    setState(() {
                                      _selectedTableId = table.id;
                                      _selectedTimeRange = '$tempStartTime-$tempEndTime';
                                    });
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Стіл №${table.num} обрано!'), backgroundColor: Colors.green));
                                  },
                                  child: const Text('ПІДТВЕРДИТИ', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
          );
        }
    );
  }

  Widget _buildTimeDropdown(String value, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.black, border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: Colors.black, value: value, isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          items: availableTimes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Future<void> _submitBooking() async {
    if (_selectedTableId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Будь ласка, оберіть столик на карті!'), backgroundColor: Colors.redAccent));
      return;
    }

    setState(() { _isSubmitting = true; });
    String? userId = await ApiService.getUserId();

    final selectedTable = tables.firstWhere((t) => t.id == _selectedTableId);

    List<Map<String, dynamic>> itemsPayload = [];
    double finalTotal = 0.0;

    List<dynamic> fullMenu = [];
    try {
      fullMenu = await ApiService.fetchMenu();
    } catch (e) {}

    if (widget.isFromCart) {
      finalTotal = CartManager.getTotalPrice();
      for (var item in CartManager.cartItems.value) {
        itemsPayload.add({
          'DishId': int.tryParse(item['id']?.toString() ?? '0') ?? 0,
          'Name': item['name'] ?? 'Страва',
          'Quantity': item['quantity'] ?? 1,
          'Price': double.tryParse(item['price']?.toString() ?? '0') ?? 0.0
        });
      }
    }
    else if (widget.isFromLobby && widget.lobbyCart != null) {
      finalTotal = widget.lobbyTotal ?? 0.0;
      for (var item in widget.lobbyCart!) {
        String name = item['name'] ?? item['Name'] ?? 'Страва';
        int dishId = int.tryParse(item['id']?.toString() ?? item['dishId']?.toString() ?? item['DishId']?.toString() ?? '0') ?? 0;

        if (dishId == 0 && fullMenu.isNotEmpty) {
          var foundDish = fullMenu.firstWhere((m) => (m['name'] ?? m['Name']) == name, orElse: () => null);
          if (foundDish != null) {
            dishId = int.tryParse(foundDish['id']?.toString() ?? '0') ?? 0;
          }
        }

        itemsPayload.add({
          'DishId': dishId,
          'Name': name,
          'Quantity': item['quantity'] ?? item['Quantity'] ?? 1,
          'Price': double.tryParse(item['price']?.toString() ?? item['Price']?.toString() ?? '0') ?? 0.0
        });
      }
    }

    String finalWishes = _wishesController.text.trim();
    if (widget.isFromLobby) {
      finalWishes = "[Замовлення з Лоббі ${widget.lobbyCode}]\n" + finalWishes;
    }

    Map<String, dynamic> bookingData = {
      'UserId': userId,
      'Date': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'Time': _selectedTimeRange,
      'Guests': selectedTable.seats,
      'TableId': _selectedTableId,
      'Wishes': finalWishes,
      'TotalPrice': finalTotal,
      'Items': itemsPayload
    };

    bool bookingSuccess = await ApiService.createBooking(bookingData);

    if (bookingSuccess) {
      if (widget.isFromCart) CartManager.clearCart();
      if (mounted) {
        setState(() { _isSubmitting = false; });

        // Використовуємо push замість pushReplacement, щоб відкрити оплату ПОВЕРХ бронювання
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(amount: finalTotal),
          ),
        ).then((_) {
          // Цей блок виконається, коли вікно оплати закриється (успішно або по кнопці "назад")
          if (widget.isFromCart || widget.isFromLobby) {
            // Якщо ми прийшли з кошика чи лоббі, закриваємо і цей екран теж
            Navigator.pop(context);
          } else {
            // Якщо ми просто бронювали на головній вкладці — скидаємо вибір столика
            setState(() {
              _selectedTableId = null;
              _wishesController.clear();
              _fetchOccupiedTables(); // Оновлюємо розклад після нашого бронювання
            });
          }
        });
      }
    } else {
      if (mounted) {
        setState(() { _isSubmitting = false; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Помилка. Перевірте з'єднання."), backgroundColor: Colors.redAccent));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: primaryGold)));
    }

    if (!_isLoggedIn) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: IconThemeData(color: primaryGold),
          title: Text('Бронювання', style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: _buildGuestScreen(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  if (widget.isFromCart || widget.isFromLobby)
                    IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), onPressed: () => Navigator.pop(context)),
                  Text(
                      widget.isFromLobby ? 'ОФОРМЛЕННЯ ЛОБІ' : (widget.isFromCart ? 'ОФОРМЛЕННЯ' : 'БРОНЮВАННЯ'),
                      style: TextStyle(color: primaryGold, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2.0)
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        DateTime? picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)),
                          builder: (context, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: ColorScheme.dark(primary: primaryGold)), child: child!),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                          });
                          _fetchOccupiedTables();
                        }
                      },
                      child: Container(
                        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(color: surfaceDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: primaryGold.withOpacity(0.3))),
                        child: Column(
                          children: [
                            Text('ДАТА ВІЗИТУ', style: TextStyle(color: primaryGold, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(DateFormat('dd.MM.yyyy').format(_selectedDate), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text('СХЕМА РЕСТОРАНУ', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    const Text('Натисніть на стіл для вибору. Червоний контур — стіл частково або повністю зайнятий.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 16),
                    Container(
                      height: 450, width: double.infinity,
                      decoration: BoxDecoration(color: const Color(0xFF0F0F0F), borderRadius: BorderRadius.circular(20), border: Border.all(color: primaryGold)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              children: [
                                Positioned(top: 0, left: 0, width: constraints.maxWidth * 0.65, height: constraints.maxHeight * 0.75, child: Container(decoration: BoxDecoration(border: const Border(right: BorderSide(color: Colors.white10, width: 2), bottom: BorderSide(color: Colors.white10, width: 2)), color: primaryGold.withOpacity(0.02)))),
                                Positioned(top: 20, left: 20, child: Text('СЦЕНА', style: TextStyle(color: primaryGold.withOpacity(0.5), fontWeight: FontWeight.bold))),
                                Positioned(bottom: 100, right: 120, child: Text('ЗАЛ', style: TextStyle(color: primaryGold.withOpacity(0.15), fontSize: 30, fontWeight: FontWeight.bold))),
                                ...tables.map((t) {
                                  bool isSelected = _selectedTableId == t.id;

                                  bool isOccupied = _dailySchedules.containsKey(t.id) && _dailySchedules[t.id]!.isNotEmpty;

                                  return Positioned(
                                    left: (constraints.maxWidth * t.x / 100) - (t.isVip ? 35 : 20),
                                    top: (constraints.maxHeight * t.y / 100) - 20,
                                    child: GestureDetector(
                                      onTap: () => _showTableModal(t),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            width: t.isVip ? 70 : 40, height: 40,
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? primaryGold
                                                  : (t.isVip ? Colors.brown[900] : Colors.grey[900]),
                                              borderRadius: BorderRadius.circular(t.isVip ? 10 : 20),
                                              border: Border.all(
                                                  color: isSelected
                                                      ? Colors.white
                                                      : (isOccupied ? Colors.redAccent : (t.isVip ? primaryGold : Colors.grey[700]!)),
                                                  width: isSelected || isOccupied ? 2 : 1
                                              ),
                                              boxShadow: isSelected ? [BoxShadow(color: primaryGold.withOpacity(0.8), blurRadius: 15)] : [],
                                            ),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                    t.isVip ? 'VIP ${t.num}' : '№${t.num}',
                                                    style: TextStyle(
                                                        color: isSelected ? Colors.black : Colors.white,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold
                                                    )
                                                ),
                                                Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.chair, size: 10, color: isSelected ? Colors.black : primaryGold),
                                                      Text(
                                                          '${t.seats}',
                                                          style: TextStyle(
                                                              color: isSelected ? Colors.black : primaryGold,
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.bold
                                                          )
                                                      )
                                                    ]
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isOccupied && !isSelected)
                                            Positioned(
                                              top: -2, right: -2,
                                              child: Container(
                                                width: 12, height: 12,
                                                decoration: BoxDecoration(
                                                  color: Colors.redAccent,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.black, width: 2),
                                                  boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.8), blurRadius: 4)],
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    TextField(
                      controller: _wishesController, style: const TextStyle(color: Colors.white), maxLines: 2,
                      decoration: InputDecoration(hintText: 'Побажання (необов\'язково)', hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: surfaceDark, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity, height: 60,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitBooking,
                        style: ElevatedButton.styleFrom(backgroundColor: primaryGold, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.black)
                            : Text(
                            (widget.isFromCart || widget.isFromLobby) ? 'ПІДТВЕРДИТИ ЗАМОВЛЕННЯ' : 'ЗАБРОНЮВАТИ СТІЛ',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0)
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
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
                  const Text('Для доступу до бронювання столів, будь ласка, увійдіть в акаунт або зареєструйтесь.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14)),
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
}