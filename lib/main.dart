import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/input_kegiatan_screen.dart';
import 'screens/riwayat_kegiatan_screen.dart';
import 'screens/rk_nilai_screen.dart';
import 'screens/profil_screen.dart';
import 'screens/changelog_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.init();
  await ApiService.init();
  runApp(const SiCkpMobileApp());
}

class SiCkpMobileApp extends StatefulWidget {
  const SiCkpMobileApp({super.key});

  @override
  State<SiCkpMobileApp> createState() => _SiCkpMobileAppState();
}

class _SiCkpMobileAppState extends State<SiCkpMobileApp> {
  late bool _loggedIn;

  @override
  void initState() {
    super.initState();
    _loggedIn = ApiService.token != null && ApiService.currentUser != null;
  }

  Future<void> _handleLogout() async {
    await ApiService.logout();
    if (mounted) {
      setState(() => _loggedIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'SI-CKP Mobile',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: _loggedIn
              ? MainShell(onLogout: _handleLogout)
              : LoginScreen(
                  onLoginSuccess: () => setState(() => _loggedIn = true),
                ),
        );
      },
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
  int _selectedIndex = 0;

  static const _titles = [
    'Beranda',
    'Input CKP',
    'Riwayat Kegiatan',
    'Nilai CKP',
    'Profil',
  ];

  void _openChangelog() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChangelogScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    final isDark = ThemeController.isDark(context);

    Widget body;
    switch (_selectedIndex) {
      case 0:
        body = HomeScreen(
          onTapInputCKP: () => setState(() => _selectedIndex = 1),
          onTapRiwayat: () => setState(() => _selectedIndex = 2),
        );
        break;
      case 1:
        body = InputKegiatanScreen(
          onSuccess: () => setState(() => _selectedIndex = 2),
        );
        break;
      case 2:
        body = const RiwayatKegiatanScreen();
        break;
      case 3:
        body = const RkNilaiScreen();
        break;
      case 4:
        body = ProfilScreen(onLogout: widget.onLogout);
        break;
      default:
        body = HomeScreen(
          onTapInputCKP: () => setState(() => _selectedIndex = 1),
          onTapRiwayat: () => setState(() => _selectedIndex = 2),
        );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: p.primaryDeep,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: p.heroBorder),
              ),
              child: const Icon(Icons.fact_check_rounded, size: 17, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SI-CKP',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  _titles[_selectedIndex],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: p.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: InkWell(
              onTap: _openChangelog,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: p.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: p.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_outlined, size: 13, color: p.primary),
                    const SizedBox(width: 5),
                    Text(
                      'v1.3',
                      style: AppTheme.mono(size: 11, weight: FontWeight.w600, color: p.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: isDark ? 'Mode Terang' : 'Mode Gelap',
            onPressed: ThemeController.toggle,
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 20,
              color: p.textSecondary,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: body,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: p.border, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard_rounded),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.add_circle_outline_rounded),
              selectedIcon: Icon(Icons.add_circle_rounded),
              label: 'Input',
            ),
            NavigationDestination(
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt_rounded),
              label: 'Riwayat',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics_rounded),
              label: 'Nilai',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
