import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../localization/app_language.dart';
import '../models/local_data.dart';
import '../services/local_store.dart';
import '../widgets/app_ui.dart';

class JobFormScreen extends StatefulWidget {
  const JobFormScreen({super.key, this.id, this.workerId});
  final String? id, workerId;
  @override
  State<JobFormScreen> createState() => _JobFormScreenState();
}

class _JobFormScreenState extends State<JobFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _phone = TextEditingController(),
      _address = TextEditingController();
  final _amount = TextEditingController(text: '0'),
      _notes = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(hours: 1));
  String _service = 'Plumber';
  String? _contactId;
  late AccountRole _role;
  JobStatus _status = JobStatus.planned;
  bool _busy = false, _missing = false;
  @override
  void initState() {
    super.initState();
    final store = context.read<LocalStore>();
    _role = store.profile!.role;
    _date = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _date.hour,
      _date.minute < 30 ? 30 : 0,
    ).add(_date.minute >= 30 ? const Duration(hours: 1) : Duration.zero);
    final j = widget.id == null ? null : store.job(widget.id!);
    _missing = widget.id != null && j == null;
    if (j != null) {
      _name.text = j.personName;
      _phone.text = j.phone;
      _address.text = j.address;
      _amount.text = j.amount.toString();
      _notes.text = j.notes;
      _date = j.scheduledAt;
      _service = j.service;
      _status = j.status;
      _role = j.role;
      _contactId = j.contactId;
    } else if (widget.workerId != null) {
      final worker = store.worker(widget.workerId!);
      if (worker != null) _chooseWorker(worker);
    } else if (_role == AccountRole.worker) {
      _service = store.profile!.profession;
    }
  }

  void _chooseWorker(WorkerContact w) {
    _contactId = w.id;
    _name.text = w.name;
    _phone.text = w.phone;
    _service = w.category;
    _amount.text = w.rate.toString();
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _address, _amount, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final first = _date.isBefore(today) ? DateUtils.dateOnly(_date) : today;
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: first,
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked != null && mounted) {
      setState(
        () => _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _date.hour,
          _date.minute,
        ),
      );
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (picked != null && mounted) {
      setState(
        () => _date = DateTime(
          _date.year,
          _date.month,
          _date.day,
          picked.hour,
          picked.minute,
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final id = widget.id ?? const Uuid().v4();
      await context.read<LocalStore>().saveJob(
        JobRecord(
          id: id,
          role: _role,
          service: _service,
          personName: _name.text.trim(),
          phone: cleanPhone(_phone.text),
          contactId: _contactId,
          scheduledAt: _date,
          address: _address.text.trim(),
          amount: int.parse(_amount.text.trim()),
          notes: _notes.text.trim(),
          status: _status,
        ),
      );
      if (mounted) {
        showMessage(context, 'Job saved on your phone.');
        context.go('/jobs/$id');
      }
    } catch (e) {
      if (mounted) showMessage(context, localError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workers = context.watch<LocalStore>().workers;
    return AppPage(
      title: widget.id == null ? 'Add job' : 'Edit job',
      navigation: false,
      child: _missing
          ? const EmptyState(
              title: 'Job not found',
              message: 'This job record was removed.',
            )
          : Form(
              key: _form,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const InfoCard(
                    'This saves an appointment on your phone. Contact the other person to agree on it.',
                  ),
                  const SizedBox(height: 20),
                  if (_role == AccountRole.customer && workers.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      initialValue: workers.any((w) => w.id == _contactId)
                          ? _contactId
                          : '',
                      decoration: localizedDecoration(
                        context,
                        labelText: 'Saved worker',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: LocalizedText('Enter details'),
                        ),
                        ...workers.map(
                          (w) => DropdownMenuItem(
                            value: w.id,
                            child: Text(
                              w.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: _busy
                          ? null
                          : (id) => setState(() {
                              if (id == '') {
                                _contactId = null;
                              } else {
                                _chooseWorker(
                                  workers.firstWhere((w) => w.id == id),
                                );
                              }
                            }),
                    ),
                    const SizedBox(height: 20),
                  ],
                  formField(
                    context,
                    _name,
                    _role == AccountRole.worker ? 'Client name' : 'Worker name',
                    validator: requiredText,
                  ),
                  formField(
                    context,
                    _phone,
                    'Phone number (optional)',
                    keyboard: TextInputType.phone,
                    maxLength: 30,
                    validator: (value) => phoneValidator(value, optional: true),
                  ),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_service),
                    initialValue: _service,
                    decoration: localizedDecoration(
                      context,
                      labelText: 'Service',
                    ),
                    items: serviceCategories
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: LocalizedText(s),
                          ),
                        )
                        .toList(),
                    onChanged: _busy
                        ? null
                        : (s) => setState(() => _service = s!),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _pickDate,
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(jobDate(context, _date)),
                      ),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _pickTime,
                        icon: const Icon(Icons.schedule),
                        label: Text(jobTime(context, _date)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  formField(
                    context,
                    _address,
                    'Work address',
                    validator: requiredText,
                    lines: 2,
                    maxLength: 300,
                  ),
                  formField(
                    context,
                    _amount,
                    'Agreed amount (Rs.)',
                    keyboard: TextInputType.number,
                    validator: amountValidator,
                    maxLength: 7,
                  ),
                  const LocalizedText(
                    'Use 0 when the price needs to be agreed.',
                  ),
                  const SizedBox(height: 16),
                  formField(
                    context,
                    _notes,
                    'Job notes',
                    lines: 4,
                    maxLength: 2000,
                  ),
                  ElevatedButton(
                    onPressed: _busy ? null : _save,
                    child: LocalizedText(_busy ? 'Saving…' : 'Save job'),
                  ),
                ],
              ),
            ),
    );
  }
}
