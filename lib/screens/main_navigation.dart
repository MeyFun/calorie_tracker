import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/food_scan_result.dart';
import '../services/food_recognition_service.dart';
import '../widgets/health_glass.dart';
import 'food_scan_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final _homeScreenKey = GlobalKey<HomeScreenState>();

  void _openScannedFood(FoodScanResult result) async {
    setState(() => _currentIndex = 0);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    _homeScreenKey.currentState?.showAddFoodWithScan(result);
  }

  @override
  Widget build(BuildContext context) {
    return HealthBackground(
      child: ValueListenableBuilder(
        valueListenable: Hive.box('settingsBox').listenable(
          keys: [FoodRecognitionService.apiKeyStorageKey],
        ),
        builder: (context, settingsBox, child) {
          final hasGeminiApiKey =
              (settingsBox.get(FoodRecognitionService.apiKeyStorageKey)
                      as String? ??
                  '')
              .trim()
              .isNotEmpty;
          final visibleIndex = _currentIndex == 1 && !hasGeminiApiKey
              ? 2
              : _currentIndex;

          return Scaffold(
            backgroundColor: Colors.transparent,
            body: IndexedStack(
              index: visibleIndex,
              children: [
                HomeScreen(key: _homeScreenKey),
                FoodScanScreen(onResult: _openScannedFood),
                const ProfileScreen(),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              height: 76,
              selectedIndex: visibleIndex,
              onDestinationSelected: (index) {
                if (index == 1 && !hasGeminiApiKey) {
                  setState(() => _currentIndex = 2);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Сначала добавьте API-ключ Gemini в профиле.',
                      ),
                    ),
                  );
                  return;
                }
                setState(() => _currentIndex = index);
              },
              backgroundColor: const Color(0xFFF9FCF9),
              indicatorColor: const Color(0xFFDDF3E4),
              elevation: 0,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.restaurant_menu_rounded),
                  selectedIcon: Icon(Icons.restaurant_menu_rounded),
                  label: 'Дневник',
                ),
                NavigationDestination(
                  icon: Icon(Icons.camera_alt_outlined),
                  selectedIcon: Icon(Icons.camera_alt_rounded),
                  label: 'ИИ фото',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Профиль',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
