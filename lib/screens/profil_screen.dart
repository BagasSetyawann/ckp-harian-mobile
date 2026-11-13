import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_components.dart';
import 'changelog_screen.dart';

class ProfilScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const ProfilScreen({super.key, required this.onLogout});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  Future<void> _showChangePasswordDialog() async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool submitting = false;
    String? errText;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final p = AppTheme.of(ctx);
          return AlertDialog(
            title: const Text('Ubah Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (errText != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: p.dangerBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: p.danger.withValues(alpha: 0.3)),
                      ),
                      child: Text(errText!, style: TextStyle(fontSize: 12, color: p.danger)),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: oldCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password Lama'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password Baru (min. 6 karakter)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Konfirmasi Password Baru'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: submitting ? null : () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: submitting
                    ? null
                    : () async {
                        if (oldCtrl.text.isEmpty || newCtrl.text.length < 6) {
                          setDialogState(() => errText = 'Password baru minimal 6 karakter.');
                          return;
                        }
                        if (newCtrl.text != confirmCtrl.text) {
                          setDialogState(() => errText = 'Konfirmasi password tidak cocok.');
                          return;
                        }
                        setDialogState(() {
                          submitting = true;
                          errText = null;
                        });
                        try {
                          await ApiService.changePassword(oldCtrl.text, newCtrl.text);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password berhasil diperbarui.')),
                            );
                          }
                        } on ApiException catch (e) {
                          setDialogState(() {
                            submitting = false;
                            errText = e.message;
                          });
                        } catch (_) {
                          setDialogState(() {
                            submitting = false;
                            errText = 'Gagal menghubungi server.';
                          });
                        }
                      },
                child: Text(submitting ? 'Menyimpan...' : 'Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar Aplikasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.of(ctx).danger),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (yes == true) {
      widget.onLogout();
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.of(context);
    final user = ApiService.currentUser ?? {};
    final nama = (user['nama'] ?? 'Pegawai').toString();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        // Identity Card
        HairlineCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: p.primaryDeep,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.heroBorder),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials(nama),
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: p.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (user['jabatan'] ?? 'Pegawai').toString(),
                      style: TextStyle(fontSize: 12.5, color: p.textMuted),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        StatusDotBadge(
                          label: (user['role'] ?? 'Anggota').toString(),
                          color: p.primary,
                          bgColor: p.primaryContainer,
                          showDot: false,
                        ),
                        if (user['golongan'] != null) ...[
                          const SizedBox(width: 6),
                          MonoPill(text: 'Gol. ${user['golongan']}'),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Metadata table card
        HairlineCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            children: [
              _infoRow(p, 'NIP', (user['nip'] ?? '-').toString(), mono: true),
              Divider(height: 1, color: p.border),
              _infoRow(p, 'Username', '@${user['username'] ?? '-'}', mono: true),
              Divider(height: 1, color: p.border),
              _infoRow(p, 'Unit Kerja', (user['unit_kerja'] ?? '-').toString()),
              Divider(height: 1, color: p.border),
              _infoRow(p, 'Email', (user['email'] ?? '-').toString()),
              Divider(height: 1, color: p.border),
              _infoRow(p, 'Server API', ApiService.baseUrl, mono: true),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Preferences & Actions
        HairlineCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ValueListenableBuilder<ThemeMode>(
                valueListenable: ThemeController.mode,
                builder: (ctx, mode, _) {
                  final darkOn = mode == ThemeMode.dark;
                  return SwitchListTile(
                    value: darkOn,
                    onChanged: (v) => ThemeController.setMode(v ? ThemeMode.dark : ThemeMode.light),
                    secondary: Icon(
                      darkOn ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                      size: 20,
                      color: p.primary,
                    ),
                    title: Text('Mode Gelap', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.textPrimary)),
                    subtitle: Text(
                      darkOn ? 'Tampilan gelap aktif' : 'Tampilan terang bersih aktif',
                      style: TextStyle(fontSize: 12, color: p.textMuted),
                    ),
                  );
                },
              ),
              Divider(height: 1, color: p.border),
              ListTile(
                leading: Icon(Icons.auto_awesome_outlined, size: 20, color: p.primary),
                title: Text('Riwayat Pembaruan (Changelog)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.textPrimary)),
                subtitle: Text('Catatan rilis fitur SI-CKP v1.3.0', style: TextStyle(fontSize: 12, color: p.textMuted)),
                trailing: Icon(Icons.chevron_right_rounded, color: p.textMuted),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ChangelogScreen()),
                ),
              ),
              Divider(height: 1, color: p.border),
              ListTile(
                leading: Icon(Icons.lock_reset_rounded, size: 20, color: p.primary),
                title: Text('Ubah Password', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.textPrimary)),
                subtitle: Text('Perbarui kata sandi akun Anda', style: TextStyle(fontSize: 12, color: p.textMuted)),
                trailing: Icon(Icons.chevron_right_rounded, color: p.textMuted),
                onTap: _showChangePasswordDialog,
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        OutlinedButton.icon(
          onPressed: _confirmLogout,
          icon: Icon(Icons.logout_rounded, size: 18, color: p.danger),
          label: Text('Keluar Aplikasi', style: TextStyle(color: p.danger, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: p.danger.withValues(alpha: 0.4)),
            backgroundColor: p.dangerBg,
            minimumSize: const Size.fromHeight(46),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(AppPalette p, String label, String value, {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: TextStyle(fontSize: 12.5, color: p.textMuted, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: mono
                  ? AppTheme.mono(size: 12, color: p.textPrimary, weight: FontWeight.w500)
                  : TextStyle(fontSize: 12.5, color: p.textPrimary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
