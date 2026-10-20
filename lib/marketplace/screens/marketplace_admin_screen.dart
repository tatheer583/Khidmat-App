import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../localization/app_language.dart';
import '../../widgets/app_ui.dart';
import '../services/marketplace_controller.dart';
import '../widgets/marketplace_ui.dart';

class MarketplaceAdminScreen extends StatefulWidget {
  const MarketplaceAdminScreen({super.key});

  @override
  State<MarketplaceAdminScreen> createState() => _MarketplaceAdminScreenState();
}

class _MarketplaceAdminScreenState extends State<MarketplaceAdminScreen> {
  final _form = GlobalKey<FormState>();
  final _account = TextEditingController(), _reason = TextEditingController();
  String _action = 'suspend';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<MarketplaceController>().isAdmin) {
        context.read<MarketplaceController>().loadReports();
        context.read<MarketplaceController>().loadModerationReviews();
      }
    });
  }

  @override
  void dispose() {
    _account.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _moderate() async {
    if (!_form.currentState!.validate()) return;
    final controller = context.read<MarketplaceController>();
    final confirmed = await confirmAction(
      context,
      'Apply moderation decision?',
      '${moderationActionLabel(_action)}\n${_account.text.trim()}\n\n${_reason.text.trim()}',
      confirm: 'Apply decision',
    );
    if (!confirmed || !mounted) return;
    final saved = await controller.moderateAccount(
      _account.text.trim(),
      _action,
      _reason.text.trim(),
    );
    if (saved && mounted) {
      _reason.clear();
      await controller.loadReports();
    }
  }

  Future<void> _reviewDecision(Map<String, dynamic> review) async {
    final controller = context.read<MarketplaceController>();
    final hide = review['hidden'] != true;
    final decisionReason = await showDialog<String>(
      context: context,
      builder: (_) => _ReviewDecisionDialog(
        hide: hide,
        comment: '${review['comment'] ?? ''}',
      ),
    );
    if (decisionReason == null || !mounted) return;
    if (await controller.moderateReview(
          '${review['id']}',
          hide,
          decisionReason,
        ) &&
        mounted) {
      await controller.loadModerationReviews();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MarketplaceController>();
    return MarketplacePage(
      title: 'Administration',
      navigation: false,
      child: !controller.isAuthenticated
          ? const MarketplaceSignIn(
              message: 'Sign in with an administrator account to continue.',
            )
          : !controller.isAdmin
          ? const EmptyState(
              title: 'Administrator access required',
              message: 'This account cannot access moderation tools.',
              icon: Icons.admin_panel_settings_outlined,
            )
          : RefreshIndicator(
              onRefresh: () async {
                await controller.loadReports();
                await controller.loadModerationReviews();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const MarketplaceHeading(
                    'Reported accounts',
                    subtitle:
                        'Review the evidence before applying a decision. Every decision is recorded.',
                  ),
                  if (controller.error != null)
                    MarketplaceNotice(message: controller.error!, error: true),
                  if (controller.notice != null)
                    MarketplaceNotice(message: controller.notice!),
                  if (controller.busy) const LinearProgressIndicator(),
                  if (controller.moderationReports.isEmpty && !controller.busy)
                    const EmptyState(
                      title: 'No reports to display',
                      message:
                          'Reports submitted by customers and workers appear here.',
                      icon: Icons.flag_outlined,
                    ),
                  for (final report in controller.moderationReports)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.flag_outlined),
                        title: LocalizedText(
                          '${report['reason'] ?? 'Report'} · ${report['status'] ?? ''}',
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableText(
                              'Account: ${report['reported_user_id'] ?? ''}',
                            ),
                            Text('${report['details'] ?? ''}'),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_downward),
                        onTap: () => setState(
                          () => _account.text =
                              '${report['reported_user_id'] ?? ''}',
                        ),
                      ),
                    ),
                  if (controller.canLoadMoreReports)
                    OutlinedButton(
                      onPressed: controller.busy
                          ? null
                          : () => controller.loadReports(append: true),
                      child: const LocalizedText('Load more reports'),
                    ),
                  const SizedBox(height: 24),
                  Form(
                    key: _form,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const MarketplaceHeading('Record a decision'),
                        marketplaceField(
                          _account,
                          'Account ID',
                          maxLength: 36,
                          validator: (value) =>
                              RegExp(
                                r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
                              ).hasMatch(value?.trim() ?? '')
                              ? null
                              : context.tr('Enter a valid account ID.'),
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: _action,
                          isExpanded: true,
                          decoration: localizedDecoration(
                            context,
                            labelText: 'Moderation action',
                          ),
                          items:
                              [
                                    'suspend',
                                    'reactivate',
                                    'verify_worker',
                                    'revoke_verification',
                                  ]
                                  .map(
                                    (action) => DropdownMenuItem(
                                      value: action,
                                      child: LocalizedText(
                                        moderationActionLabel(action),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) =>
                              setState(() => _action = value!),
                        ),
                        const SizedBox(height: 20),
                        marketplaceField(
                          _reason,
                          'Evidence and decision reason',
                          maxLength: 500,
                          lines: 4,
                          validator: (value) => (value?.trim().length ?? 0) < 10
                              ? context.tr('Add at least 10 characters.')
                              : null,
                        ),
                        const MarketplaceNotice(
                          message:
                              'Worker verification is an operator decision based on evidence. '
                              'A verified phone number alone does not verify a worker’s identity or qualifications.',
                        ),
                        FilledButton(
                          onPressed: controller.busy ? null : _moderate,
                          child: const LocalizedText('Apply decision'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const MarketplaceHeading(
                    'Review moderation',
                    subtitle:
                        'Original review text and ratings are retained. Hidden reviews do not contribute to public ratings.',
                  ),
                  if (controller.moderationReviews.isEmpty && !controller.busy)
                    const LocalizedText('No reviews to moderate'),
                  for (final review in controller.moderationReviews)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LocalizedText(
                              review['hidden'] == true
                                  ? 'Review hidden'
                                  : 'Review visible',
                            ),
                            Text('★ ${review['rating']}'),
                            Text('${review['comment'] ?? ''}'),
                            const SizedBox(height: 8),
                            SelectableText(
                              '${context.tr('Review ID')}: ${review['id']}',
                            ),
                            SelectableText(
                              '${context.tr('Worker ID')}: ${review['worker_id']}',
                            ),
                            SelectableText(
                              '${context.tr('Customer ID')}: ${review['customer_id']}',
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: controller.busy
                                  ? null
                                  : () => _reviewDecision(review),
                              icon: Icon(
                                review['hidden'] == true
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              label: LocalizedText(
                                review['hidden'] == true
                                    ? 'Restore review'
                                    : 'Hide review',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (controller.canLoadMoreModerationReviews)
                    OutlinedButton(
                      onPressed: controller.busy
                          ? null
                          : () =>
                                controller.loadModerationReviews(append: true),
                      child: const LocalizedText('Load more reviews'),
                    ),
                ],
              ),
            ),
    );
  }
}

String moderationActionLabel(String action) => switch (action) {
  'suspend' => 'Suspend account',
  'reactivate' => 'Reactivate account',
  'verify_worker' => 'Verify worker',
  'revoke_verification' => 'Revoke worker verification',
  _ => action,
};

class _ReviewDecisionDialog extends StatefulWidget {
  const _ReviewDecisionDialog({required this.hide, required this.comment});
  final bool hide;
  final String comment;
  @override
  State<_ReviewDecisionDialog> createState() => _ReviewDecisionDialogState();
}

class _ReviewDecisionDialogState extends State<_ReviewDecisionDialog> {
  final _reason = TextEditingController();
  final _form = GlobalKey<FormState>();
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: LocalizedText(
      widget.hide ? 'Hide this review?' : 'Restore this review?',
    ),
    content: SingleChildScrollView(
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.comment),
            const SizedBox(height: 16),
            marketplaceField(
              _reason,
              'Decision reason',
              maxLength: 1000,
              lines: 4,
              validator: (value) => (value?.trim().length ?? 0) < 10
                  ? context.tr(
                      'Record at least 10 characters explaining this decision.',
                    )
                  : null,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const LocalizedText('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(context, _reason.text.trim());
          }
        },
        child: const LocalizedText('Save decision'),
      ),
    ],
  );
}
