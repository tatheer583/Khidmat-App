import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../localization/app_language.dart';
import '../services/marketplace_controller.dart';
import '../widgets/marketplace_ui.dart';

/// The service directory is useful before an account or connection is available.
/// Every destination is a catalog profession, never a sample worker listing.
class MarketplaceServicesScreen extends StatefulWidget {
  const MarketplaceServicesScreen({super.key, this.category});
  final String? category;

  @override
  State<MarketplaceServicesScreen> createState() =>
      _MarketplaceServicesScreenState();
}

class _MarketplaceServicesScreenState extends State<MarketplaceServicesScreen> {
  final _query = TextEditingController();
  String? _category;

  @override
  void initState() {
    super.initState();
    _category = widget.category;
  }

  @override
  void didUpdateWidget(covariant MarketplaceServicesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category) _category = widget.category;
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MarketplaceController>();
    final professions = controller.filterProfessions(
      query: _query.text,
      category: _category,
    );
    final categories = controller.professionCategories;
    return MarketplacePage(
      title: 'Explore services',
      section: 4,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          const LocalizedText(
            'What can we help with?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -.8,
              color: MarketplacePalette.ink,
            ),
          ),
          const SizedBox(height: 8),
          const LocalizedText(
            'From everyday fixes to bigger projects, find the right skill for the job.',
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _query,
            maxLength: 120,
            decoration: localizedDecoration(
              context,
              hintText: 'Search a service or skill',
              prefixIcon: const Icon(Icons.search_rounded),
              counterText: '',
              suffixIcon: _query.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: context.tr('Clear search'),
                      onPressed: () => setState(_query.clear),
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    label: const LocalizedText('All services'),
                    selected: _category == null,
                    onSelected: (_) => setState(() => _category = null),
                  ),
                ),
                for (final category in categories)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: LocalizedText(category),
                      selected: category == _category,
                      onSelected: (_) => setState(() => _category = category),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          if (controller.catalogLoading) const LinearProgressIndicator(),
          if (professions.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.search_off_rounded, size: 36),
                    const SizedBox(height: 14),
                    const LocalizedText(
                      'No services match this search',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const LocalizedText(
                      'Try another skill or browse all services.',
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() {
                        _query.clear();
                        _category = null;
                      }),
                      child: const LocalizedText('Show all services'),
                    ),
                    if (controller.catalogError != null) ...[
                      MarketplaceNotice(message: controller.catalogError!),
                      TextButton(
                        onPressed: controller.reloadCatalog,
                        child: const LocalizedText('Try again'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          for (final category in categories.where(
            (category) => professions.any((p) => p.category == category),
          )) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(professionIcon(category), size: 19),
                  const SizedBox(width: 9),
                  Expanded(
                    child: LocalizedText(
                      category,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 760
                    ? 3
                    : constraints.maxWidth >= 500
                    ? 2
                    : 1;
                final items = professions
                    .where((p) => p.category == category)
                    .toList();
                if (columns == 1) {
                  return Column(
                    children: [
                      for (final profession in items)
                        MarketplaceServiceCard(
                          name: profession.name,
                          subtitle: profession.skills
                              .take(3)
                              .map((skill) => context.tr(skill.name))
                              .join(' · '),
                          icon: professionIcon(profession.category),
                          asset: serviceImageAsset(profession.name),
                          compact: true,
                          onTap: () => context.go(
                            '/marketplace/services/${profession.id}',
                          ),
                        ),
                    ],
                  );
                }
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisExtent: 225,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 2,
                  ),
                  itemBuilder: (context, index) {
                    final profession = items[index];
                    return MarketplaceServiceCard(
                      name: profession.name,
                      subtitle: profession.skills
                          .take(3)
                          .map((skill) => context.tr(skill.name))
                          .join(' · '),
                      icon: professionIcon(profession.category),
                      asset: serviceImageAsset(profession.name),
                      onTap: () =>
                          context.go('/marketplace/services/${profession.id}'),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 14),
          ],
          Card(
            color: MarketplacePalette.mint,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline_rounded),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: LocalizedText(
                      'Choose a skill to understand the work, then search for workers in your area.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (controller.catalogSource == CatalogSource.bundled)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              child: LocalizedText(
                'Service guide available offline. Worker profiles and bookings need a connection.',
                style: TextStyle(fontSize: 12, color: MarketplacePalette.muted),
              ),
            ),
        ],
      ),
    );
  }
}

