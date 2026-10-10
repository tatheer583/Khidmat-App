import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../localization/app_language.dart';
import '../../widgets/app_ui.dart';
import '../services/marketplace_controller.dart';
import '../widgets/marketplace_ui.dart';
import '../push_notifications.dart';

class MarketplaceNotificationsScreen extends StatefulWidget {
  const MarketplaceNotificationsScreen({super.key});

  @override
  State<MarketplaceNotificationsScreen> createState() =>
      _MarketplaceNotificationsScreenState();
}

class _MarketplaceNotificationsScreenState
    extends State<MarketplaceNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<MarketplaceController>().isAuthenticated) {
        context.read<MarketplaceController>().loadNotifications();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MarketplaceController>();
    final push = context.watch<OptionalPushService>();
    return MarketplacePage(
      title: 'Notifications',
      navigation: false,
      child: !controller.isAuthenticated
          ? const MarketplaceSignIn(
              message: 'Sign in to see updates about your jobs.',
            )
          : RefreshIndicator(
              onRefresh: () async {
                await controller.loadNotifications();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  const MarketplaceHeading(
                    'Stay up to date',
                    subtitle:
                        'Request responses, job progress and new reviews.',
                  ),
                  const MarketplaceNotice(
                    message:
                        'In-app updates refresh while Khidmat is open. Pull down to check again.',
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const LocalizedText('Push notifications'),
                    subtitle: LocalizedText(
                      push.configured
                          ? 'Receive job updates when Khidmat is closed.'
                          : 'Push notifications require provider setup. In-app notification history remains available.',
                    ),
                    value: push.enabled,
                    onChanged: push.busy || !push.configured
                        ? null
                        : (value) async {
                            if (value) {
                              await push.enable();
                            } else {
                              await push.disable();
                            }
                          },
                  ),
                  if (push.error != null)
                    MarketplaceNotice(
                      message: push.error!,
                      error: true,
                      action: 'Disable push notifications',
                      onAction: push.busy
                          ? null
                          : () async {
                              await push.disable();
                            },
                    ),
                  if (controller.error != null)
                    MarketplaceNotice(message: controller.error!, error: true),
                  if (controller.busy) const LinearProgressIndicator(),
                  if (controller.notifications.isEmpty && !controller.busy)
                    const EmptyState(
                      title: 'You are all caught up',
                      message:
                          'Updates about your requests and bookings will appear here.',
                      icon: Icons.notifications_none,
                    ),
                  for (final notification in controller.notifications)
                    Card(
                      child: ListTile(
                        leading: Icon(
                          notification.isRead
                              ? Icons.notifications_none
                              : Icons.notifications_active_outlined,
                        ),
                        title: LocalizedText(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LocalizedText(notification.body),
                            if (notification.createdAt != null)
                              Text(
                                DateFormat.yMMMd().add_jm().format(
                                  notification.createdAt!.toLocal(),
                                ),
                              ),
                          ],
                        ),
                        trailing: notification.jobId == null
                            ? null
                            : const Icon(Icons.chevron_right),
                        onTap: controller.busy
                            ? null
                            : () async {
                                if (!notification.isRead) {
                                  await controller.markNotificationRead(
                                    notification.id,
                                  );
                                }
                                if (context.mounted &&
                                    notification.jobId != null) {
                                  context.go('/marketplace/jobs');
                                }
                              },
                      ),
                    ),
                  if (controller.canLoadMoreNotifications)
                    OutlinedButton(
                      onPressed: controller.busy
                          ? null
                          : () => controller.loadNotifications(append: true),
                      child: const LocalizedText('Load more notifications'),
                    ),
                ],
              ),
            ),
    );
  }
}
