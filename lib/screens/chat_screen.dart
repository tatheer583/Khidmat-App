import '../localization/app_language.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/backend_session.dart';
import '../services/khidmat_repository.dart';
import '../widgets/live_ui.dart';

class ChatScreen extends StatefulWidget {
  final String bookingId;
  const ChatScreen({super.key, required this.bookingId});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _text = TextEditingController();
  late Stream<List<Map<String, dynamic>>> _stream;
  bool _sending = false;
  KhidmatRepository get _repo =>
      KhidmatRepository(context.read<BackendSession>().client);
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ChatScreen old) {
    super.didUpdateWidget(old);
    if (old.bookingId != widget.bookingId) {
      _text.clear();
      _load();
    }
  }

  void _load() {
    _stream = _repo.messages(widget.bookingId);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send({bool photo = false}) async {
    if (_sending || (!photo && _text.text.trim().isEmpty)) return;
    setState(() => _sending = true);
    try {
      final image = photo
          ? await ImagePicker().pickImage(
              source: ImageSource.gallery,
              maxWidth: 1920,
              maxHeight: 1920,
              imageQuality: 85,
            )
          : null;
      if (!mounted || (photo && image == null)) return;
      await _repo.sendMessage(widget.bookingId, _text.text, image: image);
      if (mounted) _text.clear();
    } catch (e) {
      if (mounted) showMessage(context, describeError(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const LocalizedText('Booking conversation'),
      actions: [
        const LanguageButton(),
        IconButton(
          tooltip: context.tr('Refresh'),
          onPressed: () => setState(_load),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Notice(
                      describeError(snapshot.error!),
                      retry: () => setState(_load),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                if (messages.isEmpty) {
                  return const Center(
                    child: Notice('Say hello or share a photo of the work.'),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final mine =
                        msg['sender_id'] ==
                        context.read<BackendSession>().user!.id;
                    final path = msg['attachment_path'] as String?;
                    return Align(
                      alignment: mine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 320),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: mine
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LocalizedText(
                              mine ? 'You' : 'Booking participant',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            if (path != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: StoredImage(
                                  key: ValueKey(path),
                                  bucket: 'booking-media',
                                  path: path,
                                ),
                              ),
                            if ((msg['body'] as String).isNotEmpty)
                              LocalizedText(
                                msg['body'] as String,
                                translate: false,
                              ),
                            const SizedBox(height: 6),
                            LocalizedText(
                              DateTime.parse(
                                msg['created_at'] as String,
                              ).toLocal().toString().substring(0, 16),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_sending) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: context.tr('Share photo'),
                  onPressed: _sending ? null : () => _send(photo: true),
                  icon: const Icon(Icons.image_outlined),
                ),
                Expanded(
                  child: TextField(
                    controller: _text,
                    enabled: !_sending,
                    maxLength: 4000,
                    minLines: 1,
                    maxLines: 4,
                    decoration: localizedDecoration(
                      context,
                      hintText: 'Message…',
                      counterText: '',
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(
                  tooltip: context.tr('Send'),
                  onPressed: _sending ? null : () => _send(),
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
