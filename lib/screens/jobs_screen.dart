import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../localization/app_language.dart';
import '../models/local_data.dart';
import '../services/local_store.dart';
import '../widgets/app_ui.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});
  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  String _filter = 'Active';
  @override
  Widget build(BuildContext context) {
    final all = context.watch<LocalStore>().roleJobs;
    final jobs = all
        .where(
          (j) => switch (_filter) {
            'Active' => j.status.active,
            'Completed' => j.status == JobStatus.completed,
            'Cancelled' => j.status == JobStatus.cancelled,
            _ => true,
          },
        )
        .toList();
    if (_filter != 'Active') {
      jobs.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    }
    return AppPage(
      title: 'My jobs',
      section: 2,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/jobs/new'),
        icon: const Icon(Icons.add),
        label: const LocalizedText('Add job'),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: LocalizedText(
              'Confirm dates and prices directly with the other person.',
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['Active', 'Completed', 'Cancelled', 'All']
                  .map(
                    (filter) => Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ChoiceChip(
                        label: LocalizedText(filter),
                        selected: _filter == filter,
                        onSelected: (_) => setState(() => _filter = filter),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: jobs.isEmpty
                ? SingleChildScrollView(
                    child: EmptyState(
                      title: 'No jobs here yet',
                      message:
                          'Save an appointment to keep the date, address, price and progress together.',
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    itemCount: jobs.length,
                    itemBuilder: (_, index) => JobCard(jobs[index]),
                  ),
          ),
        ],
      ),
    );
  }
}
