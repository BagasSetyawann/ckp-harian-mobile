import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/input_kegiatan_screen.dart';
import 'screens/riwayat_kegiatan_screen.dart';
import 'screens/rk_nilai_screen.dart';
import 'screens/profil_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init();
  runApp(const SiCkpMobileApp());
}

class SiCkpMobileApp extends StatefulWidget {
  const SiCkpMobileApp({super.key});

  @override
  State<SiCkpMobileApp> createState() => _SiCkpMobileAppState();
}

class _SiCkpMobileAppState extends State<SiCkpMobileApp> {
  bool _loggedIn = ApiService.token != null && ApiService.currentUser != null;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SI-CKP Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0284C7),
          primary: const Color(0xFF0284C7),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1E293B),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: _loggedIn
          ? MainShell(
              onLogout: () => setState(() => _loggedIn = false),
            )
          : LoginScreen(
              onLoginSuccess: () => setState(() => _loggedIn = true),
            ),
    );
  }
}

class MainShell extends StatefulWidget {
  final VoidCallback onLogout;
  const MainShell({super.key, required this.onLogout});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<String> _titles = [
    'SI-CKP Mobile',
    'Input CKP Harian',
    'Riwayat Kegiatan',
    'Nilai CKP & Laporan',
    'Profil Pegawai',
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        onTapInputCKP: () => setState(() => _currentIndex = 1),
        onTapRiwayat: () => setState(() => _currentIndex = 2),
      ),
      InputKegiatanScreen(
        onSuccess: () => setState(() => _currentIndex = 2),
      ),
      const RiwayatKegiatanScreen(),
      const RkNilaiScreen(),
      ProfilScreen(onLogout: widget.onLogout),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.phone_android_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(_titles[_currentIndex]),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE0F2FE),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF0284C7)),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle_rounded, color: Color(0xFF0284C7)),
            label: 'Input CKP',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded, color: Color(0xFF0284C7)),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.workspace_premium_outlined),
            selectedIcon: Icon(Icons.workspace_premium_rounded, color: Color(0xFF0284C7)),
            label: 'Nilai CKP',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF0284C7)),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

