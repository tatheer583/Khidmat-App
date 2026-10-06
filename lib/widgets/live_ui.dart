import '../localization/app_language.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/backend_session.dart';
import '../services/khidmat_repository.dart';

class Notice extends StatelessWidget {
  final String text;
  final VoidCallback? retry;
  const Notice(this.text, {super.key, this.retry});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LocalizedText(text, textAlign: TextAlign.center),
        if (retry != null)
          TextButton(onPressed: retry, child: const LocalizedText('Try again')),
      ],
    ),
  );
}

class StoredImage extends StatefulWidget {
  final String bucket;
  final String path;
  final double height;
  const StoredImage({
    super.key,
    required this.bucket,
    required this.path,
    this.height = 160,
  });
  @override
  State<StoredImage> createState() => _StoredImageState();
}

class _StoredImageState extends State<StoredImage> {
  late Future<String> _url;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(StoredImage old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path || old.bucket != widget.bucket) _load();
  }

  void _load() {
    _url = KhidmatRepository(
      context.read<BackendSession>().client,
    ).signedImage(widget.bucket, widget.path);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: _url,
    builder: (context, snapshot) {
      if (snapshot.hasError) return const Icon(Icons.broken_image_outlined);
      if (!snapshot.hasData) {
        return SizedBox(
          height: widget.height,
          child: const Center(child: CircularProgressIndicator()),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          snapshot.data!,
          height: widget.height,
          fit: BoxFit.cover,
          errorBuilder: (_, error, stack) =>
              const Icon(Icons.broken_image_outlined),
        ),
      );
    },
  );
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: LocalizedText(message)));
}
