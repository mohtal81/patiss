// lib/screens/commandes_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/db_helper.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class CommandesScreen extends StatefulWidget {
  const CommandesScreen({super.key});
  @override
  State<CommandesScreen> createState() => _CommandesScreenState();
}

class _CommandesScreenState extends State<CommandesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Map<String, dynamic>> _commandes = [];
  String? _dateDebut, _dateFin;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() { if (!_tab.indexIsChanging) _load(); });
    _load();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  String? get _currentStatut {
    switch (_tab.index) {
      case 1: return 'en_cours';
      case 2: return 'terminee';
      default: return null;
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final data = await DbHelper().getCommandes(
      statut: _currentStatut,
      dateDebut: _dateDebut,
      dateFin: _dateFin,
    );
    if (mounted) setState(() { _commandes = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('Commandes',
          style: TextStyle(
            color: AppColors.gold, fontSize: 18,
            fontWeight: FontWeight.w800, fontFamily: 'PlayfairDisplay')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, color: AppColors.gold, size: 28),
            onPressed: _showNewCommande,
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppColors.gold,
          indicatorWeight: 2,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Toutes'),
            Tab(text: 'En cours'),
            Tab(text: 'Terminées'),
          ],
        ),
      ),
      body: Column(
        children: [
          DateFilterChips(onChanged: (d, f) {
            _dateDebut = d; _dateFin = f; _load();
          }),
          // Résumé
          FutureBuilder<List<double>>(
            future: Future.wait(
              _commandes.map((c) => DbHelper().getTotalCommande(c['id']))),
            builder: (ctx, snap) {
              final total = snap.data?.fold(0.0, (a, b) => a + b) ?? 0;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${_commandes.length} commande(s)',
                      style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                    Text('CA : ${total.toStringAsFixed(0)} DA',
                      style: const TextStyle(
                        color: AppColors.green, fontSize: 13,
                        fontWeight: FontWeight.w800)),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: List.generate(3, (_) =>
                _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                  : _commandes.isEmpty
                    ? EmptyState(
                        icon: Icons.receipt_long_outlined,
                        message: 'Aucune commande.',
                        actionLabel: '+ Nouvelle commande',
                        onAction: _showNewCommande,
                      )
                    : RefreshIndicator(
                        color: AppColors.gold,
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: _commandes.length,
                          itemBuilder: (ctx, i) => _CommandeCard(
                            commande: _commandes[i],
                            onRefresh: _load,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showNewCommande() async {
    final produits = await DbHelper().getProduits();
    if (produits.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajoutez d\'abord des produits.'),
          backgroundColor: AppColors.orange,
        ));
      return;
    }
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _NouvelleCommandeForm(
        produits: produits,
        onSaved: () { Navigator.pop(ctx); _load(); },
      ),
    );
  }
}

// ── Carte commande ────────────────────────────────────────
class _CommandeCard extends StatelessWidget {
  final Map<String, dynamic> commande;
  final VoidCallback onRefresh;

  const _CommandeCard({required this.commande, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final c = commande;
    return FutureBuilder<double>(
      future: DbHelper().getTotalCommande(c['id']),
      builder: (ctx, snap) {
        final total = snap.data ?? 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showDetail(context),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c['client'],
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15, fontWeight: FontWeight.w700)),
                            if ((c['telephone'] ?? '').isNotEmpty)
                              Text(c['telephone'],
                                style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                      StatusBadge(c['statut']),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if ((c['date_livraison'] ?? '').isNotEmpty)
                        _chip(Icons.calendar_today_rounded,
                          c['date_livraison'], AppColors.purple),
                      const Spacer(),
                      Text('${total.toStringAsFixed(0)} DA',
                        style: const TextStyle(
                          color: AppColors.green,
                          fontSize: 16, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _CommandeDetail(
        commande: commande,
        onChanged: () { Navigator.pop(ctx); onRefresh(); },
      ),
    );
  }
}

// ── Detail commande ───────────────────────────────────────
class _CommandeDetail extends StatefulWidget {
  final Map<String, dynamic> commande;
  final VoidCallback onChanged;
  const _CommandeDetail({required this.commande, required this.onChanged});

  @override
  State<_CommandeDetail> createState() => _CommandeDetailState();
}

class _CommandeDetailState extends State<_CommandeDetail> {
  List<Map<String, dynamic>> _lignes = [];
  List<Map<String, dynamic>> _besoins = [];
  double _total = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = DbHelper();
    final lignes  = await db.getLignesCommande(widget.commande['id']);
    final total   = await db.getTotalCommande(widget.commande['id']);
    final besoins = await db.getBesoinsPourCommande(widget.commande['id']);
    if (mounted) setState(() {
      _lignes = lignes; _total = total; _besoins = besoins;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c        = widget.commande;
    final isTerminee = c['statut'] == 'terminee';
    final manques  = _besoins.where((b) => !(b['ok'] as bool)).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scroll) => Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2)),
          ),
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text('Commande #${c['id']}',
                        style: const TextStyle(
                          color: AppColors.gold, fontSize: 18,
                          fontWeight: FontWeight.w800, fontFamily: 'PlayfairDisplay')),
                    ),
                    StatusBadge(c['statut']),
                  ],
                ),
                const SizedBox(height: 4),
                Text(c['client'],
                  style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14)),
                if ((c['telephone'] ?? '').isNotEmpty)
                  Text('📞 ${c['telephone']}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                if ((c['date_livraison'] ?? '').isNotEmpty)
                  Text('📅 Livraison: ${c['date_livraison']}',
                    style: const TextStyle(color: AppColors.purple, fontSize: 13,
                      fontWeight: FontWeight.w600)),
                if ((c['notes'] ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('💬 ${c['notes']}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ),

                const Divider(height: 24),

                // Produits
                const SectionHeader(title: 'Produits commandés'),
                const SizedBox(height: 10),
                ..._lignes.map((l) {
                  final sous = (l['nb_pieces'] as num) * (l['prix_unitaire'] as num);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(l['produit_nom'],
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                        Text('${l['nb_pieces'].toInt()} pcs',
                          style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                        const SizedBox(width: 12),
                        Text('${sous.toStringAsFixed(0)} DA',
                          style: const TextStyle(
                            color: AppColors.green,
                            fontSize: 14, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  );
                }),

                // Total
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.green.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      const Text('TOTAL',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12, fontWeight: FontWeight.w700,
                          letterSpacing: 1)),
                      const Spacer(),
                      Text('${_total.toStringAsFixed(0)} DA',
                        style: const TextStyle(
                          color: AppColors.green,
                          fontSize: 22, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),

                // Besoins ingrédients
                if (_besoins.isNotEmpty) ...[
                  const Divider(height: 24),
                  SectionHeader(
                    title: manques.isEmpty ? '✓ Ingrédients OK' : '⚠ Manques détectés',
                  ),
                  const SizedBox(height: 8),
                  ..._besoins.map((b) {
                    final ok = b['ok'] as bool;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: ok
                          ? AppColors.green.withOpacity(0.06)
                          : AppColors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: ok
                            ? AppColors.green.withOpacity(0.2)
                            : AppColors.red.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            ok ? Icons.check_circle_outline : Icons.error_outline,
                            color: ok ? AppColors.green : AppColors.red,
                            size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(b['nom'],
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                          if (ok)
                            Text('${(b['besoin'] as double).toStringAsFixed(2)} ${b['unite']}',
                              style: const TextStyle(
                                color: AppColors.green, fontSize: 11))
                          else
                            Text(
                              'manque ${(b['manque'] as double).toStringAsFixed(2)} ${b['unite']}',
                              style: const TextStyle(
                                color: AppColors.red, fontSize: 11,
                                fontWeight: FontWeight.w700)),
                        ],
                      ),
                    );
                  }),
                ],

                const Divider(height: 24),

                // Actions
                if (!isTerminee) ...[
                  PrimaryButton(
                    label: 'Marquer comme Terminée',
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.green,
                    onPressed: () => _changeStatut('terminee'),
                  ),
                  const SizedBox(height: 10),
                ] else ...[
                  PrimaryButton(
                    label: 'Remettre En cours',
                    icon: Icons.replay_rounded,
                    color: AppColors.orange,
                    onPressed: () => _changeStatut('en_cours'),
                  ),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline, color: AppColors.red, size: 18),
                    label: const Text('Supprimer cette commande',
                      style: TextStyle(color: AppColors.red)),
                    onPressed: _confirmDelete,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.red.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeStatut(String s) async {
    await DbHelper().updateStatutCommande(widget.commande['id'], s);
    widget.onChanged();
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: const Text('Cette commande sera définitivement supprimée.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer',
              style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (ok == true) {
      await DbHelper().deleteCommande(widget.commande['id']);
      widget.onChanged();
    }
  }
}

// ── Formulaire nouvelle commande ──────────────────────────
class _NouvelleCommandeForm extends StatefulWidget {
  final List<Map<String, dynamic>> produits;
  final VoidCallback onSaved;
  const _NouvelleCommandeForm({required this.produits, required this.onSaved});

  @override
  State<_NouvelleCommandeForm> createState() => _NouvelleCommandeFormState();
}

class _NouvelleCommandeFormState extends State<_NouvelleCommandeForm> {
  final _formKey = GlobalKey<FormState>();
  final _client  = TextEditingController();
  final _tel     = TextEditingController();
  final _date    = TextEditingController();
  final _notes   = TextEditingController();
  bool _saving   = false;

  final List<_LigneState> _lignes = [];

  @override
  void initState() {
    super.initState();
    _addLigne();
  }

  void _addLigne() {
    setState(() => _lignes.add(_LigneState(
      produitId: widget.produits.first['id'],
      produitNom: widget.produits.first['nom'],
      prix: (widget.produits.first['prix_vente'] as num).toDouble(),
    )));
  }

  @override
  void dispose() {
    _client.dispose(); _tel.dispose();
    _date.dispose(); _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final lignes = _lignes.where((l) => l.nbPieces > 0).toList();
    if (lignes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez au moins un produit (qté > 0)'),
          backgroundColor: AppColors.red));
      return;
    }
    setState(() => _saving = true);
    try {
      await DbHelper().addCommande(
        _client.text.trim(),
        _tel.text.trim().isNotEmpty ? _tel.text.trim() : null,
        _date.text.trim().isNotEmpty ? _date.text.trim() : null,
        _notes.text.trim().isNotEmpty ? _notes.text.trim() : null,
        lignes.map((l) => {
          'produit_id': l.produitId,
          'nb_pieces': l.nbPieces,
          'prix_unitaire': l.prix,
        }).toList(),
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
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
              )),
            const SizedBox(height: 12),
            const Text('Nouvelle Commande',
              style: TextStyle(
                color: AppColors.gold, fontSize: 18,
                fontWeight: FontWeight.w800, fontFamily: 'PlayfairDisplay')),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      label: 'Client', hint: 'Nom du client',
                      controller: _client, required: true,
                      validator: (v) => (v?.trim().isEmpty ?? true) ? 'Requis' : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: AppTextField(
                          label: 'Téléphone', hint: '0555...',
                          controller: _tel,
                          keyboardType: TextInputType.phone,
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: AppTextField(
                          label: 'Date livraison', hint: 'JJ/MM/AAAA',
                          controller: _date,
                        )),
                      ],
                    ),
                    const SizedBox(height: 10),
                    AppTextField(
                      label: 'Notes', hint: 'Sans sucre, décoration...',
                      controller: _notes, maxLines: 2,
                    ),
                    const SizedBox(height: 14),

                    // Lignes produits
                    Row(
                      children: [
                        const SectionHeader(title: 'Produits'),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _addLigne,
                          icon: const Icon(Icons.add, size: 16, color: AppColors.gold),
                          label: const Text('Ajouter',
                            style: TextStyle(color: AppColors.gold, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    ..._lignes.asMap().entries.map((e) => _LigneWidget(
                      key: ValueKey(e.key),
                      produits: widget.produits,
                      state: e.value,
                      onRemove: _lignes.length > 1
                        ? () => setState(() => _lignes.removeAt(e.key))
                        : null,
                      onChange: () => setState(() {}),
                    )),

                    // Total estimé
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.green.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Text('Total estimé',
                            style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                          const Spacer(),
                          Text(
                            '${_lignes.fold(0.0, (s, l) => s + l.nbPieces * l.prix).toStringAsFixed(0)} DA',
                            style: const TextStyle(
                              color: AppColors.green, fontSize: 16,
                              fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'Créer la commande',
                      icon: Icons.receipt_long_rounded,
                      loading: _saving,
                      onPressed: _save,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LigneState {
  int    produitId;
  String produitNom;
  double prix;
  double nbPieces = 0;

  _LigneState({required this.produitId, required this.produitNom, required this.prix});
}

class _LigneWidget extends StatefulWidget {
  final List<Map<String, dynamic>> produits;
  final _LigneState state;
  final VoidCallback? onRemove;
  final VoidCallback onChange;

  const _LigneWidget({
    super.key, required this.produits, required this.state,
    this.onRemove, required this.onChange,
  });

  @override
  State<_LigneWidget> createState() => _LigneWidgetState();
}

class _LigneWidgetState extends State<_LigneWidget> {
  late TextEditingController _qteCtrl;
  late TextEditingController _prixCtrl;

  @override
  void initState() {
    super.initState();
    _qteCtrl  = TextEditingController();
    _prixCtrl = TextEditingController(text: widget.state.prix.toStringAsFixed(0));
    _qteCtrl.addListener(() {
      widget.state.nbPieces = double.tryParse(_qteCtrl.text) ?? 0;
      widget.onChange();
    });
    _prixCtrl.addListener(() {
      widget.state.prix = double.tryParse(_prixCtrl.text) ?? 0;
      widget.onChange();
    });
  }

  @override
  void dispose() { _qteCtrl.dispose(); _prixCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: widget.state.produitId,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  dropdownColor: AppColors.surface2,
                  style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13),
                  items: widget.produits.map((p) => DropdownMenuItem(
                    value: p['id'] as int,
                    child: Text(p['nom']),
                  )).toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    final p = widget.produits.firstWhere((p) => p['id'] == v);
                    setState(() {
                      widget.state.produitId  = v;
                      widget.state.produitNom = p['nom'];
                      widget.state.prix = (p['prix_vente'] as num).toDouble();
                      _prixCtrl.text = widget.state.prix.toStringAsFixed(0);
                    });
                    widget.onChange();
                  },
                ),
              ),
              if (widget.onRemove != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                    color: AppColors.red, size: 20),
                  onPressed: widget.onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _qteCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Nb pièces',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _prixCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Prix DA/pce',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
