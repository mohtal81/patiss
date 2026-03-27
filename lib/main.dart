// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'database/db_helper.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/stock_screen.dart';
import 'screens/achats_screen.dart';
import 'screens/produits_screen.dart';
import 'screens/commandes_screen.dart';
import 'screens/params_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await DbHelper().database; // init DB
  await AuthService().init();
  runApp(const PatisserieApp());
}

class PatisserieApp extends StatelessWidget {
  const PatisserieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pâtisserie Orientale',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const _Entrypoint(),
    );
  }
}

class _Entrypoint extends StatefulWidget {
  const _Entrypoint();

  @override
  State<_Entrypoint> createState() => _EntrypointState();
}

class _EntrypointState extends State<_Entrypoint> {
  bool _authDone = false;

  @override
  void initState() {
    super.initState();
    _checkAuthDone();
  }

  Future<void> _checkAuthDone() async {
    final prefs   = await SharedPreferences.getInstance();
    final skipped = prefs.getBool('auth_skipped') ?? false;
    final hasUser = AuthService().isSignedIn;
    if (skipped || hasUser) {
      if (mounted) setState(() => _authDone = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_authDone) {
      return LoginScreen(onDone: () => setState(() => _authDone = true));
    }
    return const MainShell();
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _screens = const [
    DashboardScreen(),
    StockScreen(),
    AchatsScreen(),
    ProduitsScreen(),
    CommandesScreen(),
    ParamsScreen(),
  ];

  final _navItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_rounded),
      label: 'Tableau'),
    BottomNavigationBarItem(
      icon: Icon(Icons.inventory_2_rounded),
      label: 'Stock'),
    BottomNavigationBarItem(
      icon: Icon(Icons.shopping_cart_rounded),
      label: 'Achats'),
    BottomNavigationBarItem(
      icon: Icon(Icons.cake_rounded),
      label: 'Produits'),
    BottomNavigationBarItem(
      icon: Icon(Icons.receipt_long_rounded),
      label: 'Commandes'),
    BottomNavigationBarItem(
      icon: Icon(Icons.settings_rounded),
      label: 'Params'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(
        index: _index,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: _navItems,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          iconSize: 22,
        ),
      ),
    );
  }
}
