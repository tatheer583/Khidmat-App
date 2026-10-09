import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../localization/app_language.dart';
import '../services/marketplace_controller.dart';
import '../widgets/marketplace_ui.dart';

class MarketplaceHomeScreen extends StatefulWidget {
  const MarketplaceHomeScreen({super.key, this.professionId, this.skillId});
  final String? professionId, skillId;

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
    _professionId = widget.professionId;
    _skillId = widget.skillId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _search();
    });
  }

  @override
  void didUpdateWidget(covariant MarketplaceHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.professionId != widget.professionId ||
        oldWidget.skillId != widget.skillId) {
      _professionId = widget.professionId;
      _skillId = widget.skillId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _search();
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    await context.read<MarketplaceController>().searchWorkers(
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
  }

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
                    final selected = await controller.useDeviceLocation();
                    if (mounted && selected) await _search();
                  },
                  icon: const Icon(Icons.my_location),
                  label: const LocalizedText('Use my current location'),
                ),
                if (controller.locationPermission ==
                    LocationAccess.deniedForever)
                  TextButton(
                    onPressed: controller.openLocationSettings,
                    child: const LocalizedText('Open app location settings'),
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
                  child: const LocalizedText('Search this area'),
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
    final min = TextEditingController(
      text: _minPrice?.toStringAsFixed(0) ?? '',
    );
    final max = TextEditingController(
      text: _maxPrice?.toStringAsFixed(0) ?? '',
    );
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
                  LocalizedText(
                    'Search radius: ${radius.toStringAsFixed(0)} km',
                  ),
                  Slider(
                    value: radius,
                    min: 1,
                    max: 100,
                    divisions: 99,
                    onChanged: (v) => update(() => radius = v),
                  ),
                  const LocalizedText(
                    'A distance and radius are available with device coordinates. '
                    'Manual location searches match the selected city and neighbourhood.',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: sort,
                    decoration: const InputDecoration(
                      labelText: 'Sort workers',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'distance',
                        child: LocalizedText('Nearest'),
                      ),
                      DropdownMenuItem(
                        value: 'rating',
                        child: LocalizedText('Highest rated'),
                      ),
                      DropdownMenuItem(
                        value: 'price',
                        child: LocalizedText('Lowest starting price'),
                      ),
                      DropdownMenuItem(
                        value: 'experience',
                        child: LocalizedText('Most experienced'),
                      ),
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
                          validator: (v) =>
                              v!.trim().isEmpty ? null : nonNegativeNumber(v),
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
                            if (double.parse(v) <
                                (double.tryParse(min.text) ?? 0)) {
                              return 'Maximum must be at least the minimum.';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const LocalizedText(
                    'Compare prices with the same pricing unit on worker profiles.',
                  ),
                  const SizedBox(height: 16),
                  LocalizedText(
                    'Minimum rating: ${rating == 0 ? 'Any' : rating.toStringAsFixed(1)}',
                  ),
                  Slider(
                    value: rating,
                    min: 0,
                    max: 5,
                    divisions: 10,
                    onChanged: (v) => update(() => rating = v),
                  ),
                  LocalizedText('Minimum experience: $experience years'),
                  Slider(
                    value: experience.toDouble(),
                    min: 0,
                    max: 30,
                    divisions: 30,
                    onChanged: (v) => update(() => experience = v.round()),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const LocalizedText('Available now only'),
                    subtitle: const LocalizedText(
                      'Requires a recent availability update.',
                    ),
                    value: available,
                    onChanged: (v) => update(() => available = v),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      if (form.currentState!.validate()) {
                        Navigator.pop(sheetContext, true);
                      }
                    },
                    child: const LocalizedText('Apply filters'),
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
    final selected = controller.professions
        .where((p) => p.id == _professionId)
        .firstOrNull;
    final catalog = controller.filterProfessions(
      query: _query.text,
      category: _category,
    );
    const preferred = [
      'Electrician',
      'Plumber',
      'Painter',
      'AC Technician',
      'Mazdoor',
      'Carpenter',
    ];
    final everyday = [...controller.professions]
      ..sort((a, b) {
        final ai = preferred.indexOf(a.name), bi = preferred.indexOf(b.name);
        return (ai < 0 ? 99 : ai).compareTo(bi < 0 ? 99 : bi);
      });
    final searching = selected != null || _query.text.trim().isNotEmpty;
    final denied = [
      LocationAccess.denied,
      LocationAccess.deniedForever,
      LocationAccess.serviceDisabled,
    ].contains(controller.locationPermission);
    return MarketplacePage(
      title: 'Khidmat',
      actions: [
        IconButton(
          tooltip: context.tr('Private organizer'),
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.folder_outlined),
        ),
        IconButton(
          tooltip: context.tr('Notifications'),
          onPressed: () => context.push('/marketplace/notifications'),
          icon: Badge(
            isLabelVisible: controller.unreadCount > 0,
            child: const Icon(Icons.notifications_none_rounded),
          ),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: () async {
          if (controller.configured) await controller.reloadCatalog();
          await _search();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            _locationTile(controller),
            const SizedBox(height: 16),
            const _MarketplaceHero(),
            const SizedBox(height: 20),
            TextField(
              controller: _query,
              maxLength: 120,
              decoration: InputDecoration(
                hintText: context.tr('Search profession, service or skill'),
                counterText: '',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  tooltip: context.tr('Search filters'),
                  onPressed: _filters,
                  icon: const Icon(Icons.tune_rounded),
                ),
              ),
              textInputAction: TextInputAction.search,
              onChanged: (_) {
                setState(() {});
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 400), _search);
              },
              onSubmitted: (_) => _search(),
            ),
            if (controller.profile != null &&
                !controller.profile!.isActive) ...[
              const SizedBox(height: 16),
              MarketplaceNotice(
                message:
                    'Your account is restricted. You can browse services, but marketplace actions are unavailable.',
                error: true,
                action: 'View account status',
                onAction: () => context.go('/marketplace/account'),
              ),
            ],
            if (denied) ...[
              const SizedBox(height: 16),
              MarketplaceNotice(
                message:
                    controller.locationPermission ==
                        LocationAccess.serviceDisabled
                    ? 'Location services are switched off. You can choose a city or enable device location.'
                    : 'Device location is not shared. You can still choose a city and neighbourhood.',
                action: 'Choose location or retry',
                onAction: _location,
              ),
            ],
            if (searching) ...[
              const SizedBox(height: 18),
              if (selected != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: MarketplacePalette.mint,
                          child: Icon(professionIcon(selected.name)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const LocalizedText(
                                'Looking for',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: MarketplacePalette.muted,
                                ),
                              ),
                              LocalizedText(
                                _skillId ?? selected.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              if (_skillId != null)
                                LocalizedText(
                                  selected.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: MarketplacePalette.muted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: context.tr('Clear selection'),
                          onPressed: () {
                            setState(() {
                              _professionId = null;
                              _skillId = null;
                            });
                            context.go('/marketplace');
                            _search();
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ..._workerResults(controller),
            ],
            MarketplaceHeading(
              _query.text.trim().isEmpty
                  ? 'Everyday services'
                  : 'Services matching your search',
              subtitle: _query.text.trim().isEmpty
                  ? 'Good help for the little fixes and the bigger jobs.'
                  : null,
              trailing: TextButton(
                onPressed: () => context.push('/marketplace/services'),
                child: const LocalizedText('View all'),
              ),
            ),
            if (controller.catalogLoading && controller.professions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (controller.professions.isEmpty && !controller.catalogLoading)
              MarketplaceNotice(
                message:
                    controller.catalogError ??
                    'Services are not available right now. Please try again.',
                action: 'Try again',
                onAction: controller.reloadCatalog,
              )
            else if (catalog.isEmpty)
              MarketplaceNotice(
                message:
                    'No service matches that search. Try a profession such as plumber or electrician.',
                action: 'Clear search',
                onAction: () {
                  _query.clear();
                  setState(() {});
                  _search();
                },
              )
            else if (_query.text.trim().isNotEmpty)
              ...catalog.map(
                (profession) => MarketplaceServiceCard(
                  compact: true,
                  name: profession.name,
                  subtitle: profession.skills
                      .take(2)
                      .map((s) => context.tr(s.name))
                      .join(' · '),
                  asset: serviceImageAsset(profession.name),
                  icon: professionIcon(profession.name),
                  onTap: () =>
                      context.push('/marketplace/services/${profession.id}'),
                ),
              )
            else
              SizedBox(
                height: 192,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: everyday.take(6).length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, index) {
                    final profession = everyday[index];
                    return SizedBox(
                      width: 158,
                      child: MarketplaceServiceCard(
                        name: profession.name,
                        subtitle: profession.skills
                            .take(2)
                            .map((s) => context.tr(s.name))
                            .join(' · '),
                        asset: serviceImageAsset(profession.name),
                        icon: professionIcon(profession.name),
                        onTap: () => context.push(
                          '/marketplace/services/${profession.id}',
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (_query.text.trim().isEmpty) ...[
              const SizedBox(height: 6),
              SizedBox(
                height: 46,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.professionCategories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final category = controller.professionCategories[index];
                    return ActionChip(
                      avatar: Icon(professionIcon(category), size: 16),
                      label: LocalizedText(category),
                      onPressed: () => context.push(
                        Uri(
                          path: '/marketplace/services',
                          queryParameters: {'category': category},
                        ).toString(),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (!searching) ..._workerResults(controller),
            const SizedBox(height: 10),
            const MarketplaceHeading('A little help. A simple process.'),
            const _HowItWorks(),
            const SizedBox(height: 24),
            _WorkerInvitation(controller: controller),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: MarketplacePalette.mint,
                          child: Icon(Icons.book_outlined),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const LocalizedText(
                                'Your contacts. Always with you.',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const LocalizedText(
                                'Keep personal contacts and appointment notes on this phone.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: MarketplacePalette.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/home'),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: const LocalizedText('Private organizer'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: LocalizedText(
                'Made for the way Pakistan works.',
                style: TextStyle(fontSize: 12, color: MarketplacePalette.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationTile(MarketplaceController controller) => InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: _location,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: MarketplacePalette.mint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.location_on_outlined, size: 21),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LocalizedText(
                  'YOUR NEIGHBOURHOOD',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.w700,
                    color: MarketplacePalette.muted,
                  ),
                ),
                const SizedBox(height: 3),
                LocalizedText(
                  controller.location == null
                      ? 'Choose your search location'
                      : controller.location!.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 22),
        ],
      ),
    ),
  );

  List<Widget> _workerResults(MarketplaceController controller) => [
    MarketplaceHeading(
      'Help in your neighbourhood',
      subtitle: controller.location?.isDevice == true
          ? 'Search within ${_radius.toStringAsFixed(0)} km of your location.'
          : 'Choose an area to see who can help.',
      trailing: IconButton(
        tooltip: context.tr('Filter workers'),
        onPressed: _filters,
        icon: const Icon(Icons.tune_rounded),
      ),
    ),
    if (!controller.configured)
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.travel_explore_outlined,
                color: MarketplacePalette.teal,
                size: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LocalizedText(
                      'Explore now. Book when connected.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const LocalizedText(
                      'All services and skills are ready to browse. Live worker search and bookings are not connected yet.',
                      style: TextStyle(
                        fontSize: 13,
                        color: MarketplacePalette.muted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      )
    else if (controller.location == null)
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LocalizedText(
                'Local help starts with your area.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const LocalizedText(
                'Use your current location or choose a city. Your exact position stays private.',
                style: TextStyle(color: MarketplacePalette.muted, fontSize: 13),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _location,
                icon: const Icon(Icons.my_location, size: 18),
                label: const LocalizedText('Choose location'),
              ),
            ],
          ),
        ),
      )
    else ...[
      if (controller.workerSearchLoading) const LinearProgressIndicator(),
      if (controller.workerSearchError != null)
        MarketplaceNotice(
          message: controller.workerSearchError!,
          error: true,
          action: 'Try again',
          onAction: _search,
        ),
      if (!controller.workerSearchLoading &&
          controller.workers.isEmpty &&
          controller.workerSearchError == null)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.person_search_outlined, size: 36),
                const SizedBox(height: 10),
                const LocalizedText(
                  'No matching workers yet',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 7),
                const LocalizedText(
                  'Try another skill, a wider radius or fewer filters.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: MarketplacePalette.muted,
                    fontSize: 13,
                  ),
                ),
                TextButton(
                  onPressed: _filters,
                  child: const LocalizedText('Adjust filters'),
                ),
              ],
            ),
          ),
        ),
      ...controller.workers.map(
        (worker) => MarketplaceWorkerCard(worker: worker),
      ),
      if (controller.canLoadMore)
        OutlinedButton(
          onPressed: controller.workerSearchLoading
              ? null
              : () => controller.searchWorkers(append: true),
          child: const LocalizedText('Load more workers'),
        ),
    ],
  ];
}

class _MarketplaceHero extends StatelessWidget {
  const _MarketplaceHero();
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final wide = box.maxWidth > 600;
      return ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: SizedBox(
          height: wide ? 290 : 220,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const MarketplaceAsset(
                asset: 'assets/images/khidmat-team-hero.png',
                label: 'Pakistani service professionals',
                alignment: Alignment(.35, -.15),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x000C443C), Color(0xF00C443C)],
                  ),
                ),
              ),
              PositionedDirectional(
                start: 20,
                end: 18,
                bottom: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText(
                      'Skilled hands. Better days.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: wide ? 34 : 26,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const LocalizedText(
                      'Find the right help, close to home.',
                      style: TextStyle(fontSize: 12, color: Color(0xFFE8F1EA)),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: MarketplacePalette.deepTeal,
                        minimumSize: const Size(0, 39),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 9,
                        ),
                      ),
                      onPressed: () => context.push('/marketplace/services'),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                      label: const LocalizedText('Explore services'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          for (var index = 0; index < 3; index++) ...[
            if (index > 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: MarketplacePalette.mint,
                  child: Text(
                    (index + 1).toString(),
                    style: const TextStyle(
                      color: MarketplacePalette.teal,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LocalizedText(
                        [
                          'Choose a service',
                          'Find someone nearby',
                          'Agree on the work',
                        ][index],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LocalizedText(
                        [
                          'Pick the profession and skill you need.',
                          'Set your area and compare genuine worker profiles.',
                          'Confirm the task, price and timing before work begins.',
                        ][index],
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: MarketplacePalette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}

class _WorkerInvitation extends StatelessWidget {
  const _WorkerInvitation({required this.controller});
  final MarketplaceController controller;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: MarketplacePalette.deepTeal,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.handyman_outlined,
              color: MarketplacePalette.gold,
              size: 22,
            ),
            SizedBox(width: 8),
            Expanded(
              child: LocalizedText(
                'FOR SKILLED WORKERS',
                style: TextStyle(
                  color: MarketplacePalette.gold,
                  fontSize: 10,
                  letterSpacing: 1.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const LocalizedText(
          'Your skills. Your next opportunity.',
          style: TextStyle(
            fontSize: 24,
            height: 1.2,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        const LocalizedText(
          'Build your profile, set your services and let local customers find your work.',
          style: TextStyle(color: Color(0xFFE2EDE7), fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: MarketplacePalette.gold,
            foregroundColor: MarketplacePalette.deepTeal,
          ),
          onPressed: () => context.push(
            controller.isAuthenticated
                ? '/marketplace/worker/edit'
                : '/marketplace/auth',
          ),
          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          label: const LocalizedText('Offer my services'),
        ),
      ],
    ),
  );
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
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker.name,
                        style: const TextStyle(
                          color: MarketplacePalette.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      LocalizedText(
                        worker.professionName,
                        style: const TextStyle(
                          color: MarketplacePalette.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              worker.currentDistanceKm == null
                  ? worker.serviceArea
                  : context
                        .tr('About {distance} km away')
                        .replaceAll(
                          '{distance}',
                          worker.currentDistanceKm!.toStringAsFixed(1),
                        ),
              style: const TextStyle(
                fontSize: 12,
                color: MarketplacePalette.muted,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                LocalizedText(
                  worker.currentAvailability.label,
                  style: const TextStyle(
                    color: MarketplacePalette.teal,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                LocalizedText(
                  '${worker.experienceYears} years experience',
                  style: const TextStyle(
                    fontSize: 12,
                    color: MarketplacePalette.muted,
                  ),
                ),
                LocalizedText(
                  worker.reviewCount == 0
                      ? 'No reviews yet'
                      : '★ ${worker.rating.toStringAsFixed(1)} (${worker.reviewCount})',
                  style: const TextStyle(
                    fontSize: 12,
                    color: MarketplacePalette.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LocalizedText(
              worker.rate == 0
                  ? 'Price by agreement'
                  : 'From PKR ${worker.rate.toStringAsFixed(0)} / ${context.tr(worker.priceUnit)}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: MarketplacePalette.ink,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
