import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';
import 'widgets/ui_components.dart';
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
          title: 'KASI JADI',
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
        toolbarHeight: 62,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 34,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? p.surfaceElevated : p.bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: p.border, width: 1),
              ),
              child: const KjLogoMark(width: 28, height: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(
                    TextSpan(
                      text: 'KASI ',
                      style: TextStyle(
                        fontFamily: AppTheme.sansFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: p.textPrimary,
                        letterSpacing: -0.3,
                      ),
                      children: [
                        TextSpan(
                          text: 'JADI',
                          style: TextStyle(
                            color: isDark ? p.info : const Color(0xFF0052FF),
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _titles[_selectedIndex],
                    style: TextStyle(
                      fontFamily: AppTheme.sansFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: p.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              onTap: _openChangelog,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: p.surfaceMuted,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: p.border, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: p.shadow, offset: const Offset(1.5, 2)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 13,
                      color: p.orange,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'v1.4',
                      style: AppTheme.mono(
                        size: 11,
                        weight: FontWeight.w700,
                        color: isDark ? p.info : p.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: isDark ? 'Mode Terang' : 'Mode Gelap',
            onPressed: ThemeController.toggle,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: p.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: p.border, width: 1.5),
              ),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                size: 17,
                color: isDark ? const Color(0xFFFBBF24) : p.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: p.border),
        ),
      ),
      body: body,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: p.surface,
          border: Border(top: BorderSide(color: p.border, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
          destinations: [
            NavigationDestination(
              icon: KjOutlineIcon(
                type: KjIconType.dashboard,
                color: p.textMuted,
              ),
              selectedIcon: KjOutlineIcon(
                type: KjIconType.dashboard,
                color: isDark ? Colors.white : p.primary,
                strokeWidth: 2.0,
              ),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: KjOutlineIcon(
                type: KjIconType.dailyLog,
                color: p.textMuted,
              ),
              selectedIcon: KjOutlineIcon(
                type: KjIconType.dailyLog,
                color: isDark ? Colors.white : p.primary,
                strokeWidth: 2.0,
              ),
              label: 'Input',
            ),
            NavigationDestination(
              icon: KjOutlineIcon(
                type: KjIconType.calendar,
                color: p.textMuted,
              ),
              selectedIcon: KjOutlineIcon(
                type: KjIconType.calendar,
                color: isDark ? Colors.white : p.primary,
                strokeWidth: 2.0,
              ),
              label: 'Riwayat',
            ),
            NavigationDestination(
              icon: KjOutlineIcon(
                type: KjIconType.analytics,
                color: p.textMuted,
              ),
              selectedIcon: KjOutlineIcon(
                type: KjIconType.analytics,
                color: isDark ? Colors.white : p.primary,
                strokeWidth: 2.0,
              ),
              label: 'Nilai',
            ),
            NavigationDestination(
              icon: KjOutlineIcon(
                type: KjIconType.profile,
                color: p.textMuted,
              ),
              selectedIcon: KjOutlineIcon(
                type: KjIconType.profile,
                color: isDark ? Colors.white : p.primary,
                strokeWidth: 2.0,
              ),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