class MarketplaceServiceDetailScreen extends StatefulWidget {
  const MarketplaceServiceDetailScreen({
    super.key,
    required this.id,
    this.skillId,
  });
  final String id;
  final String? skillId;

  @override
  State<MarketplaceServiceDetailScreen> createState() =>
      _MarketplaceServiceDetailScreenState();
}

class _MarketplaceServiceDetailScreenState
    extends State<MarketplaceServiceDetailScreen> {
  String? _skill;
  @override
  void initState() {
    super.initState();
    _skill = widget.skillId;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MarketplaceController>();
    final matches = controller.professions.where(
      (profession) => profession.id == widget.id,
    );
    final profession = matches.isEmpty ? null : matches.first;
    if (profession == null) {
      return MarketplacePage(
        title: 'Service details',
        navigation: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.handyman_outlined, size: 48),
                const SizedBox(height: 16),
                const LocalizedText('This service is unavailable'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go('/marketplace/services'),
                  child: const LocalizedText('Explore services'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final validSkill = profession.skills.any((skill) => skill.id == _skill)
        ? _skill
        : null;
    return MarketplacePage(
      title: profession.name,
      navigation: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 230,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MarketplaceAsset(
                    asset: serviceImageAsset(profession.name),
                    icon: professionIcon(profession.category),
                    label: profession.name,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xDD0C443C)],
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    start: 22,
                    end: 22,
                    bottom: 22,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LocalizedText(
                          profession.category,
                          style: const TextStyle(
                            color: Color(0xFFE5F0E9),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LocalizedText(
                          profession.name,
                          style: const TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const LocalizedText(
            'Choose the work you need',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          const LocalizedText(
            'Pick a skill for a more focused worker search, or explore the whole profession.',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              ChoiceChip(
                label: const LocalizedText('All skills'),
                selected: validSkill == null,
                onSelected: (_) => setState(() => _skill = null),
              ),
              for (final skill in profession.skills)
                ChoiceChip(
                  key: ValueKey('service-skill-${skill.id}'),
                  label: LocalizedText(skill.name),
                  selected: validSkill == skill.id,
                  onSelected: (_) => setState(() => _skill = skill.id),
                ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const ValueKey('find-service-workers'),
            onPressed: () => context.go(
              Uri(
                path: '/marketplace',
                queryParameters: {
                  'profession': profession.id,
                  if (validSkill != null) 'skill': validSkill,
                },
              ).toString(),
            ),
            icon: const Icon(Icons.search_rounded),
            label: const LocalizedText('Find workers'),
          ),
          const SizedBox(height: 12),
          if (!controller.configured)
            const LocalizedText(
              'You can explore every service now. Live worker search will be available when the marketplace is connected.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: MarketplacePalette.muted),
            ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.checklist_rounded),
                      SizedBox(width: 10),
                      Expanded(
                        child: LocalizedText(
                          'Before you book',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _BookingTip(
                    number: '01',
                    title: 'Explain the task',
                    message:
                        'Describe the problem, the work needed and your preferred time.',
                  ),
                  const _BookingTip(
                    number: '02',
                    title: 'Agree on the scope',
                    message:
                        'Confirm whether the price includes the visit, labour, materials and any follow-up work.',
                  ),
                  const _BookingTip(
                    number: '03',
                    title: 'Choose with confidence',
                    message:
                        'Compare real profiles, experience and completed-job reviews. Confirm the total price directly with the worker.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => context.go(
              controller.isAuthenticated
                  ? '/marketplace/worker/edit'
                  : '/marketplace/auth',
            ),
            icon: const Icon(Icons.handyman_outlined),
            label: const LocalizedText('I offer this service'),
          ),
          TextButton(
            onPressed: () => context.go('/marketplace/services'),
            child: const LocalizedText('Explore other services'),
          ),
        ],
      ),
    );
  }
}

class _BookingTip extends StatelessWidget {
  const _BookingTip({
    required this.number,
    required this.title,
    required this.message,
  });
  final String number, title, message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 17),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: MarketplacePalette.mint,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: MarketplacePalette.teal,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LocalizedText(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              LocalizedText(
                message,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.6,
                  color: MarketplacePalette.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
