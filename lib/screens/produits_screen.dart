// lib/screens/produits_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/db_helper.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class ProduitsScreen extends StatefulWidget {
  const ProduitsScreen({super.key});
  @override
  State<ProduitsScreen> createState() => _ProduitsScreenState();
}

class _ProduitsScreenState extends State<ProduitsScreen> {
  List<Map<String, dynamic>> _produits = [];
  bool _loading = true;

  static const _categories = ['Tous', 'Baklawa', 'Halwa', 'Gâteaux', 'Biscuits', 'Autres'];
  String _catFilter = 'Tous';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cat = _catFilter == 'Tous' ? null : _catFilter;
    final data = await DbHelper().getProduits(categorie: cat);
    if (mounted) setState(() { _produits = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('Produits & Recettes',
          style: TextStyle(
            color: AppColors.gold, fontSize: 18,
            fontWeight: FontWeight.w800, fontFamily: 'PlayfairDisplay')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, color: AppColors.gold, size: 28),
            onPressed: () => _showForm(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtre catégorie
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _categories.map((cat) {
                final sel = _catFilter == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () { setState(() => _catFilter = cat); _load(); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.gold.withOpacity(0.15) : AppColors.surface2,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel ? AppColors.gold : AppColors.border,
                          width: sel ? 1.5 : 1),
                      ),
                      child: Text(cat,
                        style: TextStyle(
                          color: sel ? AppColors.gold : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: sel ? FontWeight.w800 : FontWeight.w500)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
              : _produits.isEmpty
                ? EmptyState(
                    icon: Icons.cake_outlined,
                    message: 'Aucun produit.',
                    actionLabel: '+ Ajouter',
                    onAction: () => _showForm(),
                  )
                : RefreshIndicator(
                    color: AppColors.gold,
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: _produits.length,
                      itemBuilder: (ctx, i) => _ProduitCard(
                        produit: _produits[i],
                        onEdit: () => _showForm(p: _produits[i]),
                        onRecette: () => _showRecette(_produits[i]),
                        onDelete: () => _confirmDelete(_produits[i]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showForm({Map<String, dynamic>? p}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _ProduitForm(
        produit: p,
        onSaved: () { Navigator.pop(ctx); _load(); },
      ),
    );
  }

  Future<void> _showRecette(Map<String, dynamic> p) async {
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
      builder: (ctx) => _RecetteForm(
        produit: p,
        ingredients: ings,
        onSaved: () { Navigator.pop(ctx); _load(); },
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('Supprimer "${p['nom']}" ?\nSes recettes seront supprimées.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (ok == true) { await DbHelper().deleteProduit(p['id']); _load(); }
  }
}

class _ProduitCard extends StatelessWidget {
  final Map<String, dynamic> produit;
  final VoidCallback onEdit, onRecette, onDelete;

  const _ProduitCard({
    required this.produit,
    required this.onEdit, required this.onRecette, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final p = produit;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DbHelper().getRecette(p['id']),
      builder: (ctx, snap) {
        final recette = snap.data ?? [];
        final hasRecette = recette.isNotEmpty;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.cake_rounded,
                        color: AppColors.gold, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['nom'],
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15, fontWeight: FontWeight.w700)),
                          if ((p['description'] ?? '').isNotEmpty)
                            Text(p['description'],
                              style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.purple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(p['categorie'] ?? 'Autres',
                                  style: const TextStyle(
                                    color: AppColors.purple,
                                    fontSize: 10, fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: hasRecette
                                    ? AppColors.green.withOpacity(0.1)
                                    : AppColors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  hasRecette
                                    ? '${recette.length} ing.'
                                    : '⚠ Recette vide',
                                  style: TextStyle(
                                    color: hasRecette
                                      ? AppColors.green : AppColors.orange,
                                    fontSize: 10, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${p['prix_vente']} DA',
                          style: const TextStyle(
                            color: AppColors.green,
                            fontSize: 16, fontWeight: FontWeight.w900)),
                        const Text('/pièce',
                          style: TextStyle(
                            color: AppColors.textMuted, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.menu_book_rounded, size: 14,
                          color: AppColors.purple),
                        label: const Text('Recette',
                          style: TextStyle(color: AppColors.purple, fontSize: 12)),
                        onPressed: onRecette,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.purple.withOpacity(0.4)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 14,
                          color: AppColors.gold),
                        label: const Text('Modifier',
                          style: TextStyle(color: AppColors.gold, fontSize: 12)),
                        onPressed: onEdit,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.gold.withOpacity(0.4)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                        color: AppColors.red, size: 18),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProduitForm extends StatefulWidget {
  final Map<String, dynamic>? produit;
  final VoidCallback onSaved;
  const _ProduitForm({this.produit, required this.onSaved});

  @override
  State<_ProduitForm> createState() => _ProduitFormState();
}

class _ProduitFormState extends State<_ProduitForm> {
  final _formKey = GlobalKey<FormState>();
  final _nom     = TextEditingController();
  final _prix    = TextEditingController();
  final _desc    = TextEditingController();
  String _cat    = 'Autres';
  bool _saving   = false;

  static const _cats = ['Baklawa', 'Halwa', 'Gâteaux', 'Biscuits', 'Autres'];

  @override
  void initState() {
    super.initState();
    final p = widget.produit;
    if (p != null) {
      _nom.text  = p['nom'];
      _prix.text = '${p['prix_vente']}';
      _desc.text = p['description'] ?? '';
      _cat       = p['categorie'] ?? 'Autres';
    }
  }

  @override
  void dispose() { _nom.dispose(); _prix.dispose(); _desc.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final db   = DbHelper();
      final nom  = _nom.text.trim();
      final prix = double.tryParse(_prix.text) ?? 0;
      final desc = _desc.text.trim().isNotEmpty ? _desc.text.trim() : null;
      if (widget.produit != null) {
        await db.updateProduit(widget.produit!['id'], nom, prix, desc, _cat);
      } else {
        await db.addProduit(nom, prix, desc, _cat);
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 12,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 12),
              Text(widget.produit != null ? 'Modifier produit' : 'Nouveau produit',
                style: const TextStyle(
                  color: AppColors.gold, fontSize: 18,
                  fontWeight: FontWeight.w800, fontFamily: 'PlayfairDisplay')),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Nom du produit', hint: 'ex: Baklawa',
                controller: _nom, required: true,
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Prix / pièce (DA)', hint: '0',
                controller: _prix,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                validator: (v) => double.tryParse(v ?? '') == null ? 'Nombre requis' : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Description', hint: 'ex: Aux amandes',
                controller: _desc, maxLines: 2,
              ),
              const SizedBox(height: 12),
              // Catégorie
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Catégorie',
                    style: TextStyle(color: AppColors.textSecondary,
                      fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: _cats.map((cat) => GestureDetector(
                      onTap: () => setState(() => _cat = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: _cat == cat
                            ? AppColors.purple.withOpacity(0.15)
                            : AppColors.surface2,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _cat == cat ? AppColors.purple : AppColors.border),
                        ),
                        child: Text(cat,
                          style: TextStyle(
                            color: _cat == cat ? AppColors.purple : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: _cat == cat ? FontWeight.w700 : FontWeight.w500)),
                      ),
                    )).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: widget.produit != null ? 'Enregistrer' : 'Créer',
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

class _RecetteForm extends StatefulWidget {
  final Map<String, dynamic> produit;
  final List<Map<String, dynamic>> ingredients;
  final VoidCallback onSaved;
  const _RecetteForm({required this.produit, required this.ingredients, required this.onSaved});

  @override
  State<_RecetteForm> createState() => _RecetteFormState();
}

class _RecetteFormState extends State<_RecetteForm> {
  final Map<int, TextEditingController> _ctrls = {};
  bool _loading = true, _saving = false;

  @override
  void initState() {
    super.initState();
    _loadRecette();
  }

  Future<void> _loadRecette() async {
    final recette = await DbHelper().getRecette(widget.produit['id']);
    final recMap  = {for (final r in recette) r['ingredient_id'] as int: r};
    for (final ing in widget.ingredients) {
      final id = ing['id'] as int;
      final ex = recMap[id];
      _ctrls[id] = TextEditingController(
        text: ex != null ? '${ex['quantite_100']}' : '');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final db = DbHelper();
      for (final ing in widget.ingredients) {
        final id  = ing['id'] as int;
        final qte = double.tryParse(_ctrls[id]?.text ?? '') ?? 0;
        await db.setRecetteLigne(widget.produit['id'], id, qte);
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
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 12),
                Text('Recette : ${widget.produit['nom']}',
                  style: const TextStyle(
                    color: AppColors.gold, fontSize: 18,
                    fontWeight: FontWeight.w800, fontFamily: 'PlayfairDisplay')),
                const SizedBox(height: 4),
                const Text('Quantités pour 100 pièces. Laisser vide = non utilisé.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 12),
              ],
            ),
          ),
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
              : ListView(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Expanded(child: Text('Ingrédient',
                            style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11,
                              fontWeight: FontWeight.w700, letterSpacing: 0.5))),
                          const Text('Qté / 100 pcs',
                            style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11,
                              fontWeight: FontWeight.w700)),
                          const SizedBox(width: 60),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...widget.ingredients.map((ing) {
                      final id  = ing['id'] as int;
                      final ctrl = _ctrls[id]!;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(ing['nom'],
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13, fontWeight: FontWeight.w600)),
                                  Text(ing['unite'],
                                    style: const TextStyle(
                                      color: AppColors.textMuted, fontSize: 10)),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: TextFormField(
                                controller: ctrl,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                                style: const TextStyle(
                                  color: AppColors.textPrimary, fontSize: 13),
                                textAlign: TextAlign.right,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                                  hintText: '0',
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Enregistrer la recette',
                      icon: Icons.check_rounded,
                      loading: _saving,
                      onPressed: _save,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
          ),
        ],
      ),
    );
  }
}
