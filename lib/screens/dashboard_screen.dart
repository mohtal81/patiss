// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _alerts = [];
  List<Map<String, dynamic>> _commandes = [];
  String? _dateDebut, _dateFin;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = DbHelper();
    final stats    = await db.getStats(dateDebut: _dateDebut, dateFin: _dateFin);
    final alerts   = await db.getStockAlerts();
    final commandes = await db.getCommandes(dateDebut: _dateDebut, dateFin: _dateFin, limit: 8);
    if (mounted) setState(() {
      _stats = stats; _alerts = alerts; _commandes = commandes; _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.gold,
        backgroundColor: AppColors.surface,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(child: DateFilterChips(onChanged: (d, f) {
              _dateDebut = d; _dateFin = f; _load();
            })),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.gold)))
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: _buildKpis(),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: _buildFinancier(),
              ),
              if (_alerts.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  sliver: _buildAlerts(),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                sliver: _buildDernieresCommandes(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.bg,
      expandedHeight: 100,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tableau de bord',
              style: TextStyle(
                color: AppColors.gold, fontSize: 20,
                fontWeight: FontWeight.w800, fontFamily: 'PlayfairDisplay',
              )),
            const Text('Pâtisserie Orientale',
              style: TextStyle(
                color: AppColors.textSecondary, fontSize: 11,
                fontWeight: FontWeight.w500,
              )),
          ],
        ),
      ),
    );
  }

  SliverGrid _buildKpis() {
    final stats = _stats;
    return SliverGrid(
      delegate: SliverChildListDelegate([
        KpiCard(
          label: 'En cours',
          value: '${stats['commandes_en_cours'] ?? 0}',
          color: AppColors.orange,
          icon: Icons.hourglass_empty_rounded,
        ),
        KpiCard(
          label: "CA (livrées)",
          value: _fmt(stats['ca_total'] ?? 0),
          color: AppColors.green,
          icon: Icons.trending_up_rounded,
        ),
        KpiCard(
          label: 'Alertes stock',
          value: '${stats['nb_alertes'] ?? 0}',
          color: AppColors.red,
          icon: Icons.warning_amber_rounded,
        ),
        KpiCard(
          label: 'Valeur stock',
          value: _fmt(stats['valeur_stock'] ?? 0),
          color: AppColors.purple,
          icon: Icons.inventory_2_rounded,
        ),
      ]),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10,
        childAspectRatio: 1.7,
      ),
    );
  }

  SliverToBoxAdapter _buildFinancier() {
    final ca       = (_stats['ca_total']        as num?)?.toDouble() ?? 0;
    final depenses = (_stats['depenses_achats'] as num?)?.toDouble() ?? 0;
    final benefice = ca - depenses;
    final beneficeColor = benefice >= 0 ? AppColors.green : AppColors.red;

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const SectionHeader(title: 'Bilan financier'),
            const SizedBox(height: 14),
            Row(
              children: [
                _finItem('Chiffre d\'affaires', ca, AppColors.green),
                Container(width: 1, height: 40, color: AppColors.border),
                _finItem('Dépenses', depenses, AppColors.orange),
                Container(width: 1, height: 40, color: AppColors.border),
                _finItem('Bénéfice', benefice, beneficeColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _finItem(String label, double val, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(_fmt(val),
            style: TextStyle(
              color: color, fontSize: 14,
              fontWeight: FontWeight.w900,
            )),
          const SizedBox(height: 3),
          Text(label, textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildAlerts() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: '⚠  ${_alerts.length} alerte(s) stock',
            action: TextButton(
              onPressed: () {},
              child: const Text('Voir tout',
                style: TextStyle(color: AppColors.gold, fontSize: 12)),
            ),
          ),
          const SizedBox(height: 10),
          ..._alerts.take(3).map((a) => AlertChip(
            nom: a['nom'],
            stockActuel: (a['stock_actuel'] as num).toDouble(),
            stockMin: (a['stock_min'] as num).toDouble(),
            unite: a['unite'],
          )),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildDernieresCommandes() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Dernières commandes'),
          const SizedBox(height: 10),
          if (_commandes.isEmpty)
            const EmptyState(
              icon: Icons.receipt_long_rounded,
              message: 'Aucune commande sur cette période.',
            )
          else
            ..._commandes.map((c) => _CommandeRow(commande: c)),
        ],
      ),
    );
  }

  String _fmt(dynamic v) {
    final d = (v as num?)?.toDouble() ?? 0;
    if (d.abs() >= 1000000) return '${(d / 1000000).toStringAsFixed(1)}M DA';
    if (d.abs() >= 1000) return '${(d / 1000).toStringAsFixed(0)}k DA';
    return '${d.toStringAsFixed(0)} DA';
  }
}

class _CommandeRow extends StatelessWidget {
  final Map<String, dynamic> commande;
  const _CommandeRow({required this.commande});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: DbHelper().getTotalCommande(commande['id']),
      builder: (ctx, snap) {
        final total = snap.data ?? 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(commande['client'],
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14, fontWeight: FontWeight.w700)),
                    if (commande['date_livraison'] != null &&
                        commande['date_livraison'].toString().isNotEmpty)
                      Text('Livr: ${commande['date_livraison']}',
                        style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              StatusBadge(commande['statut']),
              const SizedBox(width: 10),
              Text('${total.toStringAsFixed(0)} DA',
                style: const TextStyle(
                  color: AppColors.green, fontSize: 14,
                  fontWeight: FontWeight.w800)),
            ],
          ),
        );
      },
    );
  }
}
