import '../localization/app_language.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/backend_session.dart';
import '../services/khidmat_repository.dart';
import '../widgets/live_ui.dart';
import 'home_screen.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});
  @override
  State<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _area = TextEditingController();
  final _phone = TextEditingController();
  final _price = TextEditingController();
  final _discountPrice = TextEditingController();
  final _slots = TextEditingController(text: '09:00,12:00,15:00,18:00');
  final _description = TextEditingController();
  final _experience = TextEditingController(text: '0');
  String _category = 'Plumber';
  bool _available = true;
  bool _approved = false;
  bool _exists = false;
  bool _loading = true;
  bool _loadFailed = false;
  bool _busy = false;
  String? _error;
  KhidmatRepository get _repo =>
      KhidmatRepository(context.read<BackendSession>().client);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _loadFailed = false;
    });
    try {
      final data = await _repo.ownProvider();
      if (!mounted) return;
      _exists = data != null;
      if (data != null) {
        _name.text = data['name'] as String;
        _city.text = data['city'] as String;
        _area.text = data['location'] as String;
        _phone.text = data['phone'] as String? ?? '';
        _description.text = data['description'] as String? ?? '';
        _experience.text = (data['experience_years'] ?? 0).toString();
        _price.text = data['price_max'].toString();
        _discountPrice.text = data['price_min'].toString();
        _slots.text = (data['available_slots'] as List).join(',');
        _category = data['category'] as String;
        _available = data['is_available'] as bool;
        _approved = data['is_approved'] as bool;
      } else {
        final profile = context.read<BackendSession>().profile;
        _name.text = profile?['full_name'] as String? ?? '';
        _city.text = profile?['city'] as String? ?? '';
        _description.text = profile?['bio'] as String? ?? '';
        _experience.text = (profile?['experience_years'] ?? 0).toString();
        final profession = profile?['profession'] as String?;
        if (serviceCategories.contains(profession)) _category = profession!;
      }
    } catch (e) {
      if (mounted) {
        _error = describeError(e);
        _loadFailed = true;
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _city,
      _area,
      _phone,
      _price,
      _discountPrice,
      _slots,
      _description,
      _experience,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v) =>
      v == null || v.trim().length < 2 ? 'Fill this field' : null;
  String? _rate(String? v) {
    final amount = int.tryParse(v ?? '');
    return amount == null || amount < 1 || amount > 1000000
        ? 'Enter a valid rupee amount'
        : null;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final price = int.parse(_price.text);
    final discount = int.parse(_discountPrice.text);
    if (discount > price) {
      showMessage(context, 'The booking rate cannot exceed the standard rate.');
      return;
    }
    final slots =
        _slots.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    if (slots.length > 24 ||
        slots.any((s) => !RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(s))) {
      showMessage(
        context,
        'Use up to 24 times in HH:MM format separated by commas.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _repo.saveProvider({
        'name': _name.text.trim(),
        'description': _description.text.trim(),
        'experience_years': int.parse(_experience.text),
        'category': _category,
        'city': _city.text.trim(),
        'location': _area.text.trim(),
        'phone': _phone.text.trim(),
        'price_min': discount,
        'price_max': price,
        'available_slots': slots,
        'is_available': _available,
        'avatar_path': context.read<BackendSession>().profile?['avatar_path'],
      }, exists: _exists);
      if (mounted) {
        showMessage(
          context,
          _exists ? 'Listing updated.' : 'Listing submitted for approval.',
        );
        await _load();
      }
    } catch (e) {
      if (mounted) setState(() => _error = describeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const LocalizedText('Provider dashboard'),
      actions: [
        const LanguageButton(),
        IconButton(
          tooltip: context.tr('My jobs'),
          onPressed: () => context.push('/bookings'),
          icon: const Icon(Icons.work_outline),
        ),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null && _loadFailed
        ? Center(child: Notice(_error!, retry: _load))
        : Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (_exists)
                  Card(
                    child: ListTile(
                      leading: Icon(
                        _approved
                            ? Icons.verified_outlined
                            : Icons.hourglass_top,
                      ),
                      title: LocalizedText(
                        _approved ? 'Listing approved' : 'Approval pending',
                      ),
                      subtitle: LocalizedText(
                        _approved
                            ? 'Customers can find you when available.'
                            : 'The app owner will review your listing before it becomes visible.',
                      ),
                    ),
                  ),
                const LocalizedText(
                  'Set your service details. The booking rate is the price you authorize '
                  'Khidmat to offer customers. Set both prices equal to disable discounts.',
                ),
                const SizedBox(height: 24),
                TextFormField(
                  errorBuilder: (context, error) => LocalizedText(error),
                  controller: _name,
                  maxLength: 100,
                  validator: _required,
                  decoration: localizedDecoration(
                    context,
                    labelText: 'Business or provider name',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: localizedDecoration(
                    context,
                    labelText: 'Service',
                  ),
                  items: serviceCategories
                      .map(
                        (s) =>
                            DropdownMenuItem(value: s, child: LocalizedText(s)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  errorBuilder: (context, error) => LocalizedText(error),
                  controller: _city,
                  maxLength: 80,
                  validator: _required,
                  decoration: localizedDecoration(context, labelText: 'City'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  errorBuilder: (context, error) => LocalizedText(error),
                  controller: _area,
                  maxLength: 300,
                  validator: _required,
                  decoration: localizedDecoration(
                    context,
                    labelText: 'Service area',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  errorBuilder: (context, error) => LocalizedText(error),
                  controller: _description,
                  maxLength: 2000,
                  maxLines: 4,
                  decoration: localizedDecoration(
                    context,
                    labelText: 'About you / work details',
                  ),
                  validator: (value) =>
                      value == null || value.trim().length < 10
                      ? 'Add a short description'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  errorBuilder: (context, error) => LocalizedText(error),
                  controller: _experience,
                  keyboardType: TextInputType.number,
                  decoration: localizedDecoration(
                    context,
                    labelText: 'Working experience (years)',
                  ),
                  validator: (value) {
                    final years = int.tryParse(value ?? '');
                    return years == null || years < 0 || years > 60
                        ? 'Enter experience from 0 to 60 years'
                        : null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  errorBuilder: (context, error) => LocalizedText(error),
                  controller: _phone,
                  maxLength: 30,
                  keyboardType: TextInputType.phone,
                  decoration: localizedDecoration(
                    context,
                    labelText: 'Public business phone (optional)',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  errorBuilder: (context, error) => LocalizedText(error),
                  controller: _price,
                  keyboardType: TextInputType.number,
                  validator: _rate,
                  decoration: localizedDecoration(
                    context,
                    labelText: 'Standard price (Rs.)',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  errorBuilder: (context, error) => LocalizedText(error),
                  controller: _discountPrice,
                  keyboardType: TextInputType.number,
                  validator: _rate,
                  decoration: localizedDecoration(
                    context,
                    labelText: 'Authorized booking rate (Rs.)',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  errorBuilder: (context, error) => LocalizedText(error),
                  controller: _slots,
                  decoration: localizedDecoration(
                    context,
                    labelText: 'Daily times (Pakistan time)',
                    helperText: 'Example: 09:00,12:00,15:00',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const LocalizedText('Available for bookings'),
                  value: _available,
                  onChanged: (v) => setState(() => _available = v),
                ),
                if (_error != null) Notice(_error!),
                ElevatedButton(
                  onPressed: _busy ? null : _save,
                  child: LocalizedText(
                    _busy
                        ? 'Saving…'
                        : _exists
                        ? 'Save listing'
                        : 'Submit listing',
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/bookings'),
                  child: const LocalizedText(
                    'View booking requests & update jobs',
                  ),
                ),
              ],
            ),
          ),
  );
}
