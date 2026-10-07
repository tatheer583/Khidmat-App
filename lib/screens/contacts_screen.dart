import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../localization/app_language.dart';
import '../models/local_data.dart';
import '../services/local_store.dart';
import '../services/service_matcher.dart';
import '../services/contact_actions.dart';
import '../widgets/app_ui.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});
  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _search = TextEditingController();
  String? _category;
  bool _favorites = false;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final store = context.watch<LocalStore>();
    final workers = findSavedWorkers(
      store.workers,
      _search.text,
      category: _category,
      favoritesOnly: _favorites,
    );
    return AppPage(
      title: 'Saved workers',
      section: 1,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/contacts/new'),
        icon: const Icon(Icons.person_add_alt),
        label: const LocalizedText('Add worker'),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Column(
              children: [
                if (!keyboardOpen)
                  const LocalizedText(
                    'Add workers you know. This list is saved on your phone.',
                  ),
                if (!keyboardOpen) const SizedBox(height: 16),
                TextField(
                  controller: _search,
                  decoration: localizedDecoration(
                    context,
                    hintText: 'Search name, city or service',
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                if (!keyboardOpen) const SizedBox(height: 12),
                if (!keyboardOpen)
                  SizedBox(
                    height: 52,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: FilterChip(
                            label: const LocalizedText('Favorites'),
                            selected: _favorites,
                            onSelected: (v) => setState(() => _favorites = v),
                          ),
                        ),
                        for (final category in ['All', ...serviceCategories])
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8),
                            child: ChoiceChip(
                              label: LocalizedText(category),
                              selected: (_category ?? 'All') == category,
                              onSelected: (_) => setState(
                                () => _category = category == 'All'
                                    ? null
                                    : category,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: workers.isEmpty
                ? SingleChildScrollView(
                    child: EmptyState(
                      icon: Icons.people_outline,
                      title: store.workers.isEmpty
                          ? 'No worker contacts yet'
                          : 'No matching contacts',
                      message: store.workers.isEmpty
                          ? 'Save a real worker contact to call them, send requests and plan jobs.'
                          : 'Try another name, city or service.',
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: workers.length,
                    itemBuilder: (context, index) {
                      final w = workers[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: PersonAvatar(w.name),
                          title: Text(w.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LocalizedText(w.category),
                              Text(w.city),
                              if (w.favorite) const LocalizedText('Favorite'),
                            ],
                          ),
                          trailing: IconButton(
                            tooltip: context.tr('Call'),
                            icon: const Icon(Icons.call_outlined),
                            onPressed: () =>
                                ContactActions.call(context, w.phone),
                          ),
                          onTap: () => context.push('/contacts/${w.id}'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
