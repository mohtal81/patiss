// lib/screens/params_screen.dart
import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class ParamsScreen extends StatefulWidget {
  const ParamsScreen({super.key});
  @override
  State<ParamsScreen> createState() => _ParamsScreenState();
}

class _ParamsScreenState extends State<ParamsScreen> {
  List<Map<String, dynamic>> _localBackups = [];
  List<Map<String, dynamic>> _driveBackups = [];
  bool _loadingDrive = false;
  bool _backingUp    = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final local = await DbHelper().listBackups();
    if (mounted) setState(() => _localBackups = local);
    if (AuthService().isSignedIn) _loadDriveBackups();
  }

  Future<void> _loadDriveBackups() async {
    setState(() => _loadingDrive = true);
    try {
      final drive = await AuthService().listDriveBackups();
      if (mounted) setState(() => _driveBackups = drive);
    } catch (_) {}
    if (mounted) setState(() => _loadingDrive = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth    = AuthService();
    final isSignedIn = auth.isSignedIn;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('Paramètres',
          style: TextStyle(
            color: AppColors.gold, fontSize: 18,
            fontWeight: FontWeight.w800, fontFamily: 'PlayfairDisplay')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Compte Google ─────────────────────────────
          const SectionHeader(title: 'Compte Google'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: isSignedIn ? Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded,
                        color: AppColors.green, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(auth.userName ?? '',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15, fontWeight: FontWeight.w700)),
                          Text(auth.userEmail ?? '',
                            style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.green.withOpacity(0.3)),
                      ),
                      child: const Text('Connecté',
                        style: TextStyle(
                          color: AppColors.green, fontSize: 11,
                          fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () async {
                    await auth.signOut();
                    setState(() {});
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Se déconnecter'),
                ),
              ],
            ) : Column(
              children: [
                const Icon(Icons.cloud_off_rounded,
                  color: AppColors.textMuted, size: 36),
                const SizedBox(height: 8),
                const Text('Non connecté',
                  style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 14,
                    fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('Connectez-vous pour sauvegarder sur Drive',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  textAlign: TextAlign.center),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Connexion Google',
                  icon: Icons.login_rounded,
                  onPressed: () async {
                    await auth.signIn();
                    setState(() {});
                    if (auth.isSignedIn) _loadDriveBackups();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Sauvegarde locale ─────────────────────────
          const SectionHeader(title: 'Sauvegarde locale'),
          const SizedBox(height: 12),

          PrimaryButton(
            label: 'Créer une sauvegarde',
            icon: Icons.save_rounded,
            color: AppColors.purple,
            loading: _backingUp,
            onPressed: () async {
              setState(() => _backingUp = true);
              try {
                final path = await DbHelper().backupDb();
                final name = path.split('/').last;
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Sauvegardé : $name'),
                    backgroundColor: AppColors.green));
                }
                _load();
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Erreur : $e'),
                  backgroundColor: AppColors.red));
              } finally {
                if (mounted) setState(() => _backingUp = false);
              }
            },
          ),
          const SizedBox(height: 12),

          if (_localBackups.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text('Aucune sauvegarde locale.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                textAlign: TextAlign.center),
            )
          else
            ...(_localBackups.take(5).map((bk) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.storage_rounded,
                    color: AppColors.purple, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(bk['name'].toString().replaceAll('backup_', '').replaceAll('.db', ''),
                          style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 12,
                            fontWeight: FontWeight.w600)),
                        Text('${(bk['size'] as int) ~/ 1024} Ko',
                          style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _confirmRestore(bk),
                    child: const Text('Restaurer',
                      style: TextStyle(
                        color: AppColors.orange, fontSize: 12,
                        fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ))),

          if (isSignedIn) ...[
            const SizedBox(height: 20),

            // ── Sauvegarde Drive ──────────────────────────
            Row(
              children: [
                const SectionHeader(title: 'Sauvegarde Google Drive'),
                const Spacer(),
                if (_loadingDrive)
                  const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.gold)),
              ],
            ),
            const SizedBox(height: 12),

            PrimaryButton(
              label: 'Sauvegarder sur Drive',
              icon: Icons.cloud_upload_rounded,
              color: const Color(0xFF1A73E8),
              onPressed: () async {
                try {
                  await AuthService().backupToDrive();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Sauvegardé sur Google Drive !'),
                      backgroundColor: AppColors.green));
                  }
                  _loadDriveBackups();
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Erreur Drive : $e'),
                    backgroundColor: AppColors.red));
                }
              },
            ),
            const SizedBox(height: 12),

            if (_driveBackups.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text('Aucune sauvegarde sur Drive.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  textAlign: TextAlign.center),
              )
            else
              ...(_driveBackups.take(5).map((bk) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_rounded,
                      color: Color(0xFF1A73E8), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        bk['name'].toString()
                          .replaceAll('patisserie_backup_', '')
                          .replaceAll('.db', ''),
                        style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 12,
                          fontWeight: FontWeight.w600)),
                    ),
                    Text(bk['modifiedTime']?.toString().substring(0, 10) ?? '',
                      style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ))),
          ],

          const SizedBox(height: 20),

          // ── Infos ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _infoRow('Version', '1.0.0'),
                const Divider(height: 16),
                _infoRow('DB', 'SQLite local'),
                const Divider(height: 16),
                FutureBuilder<String>(
                  future: DbHelper().getDbPath(),
                  builder: (ctx, snap) => _infoRow('Chemin DB',
                    snap.data?.split('/').last ?? '...'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text(label,
          style: const TextStyle(
            color: AppColors.textSecondary, fontSize: 12)),
        const Spacer(),
        Text(value,
          style: const TextStyle(
            color: AppColors.textPrimary, fontSize: 12,
            fontWeight: FontWeight.w600)),
      ],
    );
  }

  Future<void> _confirmRestore(Map<String, dynamic> bk) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurer ?'),
        content: Text('Restaurer "${bk['name']}" ?\nLes données actuelles seront remplacées.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restaurer',
              style: TextStyle(color: AppColors.orange))),
        ],
      ),
    );
    if (ok == true) {
      try {
        await DbHelper().restoreDb(bk['path']);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restauration réussie !'),
            backgroundColor: AppColors.green));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'),
            backgroundColor: AppColors.red));
      }
    }
  }
}
