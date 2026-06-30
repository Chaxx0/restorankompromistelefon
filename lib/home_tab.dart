import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

import 'lobby_tab.dart';
import 'reviews_tab.dart';

class HomeTab extends StatefulWidget {
  final Function(int) onTabChange;

  const HomeTab({Key? key, required this.onTabChange}) : super(key: key);

  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final Color primaryGold = const Color(0xFFFFD700);
  final Color surfaceDark = const Color(0xFF1A1A1A);

  final PageController _heroPageController = PageController();
  int _currentHeroIndex = 0;
  Timer? _heroTimer;

  final List<String> _heroImages = [
    'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=2000',
    'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?q=80&w=2000',
    'https://images.unsplash.com/photo-1517433367423-c7e5b0f35086?q=80&w=2000',
    'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?q=80&w=2000',
    'https://images.unsplash.com/photo-1504674900247-0877df9cc836?q=80&w=2000',
  ];

  @override
  void initState() {
    super.initState();
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentHeroIndex < _heroImages.length - 1) {
        _currentHeroIndex++;
      } else {
        _currentHeroIndex = 0;
      }
      if (_heroPageController.hasClients) {
        _heroPageController.animateToPage(
          _currentHeroIndex,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _heroPageController.dispose();
    super.dispose();
  }

  void _showOfferDetails(BuildContext context, String title, String price, String details) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                color: surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryGold, width: 1.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Colors.grey, size: 24),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(title, textAlign: TextAlign.center, style: TextStyle(color: primaryGold, fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  Text(price, textAlign: TextAlign.center, style: TextStyle(color: primaryGold, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  Text(details, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFDDDDDD), fontSize: 15, height: 1.6)),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onTabChange(2);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 0,
                      ),
                      child: const Text('Перейти до Бронювання', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildHeroSection(context),
          const SizedBox(height: 40),
          _buildOffersSection(context),
          const SizedBox(height: 40),
          _buildEventsSection(context),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return SizedBox(
      height: 600,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PageView.builder(
            controller: _heroPageController,
            itemCount: _heroImages.length,
            onPageChanged: (index) {
              setState(() { _currentHeroIndex = index; });
            },
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  image: DecorationImage(image: NetworkImage(_heroImages[index]), fit: BoxFit.cover),
                ),
              );
            },
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.95)],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'КОМПРОМІС',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: primaryGold,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      shadows: [Shadow(color: primaryGold.withOpacity(0.4), blurRadius: 20)],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Місце, де преміальний смак зустрічається з ідеальною атмосферою. Авторське меню, відбірні стейки та унікальні події.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 40),

                  // Кнопка: МЕНЮ
                  ElevatedButton(
                    onPressed: () => widget.onTabChange(1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      alignment: Alignment.center,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('ПЕРЕЙТИ ДО МЕНЮ', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 16),

                  // Кнопка: ЛОБІ
                  OutlinedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LobbyTab())),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryGold,
                      side: BorderSide(color: primaryGold, width: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      alignment: Alignment.center,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('СТВОРИТИ ЛОБІ', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 16),

                  // Кнопка: ВІДГУКИ (НОВА)
                  TextButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ReviewsTab())),
                    icon: Icon(Icons.star, color: primaryGold),
                    label: const Text('ВІДГУКИ ГОСТЕЙ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.0)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOffersSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('ЕКСКЛЮЗИВНІ ПРОПОЗИЦІЇ', textAlign: TextAlign.center, style: TextStyle(color: primaryGold, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          const SizedBox(height: 24),
          _buildOfferCard(
              context, 'Стейк-Вечір для Двох', 'Томагавк з трюфельним маслом (800г) + 2 гарніри та вино.', '1 650 ₴',
              "Величезний Томагавк з трюфельним маслом (800г)\nДва келихи преміального червоного вина\nОвочі гриль на гарнір\n\nІдеальний компроміс для справжніх м'ясоїдів.",
              imageUrl: 'https://images.unsplash.com/photo-1594041680534-e8c8cdebd659?q=80&w=1000'
          ),
          const SizedBox(height: 20),
          _buildOfferCard(
              context, 'Італійський Компроміс', 'Будь-які 3 піци на вибір + Літр лимонаду.', '990 ₴',
              "Будь-які 3 піци з нашого меню (включаючи авторські: з качкою, чорним трюфелем або крабом)\n+ 1 Літр фірмового лимонаду\n\nВибір великої компанії!",
              imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?q=80&w=1000'
          ),
          const SizedBox(height: 20),
          _buildOfferCard(
              context, 'Щасливі Години', 'З 14:00 до 17:00 знижка -15% на десерти.', 'Щодня',
              "З 14:00 до 17:00 знижка -15% на всі десерти та каву.\n\nАкція діє у внутрішньому залі та на терасі.",
              priceInModal: "Щодня", imageUrl: 'https://images.unsplash.com/photo-1551024601-bec78aea704b?q=80&w=1000'
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(BuildContext context, String title, String desc, String price, String fullDetails, {required String imageUrl, String? priceInModal}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: surfaceDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: primaryGold.withOpacity(0.3), width: 1.0)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(child: Image.network(imageUrl, fit: BoxFit.cover)),
            Positioned.fill(child: Container(color: Colors.black.withOpacity(0.85))),
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    Text(desc, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 14, height: 1.4)),
                    const SizedBox(height: 20),
                    Text(price, textAlign: TextAlign.center, style: TextStyle(color: primaryGold, fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    OutlinedButton(
                      onPressed: () => _showOfferDetails(context, title, priceInModal ?? price, fullDetails),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryGold, side: BorderSide(color: primaryGold, width: 1.5),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text('ДЕТАЛЬНІШЕ', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('АФІША РЕСТОРАНУ', textAlign: TextAlign.center, style: TextStyle(color: primaryGold, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 24),
        SizedBox(
          height: 450,
          child: PageView(
            controller: PageController(viewportFraction: 0.92),
            children: [
              _buildEventCard(context, '28 Лютого', 'Гурман-вечір:\nСезон Трюфелів', 'https://images.unsplash.com/photo-1550966871-3ed3cdb5ed0c?q=80&w=800'),
              _buildEventCard(context, '06 Березня', 'Вечір Живої Музики\nна Терасі', 'https://images.unsplash.com/photo-1516873240891-4bf014598ab4?q=80&w=800'),
              _buildEventCard(context, '14 Березня', 'Винна Дегустація:\nІталія', 'https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?q=80&w=800'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(BuildContext context, String date, String title, String imageUrl) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.65), BlendMode.darken)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(color: primaryGold, borderRadius: BorderRadius.circular(30)),
                child: Text(date, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 16)),
              ),
              const SizedBox(height: 20),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, height: 1.2)),
              const SizedBox(height: 30),
              OutlinedButton(
                onPressed: () => widget.onTabChange(2),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryGold, side: BorderSide(color: primaryGold, width: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('БРОНЬ СТОЛИКА', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}