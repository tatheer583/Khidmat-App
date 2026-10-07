import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../localization/app_language.dart';
import '../models/local_data.dart';
import '../services/local_store.dart';
import '../widgets/app_ui.dart';

class WorkerFormScreen extends StatefulWidget {
  const WorkerFormScreen({super.key, this.id});
  final String? id;
  @override
  State<WorkerFormScreen> createState() => _WorkerFormScreenState();
}

class _WorkerFormScreenState extends State<WorkerFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _phone = TextEditingController(),
      _city = TextEditingController();
  final _details = TextEditingController(),
      _years = TextEditingController(text: '0'),
      _rate = TextEditingController(text: '0');
  String _category = 'Plumber';
  bool _favorite = false, _busy = false, _missing = false;
  @override
  void initState() {
    super.initState();
    final store = context.read<LocalStore>();
    final w = widget.id == null ? null : store.worker(widget.id!);
    _missing = widget.id != null && w == null;
    _city.text = w?.city ?? store.profile?.city ?? '';
    if (w != null) {
      _name.text = w.name;
      _phone.text = w.phone;
      _details.text = w.details;
      _years.text = w.experienceYears.toString();
      _rate.text = w.rate.toString();
      _category = w.category;
      _favorite = w.favorite;
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _city, _details, _years, _rate]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final id = widget.id ?? const Uuid().v4();
      await context.read<LocalStore>().saveWorker(
        WorkerContact(
          id: id,
          name: _name.text.trim(),
          phone: cleanPhone(_phone.text),
          category: _category,
          city: _city.text.trim(),
          details: _details.text.trim(),
          experienceYears: int.parse(_years.text.trim()),
          rate: int.parse(_rate.text.trim()),
          favorite: _favorite,
        ),
      );
      if (mounted) {
        showMessage(context, 'Worker contact saved.');
        context.go('/contacts/$id');
      }
    } catch (e) {
      if (mounted) showMessage(context, localError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: widget.id == null ? 'Add worker' : 'Edit worker',
    navigation: false,
    child: _missing
        ? const EmptyState(
            title: 'Contact not found',
            message: 'This worker contact was removed.',
          )
        : Form(
            key: _form,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                formField(
                  context,
                  _name,
                  'Worker name',
                  validator: requiredText,
                ),
                formField(
                  context,
                  _phone,
                  'Phone number',
                  validator: phoneValidator,
                  keyboard: TextInputType.phone,
                  maxLength: 30,
                ),
                DropdownButtonFormField<String>(
                  isExpanded: true,
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
                  onChanged: _busy
                      ? null
                      : (v) => setState(() => _category = v!),
                ),
                const SizedBox(height: 20),
                formField(
                  context,
                  _city,
                  'City',
                  validator: requiredText,
                  maxLength: 80,
                ),
                formField(
                  context,
                  _years,
                  'Working experience (years)',
                  keyboard: TextInputType.number,
                  validator: yearsValidator,
                  maxLength: 2,
                ),
                formField(
                  context,
                  _rate,
                  'Starting rate (Rs.)',
                  keyboard: TextInputType.number,
                  validator: amountValidator,
                  maxLength: 7,
                ),
                const LocalizedText('Use 0 when the price needs to be agreed.'),
                const SizedBox(height: 16),
                formField(
                  context,
                  _details,
                  'Work details / notes',
                  lines: 4,
                  maxLength: 2000,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const LocalizedText('Favorite contact'),
                  value: _favorite,
                  onChanged: _busy
                      ? null
                      : (v) => setState(() => _favorite = v),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _busy ? null : _save,
                  child: LocalizedText(_busy ? 'Saving…' : 'Save worker'),
                ),
              ],
            ),
          ),
  );
}
