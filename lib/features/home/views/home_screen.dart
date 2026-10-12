import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart' as theme;
import '../viewmodels/hotspots_viewmodel.dart';

class _HomeAppColors {
  final Color navyDark = theme.appColors.navyDark;
  final Color navyCard = theme.appColors.navyCard;
  final Color navyLight = theme.appColors.navyLight;
  final Color amber = theme.appColors.amber;

  final Color white = const Color(0xFFFFFFFF);
  final Color mutedText = const Color(0xFF9AA4BF);
  final Color red = const Color(0xFFFF5252);
  final Color green = const Color(0xFF66BB6A);
}

/// The single instance for this file (injected, not static).
final _HomeAppColors appColors = _HomeAppColors();

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();

    _searchController = TextEditingController();

    Future.microtask(
      () => ref
          .read(hotspotsViewModelProvider.notifier)
          .loadHotspots(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hotspotsViewModelProvider);

    ref.listen<HotspotsState>(
      hotspotsViewModelProvider,
      (previous, next) {
        if (next.status == HotspotsStatus.error &&
            next.errorMessage != null &&
            next.errorMessage!.toLowerCase().contains('session')) {
          context.go('/login');
        }
      },
    );

    return Scaffold(
      backgroundColor: appColors.navyDark,
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(
    BuildContext context,
    HotspotsState state,
  ) {
    if (state.status == HotspotsStatus.loading &&
        state.list.isEmpty) {
      return const _LoadingView();
    }

    if (state.status == HotspotsStatus.error &&
        state.list.isEmpty) {
      return _ErrorView(
        message: state.errorMessage ?? 'Unable to load hotspots.',
        onRetry: () {
          ref
              .read(hotspotsViewModelProvider.notifier)
              .loadHotspots();
        },
      );
    }

    return RefreshIndicator(
      color: appColors.amber,
      backgroundColor: appColors.navyCard,
      onRefresh: () {
        return ref
            .read(hotspotsViewModelProvider.notifier)
            .refresh();
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeader(context, state),
          ),
          SliverToBoxAdapter(
            child: _buildSummary(state),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Row(
                children: [
                  Expanded(
                    child: _HomeAction(
                      icon: Icons.map_rounded,
                      title: 'Risk map',
                      subtitle: 'Tap Addis location',
                      onTap: () => context.push('/risk-map'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HomeAction(
                      icon: Icons.analytics_rounded,
                      title: 'Severity',
                      subtitle: 'Manual assessment',
                      onTap: () => context.push('/severity'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildSearch(),
          ),
          SliverToBoxAdapter(
            child: _buildFilters(state),
          ),
          SliverToBoxAdapter(
            child: _buildDangerZonePanel(state),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Top danger zones',
                      style: TextStyle(
                        color: appColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${state.filteredList.length} zones',
                    style: TextStyle(
                      color: appColors.mutedText,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (state.filteredList.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    'No hotspots found.',
                    style: TextStyle(
                      color: appColors.mutedText,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverList.builder(
                itemCount: state.filteredList.length,
                itemBuilder: (context, index) {
                  final hotspot = state.filteredList[index];
                  final vm = ref.read(
                    hotspotsViewModelProvider.notifier,
                  );

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _HotspotCard(
                      hotspot: hotspot,
                      rank: index + 1,
                      maxRisk: vm.maxRiskScore(),
                      riskBand: vm.riskBand(hotspot),
                      onTap: () {
                        _showHotspotDetails(context, hotspot);
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    HotspotsState state,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Hi, ',
                    style: TextStyle(
                      color: appColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: state.fullName,
                    style: TextStyle(
                      color: appColors.amber,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(
                    text: ' 👋',
                    style: TextStyle(fontSize: 21),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Stay alert on Addis roads',
              style: TextStyle(
                color: appColors.mutedText,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(HotspotsState state) {
    final vm = ref.read(hotspotsViewModelProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              value: _formatNumber(vm.totalAccidents()),
              label: 'Total accidents',
              icon: Icons.car_crash_rounded,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              value: _formatNumber(vm.totalFatalities()),
              label: 'Fatalities',
              icon: Icons.dangerous_rounded,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              value:
                  '${vm.mostCommonPeakHour().toString().padLeft(2, '0')}:00',
              label: 'Peak hour',
              icon: Icons.access_time_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: appColors.navyCard,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: appColors.navyLight,
          ),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            ref
                .read(hotspotsViewModelProvider.notifier)
                .search(value);
          },
          style: TextStyle(
            color: appColors.white,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            prefixIcon: Icon(
              Icons.search_rounded,
              color: appColors.mutedText,
            ),
            hintText: 'Search area or junction...',
            hintStyle: TextStyle(
              color: appColors.mutedText,
              fontSize: 14,
            ),
            contentPadding: EdgeInsets.symmetric(
              vertical: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(HotspotsState state) {
    final filters = [
      (
        HotspotFilter.all,
        'All',
      ),
      (
        HotspotFilter.highRisk,
        'High risk',
      ),
      (
        HotspotFilter.fatalOnly,
        'Fatal-only',
      ),
      (
        HotspotFilter.byArea,
        'By area',
      ),
    ];

    return SizedBox(
      height: 54,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final selected = state.filter == filter.$1;

          return GestureDetector(
            onTap: () {
              ref
                  .read(hotspotsViewModelProvider.notifier)
                  .applyFilter(filter.$1);
            },
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? appColors.amber
                    : appColors.navyCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? appColors.amber
                      : appColors.navyLight,
                ),
              ),
              child: Text(
                filter.$2,
                style: TextStyle(
                  color: selected
                      ? appColors.navyDark
                      : appColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDangerZonePanel(HotspotsState state) {
    final subCities = [
      'Bole',
      'Yeka',
      'Kirkos',
      'Arada',
      'Gullele',
      'Lideta',
      'Nifas Silk-Lafto',
      'Kolfe Keranio',
      'Akaki Kality',
      'Addis Ketema',
      'Lemi Kura',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: appColors.navyCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: appColors.navyLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.map_rounded,
                  color: appColors.amber,
                  size: 21,
                ),
                SizedBox(width: 8),
                Text(
                  'Addis danger zones',
                  style: TextStyle(
                    color: appColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              'Risk intensity by available area data',
              style: TextStyle(
                color: appColors.mutedText,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: appColors.navyDark,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: subCities.map((city) {
                  final intensity = _subCityIntensity(
                    city,
                    state.list,
                  );

                  return _ZoneChip(
                    name: city,
                    intensity: intensity,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _LegendDot(
                  color: appColors.green,
                  label: 'Lower',
                ),
                const SizedBox(width: 14),
                _LegendDot(
                  color: appColors.amber,
                  label: 'Medium',
                ),
                const SizedBox(width: 14),
                _LegendDot(
                  color: appColors.red,
                  label: 'Higher',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Zones are based on categorical area data; no GPS locations are assumed.',
              style: TextStyle(
                color: appColors.mutedText,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _subCityIntensity(
    String city,
    List<Hotspot> hotspots,
  ) {
    final matching = hotspots.where((hotspot) {
      final area = hotspot.area.toLowerCase();
      final cityName = city.toLowerCase();

      return area.contains(cityName);
    }).toList();

    if (matching.isEmpty) {
      return 0;
    }

    final totalRisk = matching.fold<double>(
      0,
      (sum, hotspot) => sum + hotspot.riskScore,
    );

    return totalRisk / matching.length;
  }

  void _showHotspotDetails(
    BuildContext context,
    Hotspot hotspot,
  ) {
    final vm = ref.read(hotspotsViewModelProvider.notifier);
    final riskBand = vm.riskBand(hotspot);

    showModalBottomSheet(
      context: context,
      backgroundColor: appColors.navyCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              22,
              12,
              22,
              28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: appColors.navyLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            hotspot.area,
                            style: TextStyle(
                              color: appColors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hotspot.junctionType,
                            style: TextStyle(
                              color: appColors.mutedText,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _RiskChip(
                      score: hotspot.riskScore,
                      band: riskBand,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Accident severity',
                  style: TextStyle(
                    color: appColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 15),
                _BreakdownBar(
                  label: 'Fatal',
                  value: hotspot.fatalities,
                  total: hotspot.accidents,
                  color: appColors.red,
                ),
                const SizedBox(height: 12),
                _BreakdownBar(
                  label: 'Serious',
                  value: hotspot.serious,
                  total: hotspot.accidents,
                  color: appColors.amber,
                ),
                const SizedBox(height: 12),
                _BreakdownBar(
                  label: 'Slight',
                  value: hotspot.slight,
                  total: hotspot.accidents,
                  color: appColors.green,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: appColors.navyDark,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _DetailRow(
                        label: 'Total accidents',
                        value: '${hotspot.accidents}',
                      ),
                      _DetailRow(
                        label: 'Fatalities',
                        value: '${hotspot.fatalities}',
                      ),
                      _DetailRow(
                        label: 'Peak hour',
                        value:
                            '${hotspot.peakHour.toString().padLeft(2, '0')}:00',
                      ),
                      _DetailRow(
                        label: 'Risk score',
                        value:
                            hotspot.riskScore.toStringAsFixed(1),
                        last: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Safety tips',
                  style: TextStyle(
                    color: appColors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                const _SafetyTip(
                  icon: Icons.speed_rounded,
                  text:
                      'Reduce speed when approaching this risk profile.',
                ),
                const _SafetyTip(
                  icon: Icons.visibility_rounded,
                  text:
                      'Stay alert and watch for pedestrians, vehicles and unexpected movements.',
                ),
                const _SafetyTip(
                  icon: Icons.access_time_rounded,
                  text:
                      'Take extra care around the recorded peak hour.',
                ),
                const _SafetyTip(
                  icon: Icons.directions_car_rounded,
                  text:
                      'Keep a safe following distance and avoid distracted driving.',
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((item) => item.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'U';
    }

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _formatNumber(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }

    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }

    return value.toString();
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: appColors.navyCard,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: appColors.navyLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: appColors.mutedText,
            size: 17,
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: TextStyle(
              color: appColors.amber,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: appColors.mutedText,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeAction extends StatelessWidget {
  const _HomeAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: appColors.navyCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: appColors.navyLight),
        ),
        child: Row(
          children: [
            const SizedBox(width: 2),
            Icon(icon, color: appColors.amber),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: appColors.white, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: appColors.mutedText, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HotspotCard extends StatelessWidget {
  const _HotspotCard({
    required this.hotspot,
    required this.rank,
    required this.maxRisk,
    required this.riskBand,
    required this.onTap,
  });

  final Hotspot hotspot;
  final int rank;
  final double maxRisk;
  final String riskBand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = maxRisk <= 0
        ? 0.0
        : (hotspot.riskScore / maxRisk).clamp(0.0, 1.0);

    return Material(
      color: appColors.navyCard,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 35,
                    height: 35,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: rank <= 3
                          ? appColors.amber
                          : appColors.navyLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        color: rank <= 3
                            ? appColors.navyDark
                            : appColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          hotspot.area,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: appColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          hotspot.junctionType,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: appColors.mutedText,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _RiskChip(
                    score: hotspot.riskScore,
                    band: riskBand,
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${hotspot.accidents} accidents · '
                  '${hotspot.fatalities} fatal · '
                  'Peak ${hotspot.peakHour.toString().padLeft(2, '0')}:00',
                  style: TextStyle(
                    color: appColors.mutedText,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 11),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: appColors.navyLight,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(
                    _riskColor(riskBand),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RiskChip extends StatelessWidget {
  const _RiskChip({
    required this.score,
    required this.band,
  });

  final double score;
  final String band;

  @override
  Widget build(BuildContext context) {
    final color = _riskColor(band);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Text(
            score.toStringAsFixed(1),
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            band,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownBar extends StatelessWidget {
  const _BreakdownBar({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  final String label;
  final int value;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final percentage =
        total <= 0 ? 0.0 : (value / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: appColors.mutedText,
                  fontSize: 12,
                ),
              ),
            ),
            Text(
              '$value',
              style: TextStyle(
                color: appColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 7,
            backgroundColor: appColors.navyLight,
            valueColor:
                AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.last = false,
  });

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(
                  color: appColors.navyLight,
                ),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: appColors.mutedText,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: appColors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyTip extends StatelessWidget {
  const _SafetyTip({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: appColors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              color: appColors.amber,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: appColors.mutedText,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoneChip extends StatelessWidget {
  const _ZoneChip({
    required this.name,
    required this.intensity,
  });

  final String name;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final color = _zoneColor(intensity);

    return Container(
      constraints: const BoxConstraints(
        minHeight: 42,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(
              color: appColors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: appColors.mutedText,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? appColors.amber
        : appColors.mutedText;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: active
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 15),
        Row(
          children: [
            const _ShimmerBox(
              width: 44,
              height: 44,
              radius: 13,
            ),
            const SizedBox(width: 12),
            const _ShimmerBox(
              width: 120,
              height: 20,
            ),
          ],
        ),
        const SizedBox(height: 30),
        const _ShimmerBox(
          width: 210,
          height: 27,
        ),
        const SizedBox(height: 9),
        const _ShimmerBox(
          width: 180,
          height: 14,
        ),
        const SizedBox(height: 25),
        Row(
          children: [
            const Expanded(
              child: _ShimmerBox(
                width: double.infinity,
                height: 90,
                radius: 15,
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: _ShimmerBox(
                width: double.infinity,
                height: 90,
                radius: 15,
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: _ShimmerBox(
                width: double.infinity,
                height: 90,
                radius: 15,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _ShimmerBox(
          width: double.infinity,
          height: 52,
          radius: 15,
        ),
        const SizedBox(height: 22),
        const _ShimmerBox(
          width: double.infinity,
          height: 190,
          radius: 20,
        ),
        const SizedBox(height: 22),
        const _ShimmerBox(
          width: double.infinity,
          height: 150,
          radius: 18,
        ),
        const SizedBox(height: 12),
        const _ShimmerBox(
          width: double.infinity,
          height: 150,
          radius: 18,
        ),
      ],
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    this.radius = 10,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = 0.5 + (_controller.value * 0.2);

        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: appColors.navyLight.withValues(
              alpha: value,
            ),
            borderRadius: BorderRadius.circular(
              widget.radius,
            ),
          ),
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: appColors.red.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                color: appColors.red,
                size: 34,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Unable to load hotspots',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: appColors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: appColors.mutedText,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: appColors.amber,
                foregroundColor: appColors.navyDark,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _riskColor(String band) {
  switch (band) {
    case 'High':
      return appColors.red;
    case 'Low':
      return appColors.green;
    default:
      return appColors.amber;
  }
}

Color _zoneColor(double intensity) {
  if (intensity <= 0) {
    return appColors.navyLight;
  }

  if (intensity < 100) {
    return appColors.green;
  }

  if (intensity < 500) {
    return appColors.amber;
  }

  return appColors.red;
}