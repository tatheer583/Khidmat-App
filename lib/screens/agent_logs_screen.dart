import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../localization/app_language.dart';
import '../services/app_state.dart';

class AgentLogsScreen extends StatelessWidget {
  const AgentLogsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final logs = context.watch<AppState>().agentLogs;
    return Scaffold(
      appBar: AppBar(
        title: const LocalizedText('Activity log'),
        actions: const [LanguageButton()],
      ),
      body: logs.isEmpty
          ? const Center(
              child: LocalizedText('Start a service request to see activity.'),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final log in logs)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.agent.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          for (final line in log.lines) LocalizedText(line),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
