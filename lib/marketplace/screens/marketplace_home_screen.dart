import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../widgets/app_ui.dart';
import '../models/marketplace_models.dart';
import '../services/marketplace_controller.dart';
import '../widgets/marketplace_ui.dart';

class MarketplaceHomeScreen extends StatefulWidget {
  const MarketplaceHomeScreen({super.key});

  @override
  State<MarketplaceHomeScreen> createState() => _MarketplaceHomeScreenState();
}

class _MarketplaceHomeScreenState extends State<MarketplaceHomeScreen> {
  final _query = TextEditingController();
  Timer? _debounce;
  String? _category, _professionId, _skillId;
  double _radius = 15, _rating = 0;
  double? _minPrice, _maxPrice;
  int _experience = 0;
  bool _available = false;
  String _sort = 'distance';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _search();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() => context.read<MarketplaceController>().searchWorkers(
    filters: WorkerSearch(
      query: _query.text.trim(),
      professionId: _professionId,
      skillId: _skillId,
      radiusKm: _radius,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      minRating: _rating,
      minExperience: _experience,
      availableOnly: _available,
      sort: _sort,
    ),
  );

  Future<void> _location() async {
    final controller = context.read<MarketplaceController>();
    final city = TextEditingController(text: controller.location?.city ?? '');
    final neighbourhood = TextEditingController(
      text: controller.location?.neighbourhood ?? '',
    );
    final form = GlobalKey<FormState>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          24 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const MarketplaceHeading(
                  'Where do you need help?',
                  subtitle:
                      'Device location finds workers within your search radius. '
                      'You can also browse a city without sharing your location.',
                ),
                FilledButton.icon(
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    await controller.useDeviceLocation();
                    if (mounted) await _search();
                  },
                  icon: const Icon(Icons.my_location),
                  label: const Text('Use my current location'),
                ),
                const SizedBox(height: 22),
                marketplaceField(city, 'City', validator: marketplaceRequired),
                marketplaceField(neighbourhood, 'Neighbourhood (optional)'),
                OutlinedButton(
                  onPressed: () async {
                    if (!form.currentState!.validate()) return;
                    Navigator.pop(sheetContext);
                    await controller.setManualLocation(
                      city.text.trim(),
                      neighbourhood.text.trim(),
                    );
                    if (mounted) await _search();
                  },
                  child: const Text('Search this area'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    // The sheet can still animate while its fields are mounted.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    city.dispose();
    neighbourhood.dispose();
  }

  Future<void> _filters() async {
    var radius = _radius;
    var rating = _rating;
    var experience = _experience;
    var available = _available;
    var sort = _sort;
    final min = TextEditingController(text: _minPrice?.toStringAsFixed(0) ?? '');
    final max = TextEditingController(text: _maxPrice?.toStringAsFixed(0) ?? '');
    final form = GlobalKey<FormState>();
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, update) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            24 + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const MarketplaceHeading('Find the right worker'),
                  Text('Search radius: ${radius.toStringAsFixed(0)} km'),
                  Slider(
                    value: radius,
                    min: 1,
                    max: 100,
                    divisions: 99,
                    onChanged: (v) => update(() => radius = v),
                  ),
                  const Text(
                    'A distance and radius are available with device coordinates. '
                    'Manual location searches match the selected city and neighbourhood.',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: sort,
                    decoration: const InputDecoration(labelText: 'Sort workers'),
                    items: const [
                      DropdownMenuItem(value: 'distance', child: Text('Nearest')),
                      DropdownMenuItem(value: 'rating', child: Text('Highest rated')),
                      DropdownMenuItem(value: 'price', child: Text('Lowest starting price')),
                      DropdownMenuItem(value: 'experience', child: Text('Most experienced')),
                    ],
                    onChanged: (v) => update(() => sort = v!),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: marketplaceField(
                          min,
                          'Min price (PKR)',
                          keyboard: TextInputType.number,
                          validator: (v) => v!.trim().isEmpty
                              ? null
                              : nonNegativeNumber(v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: marketplaceField(
                          max,
                          'Max price (PKR)',
                          keyboard: TextInputType.number,
                          validator: (v) {
                            if (v!.trim().isEmpty) return null;
                            final error = nonNegativeNumber(v);
                            if (error != null) return error;
                            if (double.parse(v) < (double.tryParse(min.text) ?? 0)) {
                              return 'Maximum must be at least the minimum.';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const Text('Compare prices with the same pricing unit on worker profiles.'),
                  const SizedBox(height: 16),
                  Text('Minimum rating: ${rating == 0 ? 'Any' : rating.toStringAsFixed(1)}'),
                  Slider(
                    value: rating,
                    min: 0,
                    max: 5,
                    divisions: 10,
                    onChanged: (v) => update(() => rating = v),
                  ),
                  Text('Minimum experience: $experience years'),
                  Slider(
                    value: experience.toDouble(),
                    min: 0,
                    max: 30,
                    divisions: 30,
                    onChanged: (v) => update(() => experience = v.round()),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Available now only'),
                    subtitle: const Text('Requires a recent availability update.'),
                    value: available,
                    onChanged: (v) => update(() => available = v),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      if (form.currentState!.validate()) Navigator.pop(sheetContext, true);
                    },
                    child: const Text('Apply filters'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (applied == true && mounted) {
      setState(() {
        _radius = radius;
        _rating = rating;
        _experience = experience;
        _available = available;
        _sort = sort;
        _minPrice = double.tryParse(min.text.trim());
        _maxPrice = double.tryParse(max.text.trim());
      });
      await _search();
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    min.dispose();
    max.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MarketplaceController>();
    final categories = controller.professions.map((p) => p.category).toSet().toList();
    final professions = controller.professions
        .where((p) => _category == null || p.category == _category)
        .toList();
    final selected = controller.professions.where((p) => p.id == _professionId).firstOrNull;
    final location = controller.location;
    final permission = controller.locationPermission.name;
    return MarketplacePage(
      title: 'Khidmat · خدمت',
      actions: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: () => context.push('/marketplace/notifications'),
          icon: Badge(
            isLabelVisible: controller.notifications.any((n) => !n.isRead),
            child: const Icon(Icons.notifications_outlined),
          ),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: _search,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Good work. Close to home.', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 10),
                  const Text('Find skilled people for your home, your workplace and your next project.'),
                  const SizedBox(height: 18),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.location_on_outlined, color: AppColors.primaryLight),
                    title: Text(location == null
                        ? 'Choose your search location'
                        : [location.neighbourhood, location.city].where((s) => s.isNotEmpty).join(', ')),
                    subtitle: Text(location?.isDevice == true
                        ? 'Device location · ${_radius.toStringAsFixed(0)} km radius'
                        : 'Manual area · distances are not shown'),
                    trailing: const Icon(Icons.expand_more),
                    onTap: _location,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!controller.configured)
              const MarketplaceNotice(
                message: 'The marketplace is not connected yet. You can explore services; '
                    'live workers, verified sign-in and job requests will become available after setup.',
              ),
            if (permission == 'denied' || permission == 'deniedForever' || permission == 'serviceDisabled')
              MarketplaceNotice(
                message: permission == 'serviceDisabled'
                    ? 'Location services are switched off. You can choose a city or enable device location.'
                    : 'Device location is not shared. You can still choose a city and neighbourhood.',
                action: 'Choose location or retry',
                onAction: _location,
              ),
            if (controller.error != null)
              MarketplaceNotice(message: controller.error!, error: true),
            TextField(
              controller: _query,
              decoration: InputDecoration(
                hintText: 'Search profession, service or skill',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Search filters',
                  onPressed: _filters,
                  icon: const Icon(Icons.tune),
                ),
              ),
              textInputAction: TextInputAction.search,
              onChanged: (_) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 450), _search);
              },
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 20),
            const MarketplaceHeading('Explore services', subtitle: 'Choose a category, a profession, then a skill.'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All services'),
                  selected: _category == null,
                  onSelected: (_) {
                    setState(() { _category = null; _professionId = null; _skillId = null; });
                    _search();
                  },
                ),
                for (final category in categories)
                  ChoiceChip(
                    avatar: Icon(professionIcon(category), size: 18),
                    label: Text(category),
                    selected: _category == category,
                    onSelected: (_) {
                      setState(() { _category = category; _professionId = null; _skillId = null; });
                      _search();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final profession in professions)
                  FilterChip(
                    label: Text(profession.name),
                    selected: _professionId == profession.id,
                    onSelected: (selected) {
                      setState(() { _professionId = selected ? profession.id : null; _skillId = null; });
                      _search();
                    },
                  ),
              ],
            ),
            if (selected != null && selected.skills.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('${selected.name} specializations', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final skill in selected.skills)
                    ChoiceChip(
                      label: Text(skill.name),
                      selected: _skillId == skill.id,
                      onSelected: (selected) {
                        setState(() => _skillId = selected ? skill.id : null);
                        _search();
                      },
                    ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            MarketplaceHeading(
              location?.isDevice == true ? 'Workers near you' : 'Workers in your area',
              subtitle: _available ? 'Recently available workers' : 'Compare services, availability and starting prices.',
              trailing: IconButton(tooltip: 'Filter workers', onPressed: _filters, icon: const Icon(Icons.tune)),
            ),
            if (controller.busy) const LinearProgressIndicator(),
            if (location == null)
              EmptyState(
                title: 'Start with your area',
                message: 'Choose a city or use your current location to discover local workers.',
                icon: Icons.near_me_outlined,
                action: 'Choose location',
                onAction: _location,
              )
            else if (!controller.busy && controller.workers.isEmpty)
              const EmptyState(
                title: 'No matching workers yet',
                message: 'Try another profession, a wider radius or fewer filters. Only published eligible profiles appear here.',
                icon: Icons.person_search_outlined,
              ),
            ...controller.workers.map((worker) => MarketplaceWorkerCard(worker: worker)),
            if (controller.canLoadMore)
              OutlinedButton(
                onPressed: controller.busy ? null : () => controller.searchWorkers(append: true),
                child: const Text('Load more workers'),
              ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.handyman_outlined),
                title: const Text('Put your skills to work'),
                subtitle: const Text('Create one profile and choose your profession and skills.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/marketplace/worker/edit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MarketplaceWorkerCard extends StatelessWidget {
  const MarketplaceWorkerCard({super.key, required this.worker});
  final MarketplaceWorker worker;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => context.push('/marketplace/workers/${worker.id}'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MarketplacePhoto(name: worker.name, url: worker.avatarUrl),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(worker.name, style: Theme.of(context).textTheme.titleMedium),
                      Text(worker.professionName),
                      const SizedBox(height: 4),
                      Text(
                        worker.distanceKm == null
                            ? [worker.neighbourhood, worker.city].where((s) => s.isNotEmpty).join(', ')
                            : 'About ${worker.distanceKm!.toStringAsFixed(1)} km away · ${worker.city}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                Text(worker.availability.label,
                    style: TextStyle(color: worker.availability == WorkerAvailability.availableNow
                        ? AppColors.success : AppColors.textSecondary)),
                Text('${worker.experienceYears} years experience'),
                Text(worker.reviewCount == 0 ? 'No reviews yet' : '★ ${worker.rating.toStringAsFixed(1)} (${worker.reviewCount})'),
              ],
            ),
            const SizedBox(height: 10),
            Text(worker.rate == 0
                ? 'Price by agreement'
                : 'From PKR ${worker.rate.toStringAsFixed(0)} / ${worker.priceUnit}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    ),
  );
}
