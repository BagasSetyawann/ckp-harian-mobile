import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_components.dart';
import 'changelog_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;
  bool _showDemo = false;
  String? _errorMsg;

  static const _demoPegawai = [
    {'username': 'budi', 'nama': 'Budi Santoso', 'jabatan': 'Statistisi Muda'},
    {'username': 'sari', 'nama': 'Sari Dewi L.', 'jabatan': 'Analis Kebijakan'},
    {'username': 'reza', 'nama': 'Reza Firmansyah', 'jabatan': 'Pranata Komputer'},
    {'username': 'dewi', 'nama': 'Dewi Rahayu', 'jabatan': 'Statistisi Pertama'},
  ];

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit([String? demoUser]) async {
    if (demoUser != null) {
      _usernameCtrl.text = demoUser;
      _passwordCtrl.text = 'password123';
    } else if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      await ApiService.login(_usernameCtrl.text.trim(), _passwordCtrl.text);
      if (mounted) widget.onLoginSuccess();
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMsg = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMsg = 'Tidak dapat terhubung ke server API. Periksa koneksi atau konfigurasi URL.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showServerDialog() async {
    final ctrl = TextEditingController(text: ApiService.baseUrl);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final p = AppTheme.of(ctx);
        return AlertDialog(
          title: const Text('Konfigurasi Server API', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Masukkan URL endpoint backend KASI JADI.',
                style: TextStyle(fontSize: 12.5, color: p.textMuted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                style: AppTheme.mono(size: 12.5, color: p.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Base URL API',
                  hintText: 'https://ckp-harian-backend.vercel.app/api',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
          ],
        );
      },
    );

    if (saved == true && ctrl.text.trim().isNotEmpty) {
      await ApiService.setBaseUrl(ctrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server API diperbarui: ${ApiService.baseUrl}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    final isDark = ThemeController.isDark(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Minimalist top utility bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ChangelogScreen()),
                    ),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: p.border, width: 1.5),
                        boxShadow: [
                          BoxShadow(color: p.shadow, offset: const Offset(1.5, 2)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 14, color: p.orange),
                          const SizedBox(width: 6),
                          Text(
                            'Changelog',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: p.textPrimary),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'v1.4',
                            style: AppTheme.mono(size: 11, weight: FontWeight.w700, color: isDark ? p.info : p.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    tooltip: isDark ? 'Mode Terang' : 'Mode Gelap',
                    onPressed: ThemeController.toggle,
                    style: IconButton.styleFrom(
                      side: BorderSide(color: p.border, width: 1.5),
                      backgroundColor: p.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(36, 36),
                      padding: EdgeInsets.zero,
                    ),
                    icon: Icon(
                      isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      size: 17,
                      color: isDark ? const Color(0xFFFBBF24) : p.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    tooltip: 'Pengaturan Server API',
                    onPressed: _showServerDialog,
                    style: IconButton.styleFrom(
                      side: BorderSide(color: p.border, width: 1.5),
                      backgroundColor: p.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(36, 36),
                      padding: EdgeInsets.zero,
                    ),
                    icon: Icon(Icons.dns_rounded, size: 17, color: p.textPrimary),
                  ),
                ],
              ),
            ),

            // Centered Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Brand header
                        Row(
                          children: [
                            Container(
                              width: 54,
                              height: 48,
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: p.border, width: 2),
                                boxShadow: [
                                  BoxShadow(color: p.shadow, offset: const Offset(2.5, 3.5)),
                                ],
                              ),
                              child: const KjLogoMark(width: 40, height: 34),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'JURNAL AKTIVITAS & KINERJA',
                                    style: AppTheme.mono(
                                      size: 10,
                                      weight: FontWeight.w700,
                                      color: isDark ? p.info : p.primary,
                                      letterSpacing: 0.9,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text.rich(
                                    TextSpan(
                                      text: 'KASI ',
                                      style: TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.w800,
                                        color: p.textPrimary,
                                        letterSpacing: -0.6,
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
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: p.tealBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: p.border, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.bolt_rounded, size: 16, color: p.orange),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Kasi Jadi Hari Ini, Sat-Set No Drama!',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: p.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const KjTenunStrip(height: 10, opacity: 0.24),
                        const SizedBox(height: 16),

                        // Login Card
                        HairlineCard(
                          padding: const EdgeInsets.all(20),
                          radius: 16,
                          shadowOffset: const Offset(4, 5),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_errorMsg != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: p.dangerBg,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: p.danger.withValues(alpha: 0.35)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.error_outline_rounded, size: 18, color: p.danger),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _errorMsg!,
                                            style: TextStyle(fontSize: 12.5, color: p.danger, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                Text(
                                  'Username',
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: p.textSecondary),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _usernameCtrl,
                                  textInputAction: TextInputAction.next,
                                  autocorrect: false,
                                  decoration: const InputDecoration(
                                    hintText: 'Masukkan username pegawai',
                                    prefixIcon: Icon(Icons.person_outline_rounded, size: 19),
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Username wajib diisi' : null,
                                ),
                                const SizedBox(height: 14),

                                Text(
                                  'Password',
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: p.textSecondary),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _passwordCtrl,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration: InputDecoration(
                                    hintText: 'Masukkan password',
                                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 19),
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                        size: 19,
                                      ),
                                    ),
                                  ),
                                  validator: (v) => (v == null || v.isEmpty) ? 'Password wajib diisi' : null,
                                ),
                                const SizedBox(height: 18),

                                KjNeoButton(
                                  label: 'GAS MASUK!',
                                  icon: Icons.arrow_forward_rounded,
                                  variant: KjButtonVariant.orange,
                                  isLoading: _loading,
                                  expand: true,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  onPressed: _loading ? null : () => _submit(),
                                ),

                                // Collapsible Demo Accounts
                                const SizedBox(height: 18),
                                Divider(height: 1, color: p.border),
                                const SizedBox(height: 12),
                                InkWell(
                                  onTap: () => setState(() => _showDemo = !_showDemo),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Akses Akun Demo (Uji Coba)',
                                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: p.textMuted),
                                        ),
                                        Icon(
                                          _showDemo ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                          size: 20,
                                          color: p.textMuted,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                if (_showDemo) ...[
                                  const SizedBox(height: 10),
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                      childAspectRatio: 2.2,
                                    ),
                                    itemCount: _demoPegawai.length,
                                    itemBuilder: (_, idx) {
                                      final item = _demoPegawai[idx];
                                      return InkWell(
                                        onTap: _loading ? null : () => _submit(item['username']),
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: p.surfaceMuted,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: p.border),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                item['nama']!,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: p.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '@${item['username']}',
                                                style: AppTheme.mono(size: 11, color: p.primary),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Password default: password123',
                                    textAlign: TextAlign.center,
                                    style: AppTheme.mono(size: 11, color: p.textMuted),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        Text(
                          '© 2026 KASI JADI · Kanal Sistem Jurnal Aktivitas Dan Kinerja',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11.5, color: p.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
