import '../localization/app_language.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/backend_session.dart';
import '../widgets/live_ui.dart';

DateTime pakistanToday() {
  final now = DateTime.now().toUtc().add(const Duration(hours: 5));
  return DateTime(now.year, now.month, now.day);
}

class NegotiationScreen extends StatefulWidget {
  const NegotiationScreen({super.key});
  @override
  State<NegotiationScreen> createState() => _NegotiationScreenState();
}

class _NegotiationScreenState extends State<NegotiationScreen> {
  final _form = GlobalKey<FormState>();
  final _address = TextEditingController();
  final _notes = TextEditingController();
  DateTime _day = pakistanToday().add(const Duration(days: 1));
  String? _slot;
  Future<List<String>>? _slots;
  String? _providerId;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = context.watch<AppState>().selectedProvider?.provider.id;
    if (id != null && id != _providerId) {
      _providerId = id;
      _loadSlots();
    }
  }

  void _loadSlots() {
    _slot = null;
    if (_providerId != null) {
      _slots = context.read<AppState>().repository.availableSlots(
        _providerId!,
        _day,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _address.text =
        context.read<BackendSession>().profile?['location'] as String? ?? '';
  }

  @override
  void dispose() {
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _book() async {
    if (!_form.currentState!.validate() || _slot == null) return;
    final booking = await context.read<AppState>().book(
      _day,
      _slot!,
      _address.text,
      _notes.text,
    );
    if (mounted && booking != null) context.go('/booking/${booking.id}');
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final quote = state.negotiationResult;
    final provider = state.selectedProvider?.provider;
    return Scaffold(
      appBar: AppBar(
        actions: const [LanguageButton()],
        title: const LocalizedText('Your booking quote'),
      ),
      body: quote == null || provider == null
          ? Center(
              child: state.error != null
                  ? Notice(
                      state.error!,
                      retry: state.selectedProvider == null
                          ? null
                          : () =>
                                state.startNegotiation(state.selectedProvider!),
                    )
                  : state.isProcessing
                  ? const CircularProgressIndicator()
                  : const Notice('Choose a provider to get a quote.'),
            )
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  LocalizedText(
                    provider.name,
                    translate: false,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  LocalizedText(
                    'Rs. ${quote.finalPrice}',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  if (quote.savings > 0)
                    LocalizedText(
                      'Provider-authorized discount: Rs. ${quote.savings}',
                    ),
                  const SizedBox(height: 12),
                  LocalizedText(quote.explanation),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: state.isProcessing
                        ? null
                        : () async {
                            final day = await showDatePicker(
                              context: context,
                              initialDate: _day,
                              firstDate: pakistanToday(),
                              lastDate: pakistanToday().add(
                                const Duration(days: 90),
                              ),
                            );
                            if (day != null && mounted) {
                              setState(() {
                                _day = day;
                                _loadSlots();
                              });
                            }
                          },
                    icon: const Icon(Icons.calendar_month),
                    label: LocalizedText(
                      _day.toIso8601String().split('T').first,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<String>>(
                    future: _slots,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const LinearProgressIndicator();
                      }
                      if (snapshot.hasError) {
                        return Notice(
                          describeError(snapshot.error!),
                          retry: () => setState(_loadSlots),
                        );
                      }
                      final slots = snapshot.data ?? [];
                      if (slots.isEmpty) {
                        return const Notice(
                          'No times available on this date. Choose another day.',
                        );
                      }
                      return DropdownButtonFormField<String>(
                        key: ValueKey(_slots),
                        initialValue: _slot,
                        decoration: localizedDecoration(
                          context,
                          labelText: 'Appointment time',
                        ),
                        items: slots
                            .map(
                              (slot) => DropdownMenuItem(
                                value: slot,
                                child: LocalizedText('$slot (Pakistan time)'),
                              ),
                            )
                            .toList(),
                        onChanged: state.isProcessing
                            ? null
                            : (value) => setState(() => _slot = value),
                        validator: (v) =>
                            v == null ? context.tr('Choose a time') : null,
                      );
                    },
                  ),
                  TextButton(
                    onPressed: state.isProcessing
                        ? null
                        : () => setState(_loadSlots),
                    child: const LocalizedText('Refresh available times'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    errorBuilder: (context, error) => LocalizedText(error),
                    controller: _address,
                    maxLength: 500,
                    maxLines: 3,
                    decoration: localizedDecoration(
                      context,
                      labelText: 'Full service address',
                    ),
                    validator: (v) => v == null || v.trim().length < 5
                        ? 'Enter your full address'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    errorBuilder: (context, error) => LocalizedText(error),
                    controller: _notes,
                    maxLength: 2000,
                    maxLines: 3,
                    decoration: localizedDecoration(
                      context,
                      labelText: 'Work details and notes',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const LocalizedText(
                    'The provider must accept your request. Payment is cash after completion.',
                  ),
                  if (state.error != null) Notice(state.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: state.isProcessing || _slot == null
                        ? null
                        : _book,
                    child: LocalizedText(
                      state.isProcessing ? 'Reserving…' : 'Request booking',
                    ),
                  ),
                  TextButton(
                    onPressed: state.isProcessing
                        ? null
                        : () => state.startNegotiation(state.selectedProvider!),
                    child: const LocalizedText('Refresh quote'),
                  ),
                ],
              ),
            ),
    );
  }
}
