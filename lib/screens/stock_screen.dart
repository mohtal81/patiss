// lib/screens/stock_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/db_helper.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});
  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  List<Map<String, dynamic>> _ingredients = [];
  final _searchCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() => _load(search: _searchCtrl.text));
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load({String? search}) async {
    final data = await DbHelper().getIngredients(search: search ?? _searchCtrl.text.trim());
    if (mounted) setState(() { _ingredients = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final alertes = _ingredients.where((i) =>
      (i['stock_actuel'] as num) <= (i['stock_min'] as num)).length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Stock Ingrédients',
              style: TextStyle(
                color: AppColors.gold, fontSize: 18,
                fontWeight: FontWeight.w800, fontFamily: 'PlayfairDisplay')),
            if (alertes > 0)
              Text('$alertes alerte(s)',
                style: const TextStyle(color: AppColors.red, fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, color: AppColors.gold, size: 28),
            onPressed: () => _showForm(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Rechercher un ingrédient...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                      onPressed: () { _searchCtrl.clear(); _load(); })
                  : null,
              ),
            ),
          ),
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
              : _ingredients.isEmpty
                ? EmptyState(
                    icon: Icons.inventory_2_outlined,
                    message: 'Aucun ingrédient trouvé.',
                    actionLabel: '+ Ajouter',
                    onAction: () => _showForm(),
                  )
                : RefreshIndicator(
                    color: AppColors.gold,
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: _ingredients.length,
                      itemBuilder: (ctx, i) => _IngredientCard(
                        ingredient: _ingredients[i],
                        onEdit: () => _showForm(ing: _ingredients[i]),
                        onDelete: () => _confirmDelete(_ingredients[i]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> ing) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('Supprimer "${ing['nom']}" ?\nSes recettes seront aussi supprimées.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (ok == true) {
      await DbHelper().deleteIngredient(ing['id']);
      _load();
    }
  }

  void _showForm({Map<String, dynamic>? ing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _IngredientForm(
        ingredient: ing,
        onSaved: () { Navigator.pop(ctx); _load(); },
      ),
    );
  }
}

class _IngredientCard extends StatelessWidget {
  final Map<String, dynamic> ingredient;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _IngredientCard({
    required this.ingredient, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final ing     = ingredient;
    final stock   = (ing['stock_actuel'] as num).toDouble();
    final stockMin = (ing['stock_min'] as num).toDouble();
    final isLow   = stock <= stockMin;
    final percent = stockMin > 0 ? (stock / (stockMin * 2)).clamp(0.0, 1.0) : 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isLow ? AppColors.red.withOpacity(0.06) : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLow ? AppColors.red.withOpacity(0.3) : AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: isLow
                      ? AppColors.red.withOpacity(0.12)
                      : AppColors.gold.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.kitchen_rounded,
                    color: isLow ? AppColors.red : AppColors.gold,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ing['nom'],
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15, fontWeight: FontWeight.w700)),
                      Text('${ing['prix_unitaire']} DA/${ing['unite']}',
                        style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$stock ${ing['unite']}',
                      style: TextStyle(
                        color: isLow ? AppColors.red : AppColors.green,
                        fontSize: 16, fontWeight: FontWeight.w900)),
                    Text('min: $stockMin',
                      style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 10)),
                  ],
                ),
                const SizedBox(width: 8),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert, color: AppColors.textMuted, size: 18),
                  color: AppColors.surface2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      onTap: onEdit,
                      child: const Row(children: [
                        Icon(Icons.edit_outlined, color: AppColors.gold, size: 16),
                        SizedBox(width: 8),
                        Text('Modifier', style: TextStyle(color: AppColors.textPrimary)),
                      ])),
                    PopupMenuItem(
                      onTap: onDelete,
                      child: const Row(children: [
                        Icon(Icons.delete_outline, color: AppColors.red, size: 16),
                        SizedBox(width: 8),
                        Text('Supprimer', style: TextStyle(color: AppColors.red)),
                      ])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(
                  isLow ? AppColors.red : AppColors.green),
                minHeight: 4,
              ),
            ),
            if (isLow) ...[
              const SizedBox(height: 4),
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.red, size: 12),
                  SizedBox(width: 4),
                  Text('Stock faible !',
                    style: TextStyle(color: AppColors.red, fontSize: 11,
                      fontWeight: FontWeight.w700)),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class _IngredientForm extends StatefulWidget {
  final Map<String, dynamic>? ingredient;
  final VoidCallback onSaved;
  const _IngredientForm({this.ingredient, required this.onSaved});

  @override
  State<_IngredientForm> createState() => _IngredientFormState();
}

