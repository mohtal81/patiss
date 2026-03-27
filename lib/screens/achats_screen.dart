// lib/screens/achats_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/db_helper.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class AchatsScreen extends StatefulWidget {
  const AchatsScreen({super.key});
  @override
  State<AchatsScreen> createState() => _AchatsScreenState();
}

class _AchatsScreenState extends State<AchatsScreen> {
  List<Map<String, dynamic>> _achats = [];
  String? _dateDebut, _dateFin;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await DbHelper().getAchats(
      dateDebut: _dateDebut, dateFin: _dateFin);
    if (mounted) setState(() { _achats = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final totalDep = _achats.fold(0.0, (s, a) => s + (a['prix_total'] as num));

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('Achats / Réappro',
          style: TextStyle(
            color: AppColors.gold, fontSize: 18,
            fontWeight: FontWeight.w800, fontFamily: 'PlayfairDisplay')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, color: AppColors.gold, size: 28),
            onPressed: _showForm,
          ),
        ],
      ),
      body: Column(
        children: [
          DateFilterChips(onChanged: (d, f) {
            _dateDebut = d; _dateFin = f; _load();
          }),
          // Résumé dépenses
          if (!_loading)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.orange.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart_rounded,
                    color: AppColors.orange, size: 18),
                  const SizedBox(width: 10),
                  const Text('Total dépenses :',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const Spacer(),
                  Text('${totalDep.toStringAsFixed(0)} DA',
                    style: const TextStyle(
                      color: AppColors.orange, fontSize: 16,
                      fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
              : _achats.isEmpty
                ? EmptyState(
                    icon: Icons.shopping_cart_outlined,
                    message: 'Aucun achat sur cette période.',
                    actionLabel: '+ Enregistrer un achat',
                    onAction: _showForm,
                  )
                : RefreshIndicator(
                    color: AppColors.gold,
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: _achats.length,
                      itemBuilder: (ctx, i) => _AchatCard(achat: _achats[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showForm() async {
    final ings = await DbHelper().getIngredients();
    if (ings.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez d\'abord des ingrédients.'),
          backgroundColor: AppColors.orange));
      return;
    }
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _AchatForm(
        ingredients: ings,
        onSaved: () { Navigator.pop(ctx); _load(); },
      ),
    );
  }
}

class _AchatCard extends StatelessWidget {
  final Map<String, dynamic> achat;
  const _AchatCard({required this.achat});

  @override
  Widget build(BuildContext context) {
    final a = achat;
    final date = (a['created_at'] as String?)?.substring(0, 10) ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add_shopping_cart_rounded,
              color: AppColors.green, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a['ingredient_nom'],
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14, fontWeight: FontWeight.w700)),
                Text(
                  '${a['fournisseur'] != null && (a['fournisseur'] as String).isNotEmpty ? a['fournisseur'] : 'Fournisseur'}  ·  $date',
                  style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('+${a['quantite']} ${a['unite']}',
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 13, fontWeight: FontWeight.w800)),
              Text('${(a['prix_total'] as num).toStringAsFixed(0)} DA',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 14, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AchatForm extends StatefulWidget {
  final List<Map<String, dynamic>> ingredients;
  final VoidCallback onSaved;
  const _AchatForm({required this.ingredients, required this.onSaved});

  @override
  State<_AchatForm> createState() => _AchatFormState();
}

class _AchatFormState extends State<_AchatForm> {
  final _formKey = GlobalKey<FormState>();
  final _qte     = TextEditingController();
  final _prix    = TextEditingController();
  final _four    = TextEditingController();
  late int _selectedIngId;
  String _selectedIngUnite = 'kg';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedIngId    = widget.ingredients.first['id'];
    _selectedIngUnite = widget.ingredients.first['unite'];
  }

  @override
  void dispose() { _qte.dispose(); _prix.dispose(); _four.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final qte  = double.tryParse(_qte.text) ?? 0;
    if (qte <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantité doit être > 0'),
          backgroundColor: AppColors.red));
      return;
    }
    setState(() => _saving = true);
    try {
      await DbHelper().addAchat(
        _selectedIngId,
        qte,
        double.tryParse(_prix.text) ?? 0,
        _four.text.trim().isNotEmpty ? _four.text.trim() : null,
      );
      widget.onSaved();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 12,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 12),
            const Text('Nouvel achat / Réappro',
              style: TextStyle(
                color: AppColors.gold, fontSize: 18,
                fontWeight: FontWeight.w800, fontFamily: 'PlayfairDisplay')),
            const SizedBox(height: 16),

            // Ingrédient
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ingrédient *',
                  style: TextStyle(color: AppColors.textSecondary,
                    fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  value: _selectedIngId,
                  decoration: const InputDecoration(),
                  dropdownColor: AppColors.surface2,
                  style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14),
                  items: widget.ingredients.map((i) => DropdownMenuItem(
                    value: i['id'] as int,
                    child: Text('${i['nom']} (${i['unite']})'),
                  )).toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    final ing = widget.ingredients.firstWhere((i) => i['id'] == v);
                    setState(() {
                      _selectedIngId    = v;
                      _selectedIngUnite = ing['unite'];
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(child: AppTextField(
                  label: 'Quantité achetée ($_selectedIngUnite)', hint: '0',
                  controller: _qte, required: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    if ((double.tryParse(v) ?? 0) <= 0) return '> 0';
                    return null;
                  },
                )),
                const SizedBox(width: 12),
                Expanded(child: AppTextField(
                  label: 'Prix total (DA)', hint: '0',
                  controller: _prix,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                )),
              ],
            ),
            const SizedBox(height: 12),

            AppTextField(
              label: 'Fournisseur (optionnel)', hint: 'ex: Marché central',
              controller: _four,
            ),
            const SizedBox(height: 20),

            PrimaryButton(
              label: 'Enregistrer l\'achat',
              icon: Icons.add_shopping_cart_rounded,
              loading: _saving,
              onPressed: _save,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
