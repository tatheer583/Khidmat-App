import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../localization/app_language.dart';
import '../../widgets/app_ui.dart';
import '../services/marketplace_controller.dart';
import '../widgets/marketplace_ui.dart';

class MarketplaceWorkerFormScreen extends StatefulWidget {
  const MarketplaceWorkerFormScreen({super.key});

  @override
  State<MarketplaceWorkerFormScreen> createState() =>
      _MarketplaceWorkerFormScreenState();
}

class _MarketplaceWorkerFormScreenState
    extends State<MarketplaceWorkerFormScreen> {
  final _form = GlobalKey<FormState>();
  final _scroll = ScrollController();
  final _name = TextEditingController(), _city = TextEditingController();
  final _area = TextEditingController(), _whatsapp = TextEditingController();
  final _experience = TextEditingController(text: '0'),
      _description = TextEditingController();
  final _languages = TextEditingController(),
      _rate = TextEditingController(text: '0');
  String? _loadedId, _professionId, _avatar;
  final Set<String> _skills = {};
  final Set<int> _days = {1, 2, 3, 4, 5, 6};
  final Map<String, dynamic> _answers = {};
  final List<String> _portfolio = [];
  String _rateUnit = 'day', _start = '08:00', _end = '18:00';
  double _radius = 15;
  int _step = 0;
  bool _shareContact = false, _uploading = false;
  bool _loadedDraft = false;

  @override
  void dispose() {
    _scroll.dispose();
    for (final c in [
      _name,
      _city,
      _area,
      _whatsapp,
      _experience,
      _description,
      _languages,
      _rate,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _goStep(int value) {
    setState(() => _step = value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
    });
  }

  void _populate(MarketplaceController controller) {
    final profile = controller.profile;
    if (profile != null && _loadedId != profile.id) {
      _loadedId = profile.id;
      _name.text = profile.fullName;
      _city.text = profile.city;
      _area.text = profile.neighbourhood;
      _whatsapp.text = profile.whatsapp;
    }
    final draft = controller.ownWorker;
    if (draft == null || _loadedDraft) return;
    _loadedDraft = true;
    _professionId = draft.professionId;
    _skills.addAll(draft.skillIds);
    _experience.text = '${draft.experienceYears}';
    _description.text = draft.description;
    _languages.text = draft.languages.join(', ');
    _rate.text = draft.rate.toStringAsFixed(0);
    _rateUnit = draft.rateUnit;
    _radius = draft.serviceRadiusKm;
    _days
      ..clear()
      ..addAll(draft.workingDays);
    _start = draft.startTime.substring(0, 5);
    _end = draft.endTime.substring(0, 5);
    _answers.addAll(draft.answers);
    _avatar = draft.avatarPath;
    _portfolio.addAll(draft.portfolioPaths);
    _shareContact = draft.shareContact;
  }

  Future<void> _upload({required bool avatar}) async {
    if (_uploading) return;
    final controller = context.read<MarketplaceController>();
    setState(() => _uploading = true);
    try {
      final file = await openFile(
        acceptedTypeGroups: [
          const XTypeGroup(
            label: 'Images',
            extensions: ['jpg', 'jpeg', 'png', 'webp'],
            mimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
            uniformTypeIdentifiers: ['public.image'],
          ),
        ],
      );
      if (file == null) return;
      if (await file.length() > 5 * 1024 * 1024) {
        if (mounted) showMessage(context, 'Choose an image smaller than 5 MB.');
        return;
      }
      final extension = file.name.split('.').last.toLowerCase();
      final mime = switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };
      final url = await controller.uploadImage(
        await file.readAsBytes(),
        file.name,
        mime,
      );
      if (mounted && url != null) {
        setState(() {
          if (avatar) {
            _avatar = url;
          } else {
            _portfolio.add(url);
          }
        });
      }
    } catch (_) {
      if (mounted) {
        showMessage(
          context,
          'The image could not be selected. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _time({required bool opening}) async {
    final text = opening ? _start : _end;
    final parts = text.split(':');
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      ),
    );
    if (selected != null && mounted) {
      final value =
          '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (opening) {
          _start = value;
        } else {
          _end = value;
        }
      });
    }
  }

  WorkerDraft _draft(bool published) => WorkerDraft(
    professionId: _professionId ?? '',
    skillIds: _skills.toList(),
    experienceYears: int.tryParse(_experience.text.trim()) ?? 0,
    description: _description.text.trim(),
    languages: _languages.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList(),
    serviceRadiusKm: _radius,
    rate: double.tryParse(_rate.text.trim()) ?? 0,
    rateUnit: _rateUnit,
    workingDays: _days.toList()..sort(),
    startTime: _start,
    endTime: _end,
    answers: Map.of(_answers),
    avatarPath: _avatar,
    portfolioPaths: List.of(_portfolio),
    published: published,
    shareContact: _shareContact,
  );

  Future<void> _advance() async {
    if (!_form.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (_step == 0) {
      final controller = context.read<MarketplaceController>();
      final saved = await controller.saveAccount(
        fullName: _name.text.trim(),
        city: _city.text.trim(),
        neighbourhood: _area.text.trim(),
        whatsapp: _whatsapp.text.trim(),
        roles: {...?controller.profile?.roles, 'worker'}.toList(),
      );
      if (!saved || !mounted) return;
    }
    if (mounted) _goStep(_step + 1);
  }

  Future<void> _save(bool publish) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final controller = context.read<MarketplaceController>();
    if (marketplaceRequired(_name.text) != null ||
        marketplaceRequired(_city.text) != null ||
        pakistanPhone(_whatsapp.text, optional: true) != null) {
      _goStep(0);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _form.currentState?.validate(),
      );
      return;
    }
    if (_professionId == null) {
      _goStep(1);
      return;
    }
    final accountSaved = await controller.saveAccount(
      fullName: _name.text.trim(),
      city: _city.text.trim(),
      neighbourhood: _area.text.trim(),
      whatsapp: _whatsapp.text.trim(),
      roles: {...?controller.profile?.roles, 'worker'}.toList(),
    );
    if (!accountSaved || !mounted) return;
    final saved = await controller.saveWorker(_draft(publish));
    if (!mounted || !saved) return;
    showMessage(
      context,
      publish
          ? 'Your professional profile is published.'
          : 'Worker draft saved.',
    );
  }

  Widget _question(ProfessionQuestion question) {
    String? validate(dynamic value) {
      try {
        question.validate(value);
        return null;
      } on FormatException catch (error) {
        return context.tr(error.message);
      }
    }

    final label =
        '${context.tr(question.label)}${question.required ? ' *' : ''}';
    if (question.type == 'boolean' || question.type == 'bool') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: DropdownButtonFormField<bool>(
          key: ValueKey('$_professionId-${question.id}'),
          initialValue: _answers[question.id] as bool?,
          isExpanded: true,
          decoration: InputDecoration(labelText: context.tr(label)),
          items: const [
            DropdownMenuItem(value: true, child: LocalizedText('Yes')),
            DropdownMenuItem(value: false, child: LocalizedText('No')),
          ],
          validator: validate,
          onChanged: (value) => setState(() => _answers[question.id] = value),
        ),
      );
    }
    if (question.type == 'select') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: DropdownButtonFormField<String>(
          key: ValueKey('$_professionId-${question.id}'),
          initialValue: question.options.contains(_answers[question.id])
              ? _answers[question.id] as String?
              : null,
          isExpanded: true,
          decoration: InputDecoration(labelText: context.tr(label)),
          items: question.options
              .map((o) => DropdownMenuItem(value: o, child: LocalizedText(o)))
              .toList(),
          validator: validate,
          onChanged: (value) => setState(() => _answers[question.id] = value),
        ),
      );
    }
    if (question.type == 'multiselect' || question.type == 'multi_select') {
      return FormField<List<String>>(
        key: ValueKey('$_professionId-${question.id}'),
        initialValue:
            (_answers[question.id] as List?)?.whereType<String>().toList() ??
            [],
        validator: validate,
        builder: (field) => Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LocalizedText(label),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final option in question.options)
                    FilterChip(
                      label: LocalizedText(option),
                      selected: field.value!.contains(option),
                      onSelected: (selected) {
                        final values = {...field.value!};
                        selected ? values.add(option) : values.remove(option);
                        field.didChange(values.toList());
                        _answers[question.id] = values.toList();
                      },
                    ),
                ],
              ),
              if (field.hasError)
                Text(
                  field.errorText!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        key: ValueKey('$_professionId-${question.id}'),
        initialValue: _answers[question.id]?.toString() ?? '',
        decoration: InputDecoration(labelText: context.tr(label)),
        maxLength: question.type == 'number' ? 10 : 1000,
        keyboardType: question.type == 'number'
            ? TextInputType.number
            : TextInputType.text,
        validator: validate,
        onChanged: (value) => _answers[question.id] = question.type == 'number'
            ? (num.tryParse(value) ?? value)
            : value,
      ),
    );
  }

  List<Widget> _stepContent(
    MarketplaceController controller,
    Profession? profession,
  ) => switch (_step) {
    0 => [
      const MarketplaceHeading(
        'First, introduce yourself',
        subtitle:
            'Your account is already created. You can save a draft before publishing your services.',
      ),
      marketplaceField(_name, 'Full name', validator: marketplaceRequired),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.verified_user_outlined),
        title: Text(
          controller.profile?.phone ?? '',
          textDirection: TextDirection.ltr,
        ),
        subtitle: const LocalizedText('Verified account phone number'),
      ),
      const SizedBox(height: 16),
      marketplaceField(
        _whatsapp,
        'WhatsApp number (if different)',
        keyboard: TextInputType.phone,
        validator: (v) => pakistanPhone(v, optional: true),
        maxLength: 20,
      ),
      marketplaceField(
        _city,
        'City',
        validator: marketplaceRequired,
        maxLength: 80,
      ),
      marketplaceField(_area, 'Neighbourhood / service area', maxLength: 120),
      const MarketplaceNotice(
        message:
            'Use an area name, not your home address. Customers see your service area '
            'and approximate distance, never your precise coordinates.',
      ),
    ],
    1 => [
      const MarketplaceHeading(
        'Show what you do best',
        subtitle: 'Your profession determines the skills and questions below.',
      ),
      DropdownButtonFormField<String>(
        key: ValueKey('profession-$_professionId'),
        initialValue: controller.professions.any((p) => p.id == _professionId)
            ? _professionId
            : null,
        isExpanded: true,
        decoration: localizedDecoration(context, labelText: 'Profession'),
        items: controller.professions
            .map(
              (p) =>
                  DropdownMenuItem(value: p.id, child: LocalizedText(p.name)),
            )
            .toList(),
        validator: (value) =>
            value == null ? context.tr('Choose your profession.') : null,
        onChanged: (value) => setState(() {
          if (_professionId != value) {
            _skills.clear();
            _answers.clear();
          }
          _professionId = value;
        }),
      ),
      const SizedBox(height: 20),
      if (profession != null) ...[
        const LocalizedText('Skills and specializations'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final skill in profession.skills)
              FilterChip(
                label: LocalizedText(skill.name),
                selected: _skills.contains(skill.id),
                onSelected: (selected) => setState(() {
                  selected ? _skills.add(skill.id) : _skills.remove(skill.id);
                }),
              ),
          ],
        ),
        const SizedBox(height: 20),
      ],
      marketplaceField(
        _experience,
        'Years of experience',
        keyboard: TextInputType.number,
        maxLength: 2,
        validator: (v) {
          final value = int.tryParse(v ?? '');
          return value == null || value < 0 || value > 60
              ? context.tr('Enter experience from 0 to 60 years.')
              : null;
        },
      ),
      marketplaceField(
        _description,
        'About your work',
        lines: 4,
        maxLength: 2000,
        hint: 'Describe your experience and the work you can take on.',
      ),
      marketplaceField(
        _languages,
        'Languages (comma separated)',
        maxLength: 300,
        hint: 'Urdu, Punjabi, English',
      ),
      if (profession != null) ...profession.questions.map(_question),
    ],
    2 => [
      const MarketplaceHeading('Set your price and working hours'),
      marketplaceField(
        _rate,
        'Starting price (PKR)',
        keyboard: TextInputType.number,
        validator: nonNegativeNumber,
        maxLength: 8,
      ),
      DropdownButtonFormField<String>(
        initialValue: _rateUnit,
        isExpanded: true,
        decoration: localizedDecoration(context, labelText: 'Pricing method'),
        items: const [
          DropdownMenuItem(value: 'hour', child: LocalizedText('Per hour')),
          DropdownMenuItem(value: 'day', child: LocalizedText('Per day')),
          DropdownMenuItem(value: 'job', child: LocalizedText('Per job')),
          DropdownMenuItem(value: 'visit', child: LocalizedText('Per visit')),
        ],
        onChanged: (v) => setState(() => _rateUnit = v!),
      ),
      const SizedBox(height: 16),
      LocalizedText('Service radius: ${_radius.toStringAsFixed(0)} km'),
      Slider(
        value: _radius.clamp(1, 100),
        min: 1,
        max: 100,
        divisions: 99,
        onChanged: (v) => setState(() => _radius = v),
      ),
      const LocalizedText('Working days'),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var day = 1; day <= 7; day++)
            FilterChip(
              label: LocalizedText(
                ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day - 1],
              ),
              selected: _days.contains(day),
              onSelected: (selected) => setState(() {
                selected ? _days.add(day) : _days.remove(day);
              }),
            ),
        ],
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          OutlinedButton.icon(
            onPressed: () => _time(opening: true),
            icon: const Icon(Icons.schedule),
            label: LocalizedText('Start: $_start'),
          ),
          OutlinedButton.icon(
            onPressed: () => _time(opening: false),
            icon: const Icon(Icons.schedule),
            label: LocalizedText('Finish: $_end'),
          ),
        ],
      ),
      const SizedBox(height: 16),
      const MarketplaceNotice(
        message:
            'Your working hours describe your usual schedule. '
            'Set your current availability separately after saving your profile.',
      ),
    ],
    _ => [
      const MarketplaceHeading(
        'Add your work. Make it yours.',
        subtitle:
            'Photos are optional. Upload only images you have permission to share.',
      ),
      Row(
        children: [
          MarketplacePhoto(name: _name.text, url: _avatar, radius: 36),
          const SizedBox(width: 16),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _uploading ? null : () => _upload(avatar: true),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const LocalizedText('Profile photo'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      const LocalizedText('Portfolio photos'),
      const SizedBox(height: 10),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final url in _portfolio.where(isSafeMarketplaceImage))
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton.filledTonal(
                      tooltip: context.tr('Remove image'),
                      onPressed: () => setState(() => _portfolio.remove(url)),
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          if (_portfolio.length < 8)
            SizedBox(
              width: 100,
              height: 100,
              child: OutlinedButton(
                onPressed: _uploading ? null : () => _upload(avatar: false),
                child: const Icon(Icons.add_photo_alternate_outlined),
              ),
            ),
        ],
      ),
      if (_uploading) const LinearProgressIndicator(),
      const SizedBox(height: 20),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const LocalizedText('Let signed-in customers contact me'),
        subtitle: const LocalizedText(
          'Share your phone and WhatsApp number when an eligible customer asks. '
          'Job requests work without sharing these details.',
        ),
        value: _shareContact,
        onChanged: (v) => setState(() => _shareContact = v),
      ),
      const SizedBox(height: 16),
      const MarketplaceHeading('Public profile preview'),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_name.text, style: Theme.of(context).textTheme.titleLarge),
              LocalizedText(profession?.name ?? 'Choose your profession.'),
              const SizedBox(height: 8),
              Text(
                [_area.text, _city.text].where((s) => s.isNotEmpty).join(', '),
              ),
              LocalizedText('${_experience.text} years experience'),
              LocalizedText(
                'From PKR ${_rate.text} / ${context.tr(_rateUnit)}',
              ),
              const SizedBox(height: 8),
              Text(_description.text),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: _skills
                    .map((s) => Chip(label: LocalizedText(s)))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
      const MarketplaceNotice(
        message:
            'Publishing makes your profile discoverable. A draft stays private. '
            'To publish, add skills, a description of at least 20 characters, a price and working days, '
            'and complete the questions for your profession.',
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MarketplaceController>();
    _populate(controller);
    final profile = controller.profile;
    final profession = controller.professions
        .where((p) => p.id == _professionId)
        .firstOrNull;
    final busy = controller.busy || _uploading;
    return MarketplacePage(
      title: 'My professional profile',
      section: 2,
      child: !controller.isAuthenticated
          ? const MarketplaceSignIn(
              message:
                  'Sign in to offer your services and receive job requests.',
            )
          : profile != null && !profile.isActive
          ? EmptyState(
              title: 'Account restricted',
              message:
                  'Your account is ${profile.status}. Contact support for help.',
            )
          : Form(
              key: _form,
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.all(24),
                children: [
                  if (controller.error != null)
                    MarketplaceNotice(message: controller.error!, error: true),
                  if (controller.notice != null)
                    MarketplaceNotice(message: controller.notice!),
                  LinearProgressIndicator(value: (_step + 1) / 4),
                  const SizedBox(height: 12),
                  LocalizedText(
                    'Step ${_step + 1} of 4',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 20),
                  ..._stepContent(controller, profession),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (_step > 0)
                        OutlinedButton(
                          onPressed: busy ? null : () => _goStep(_step - 1),
                          child: const LocalizedText('Back'),
                        ),
                      if (_step < 3)
                        FilledButton(
                          onPressed: busy ? null : _advance,
                          child: const LocalizedText('Continue'),
                        ),
                      if (_step == 3)
                        FilledButton(
                          onPressed: busy ? null : () => _save(true),
                          child: const LocalizedText('Publish profile'),
                        ),
                      OutlinedButton(
                        onPressed: busy ? null : () => _save(false),
                        child: const LocalizedText('Save draft'),
                      ),
                    ],
                  ),
                  if (controller.ownWorker != null) ...[
                    const SizedBox(height: 28),
                    const MarketplaceHeading(
                      'Current availability',
                      subtitle:
                          'Update this when you can accept work. Available now expires after 15 minutes.',
                    ),
                    LocalizedText(controller.ownAvailability.label),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final availability
                            in WorkerAvailability.values.where(
                              (v) => v != WorkerAvailability.unknown,
                            ))
                          ActionChip(
                            label: LocalizedText(availability.label),
                            onPressed: busy
                                ? null
                                : () async {
                                    if (availability ==
                                        WorkerAvailability.availableNow) {
                                      final proceed = await confirmAction(
                                        context,
                                        'Share your service location?',
                                        'Available now uses your current device location to match nearby customers. '
                                            'Your exact coordinates stay private. Location is updated only when you choose this action.',
                                        confirm: 'Use location',
                                      );
                                      if (!proceed || !mounted) return;
                                    }
                                    await controller.setAvailability(
                                      availability,
                                    );
                                  },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => context.push(
                        '/marketplace/workers/${controller.userId}',
                      ),
                      child: const LocalizedText('View published profile'),
                    ),
                  ],
                  if (busy)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: LinearProgressIndicator(),
                    ),
                ],
              ),
            ),
    );
  }
}