class _IngredientFormState extends State<_IngredientForm> {
  final _formKey = GlobalKey<FormState>();
  final _nom     = TextEditingController();
  final _stock   = TextEditingController();
  final _stockMin = TextEditingController();
  final _prix    = TextEditingController();
  String _unite  = 'kg';
  bool _saving   = false;

  static const _unites = ['kg', 'g', 'L', 'ml', 'unité'];

  @override
  void initState() {
    super.initState();
    final ing = widget.ingredient;
    if (ing != null) {
      _nom.text     = ing['nom'];
      _stock.text   = '${ing['stock_actuel']}';
      _stockMin.text = '${ing['stock_min']}';
      _prix.text    = '${ing['prix_unitaire']}';
      _unite        = ing['unite'];
    }
  }

  @override
  void dispose() {
    _nom.dispose(); _stock.dispose(); _stockMin.dispose(); _prix.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final db = DbHelper();
      final nom  = _nom.text.trim();
      final stock = double.tryParse(_stock.text) ?? 0;
      final min   = double.tryParse(_stockMin.text) ?? 0;
      final prix  = double.tryParse(_prix.text) ?? 0;

      if (widget.ingredient != null) {
        await db.updateIngredient(widget.ingredient!['id'], nom, _unite, stock, min, prix);
      } else {
        await db.addIngredient(nom, _unite, stock, min, prix);
      }
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
    final isEdit = widget.ingredient != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
                )),
              const SizedBox(height: 16),
              Text(isEdit ? 'Modifier ingrédient' : 'Nouvel ingrédient',
                style: const TextStyle(
                  color: AppColors.gold, fontSize: 18,
                  fontWeight: FontWeight.w800, fontFamily: 'PlayfairDisplay')),
              const SizedBox(height: 20),

              AppTextField(
                label: 'Nom', hint: 'ex: Amandes', controller: _nom,
                required: true,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 14),

              // Unité
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Unité',
                    style: TextStyle(color: AppColors.textSecondary,
                      fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: _unites.map((u) => GestureDetector(
                      onTap: () => setState(() => _unite = u),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _unite == u
                            ? AppColors.gold.withOpacity(0.15)
                            : AppColors.surface2,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _unite == u ? AppColors.gold : AppColors.border),
                        ),
                        child: Text(u,
                          style: TextStyle(
                            color: _unite == u ? AppColors.gold : AppColors.textSecondary,
                            fontWeight: _unite == u ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 13,
                          )),
                      ),
                    )).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(child: AppTextField(
                    label: 'Stock actuel', hint: '0',
                    controller: _stock,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                    validator: (v) => double.tryParse(v ?? '') == null ? 'Nombre' : null,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: AppTextField(
                    label: 'Stock minimum', hint: '0',
                    controller: _stockMin,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                    validator: (v) => double.tryParse(v ?? '') == null ? 'Nombre' : null,
                  )),
                ],
              ),
              const SizedBox(height: 14),

              AppTextField(
                label: 'Prix / unité (DA)', hint: '0',
                controller: _prix,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                validator: (v) => double.tryParse(v ?? '') == null ? 'Nombre' : null,
              ),
              const SizedBox(height: 24),

              PrimaryButton(
                label: isEdit ? 'Enregistrer' : 'Ajouter',
                icon: Icons.check_rounded,
                loading: _saving,
                onPressed: _save,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
