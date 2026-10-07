import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/local_data.dart';

/// A phone-owned JSON file. Writes finish before the UI reports success.
class LocalStore extends ChangeNotifier {
  LocalStore({Directory? directory}) : _directory = directory;
  Directory? _directory;
  LocalData _data = LocalData();
  Future<void> _queue = Future.value();
  bool initialized = false;
  bool loading = false;
  bool _disposed = false;
  int _operations = 0;
  String? error;
  String? notice;
  bool get busy => _operations > 0;
  KhidmatProfile? get profile => _data.profile;
  List<WorkerContact> get workers => _data.workers;
  List<JobRecord> get jobs => _data.jobs;
  List<JobRecord> get roleJobs =>
      jobs.where((j) => j.role == profile?.role).toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  File _file(String name) =>
      File('${_directory!.path}${Platform.pathSeparator}$name');
  void _changed() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    if (loading || initialized) return;
    loading = true;
    error = null;
    notice = null;
    _changed();
    try {
      _directory ??= Directory(
        '${(await getApplicationSupportDirectory()).path}${Platform.pathSeparator}khidmat',
      );
      await _directory!.create(recursive: true);
      final main = _file('data.json');
      final backup = _file('data.previous.json');
      if (await main.exists()) {
        try {
          _data = _decode(await main.readAsString());
        } catch (_) {
          if (!await backup.exists()) rethrow;
          _data = _decode(await backup.readAsString());
          // Preserve the unreadable file; restore only from a valid snapshot.
          await main.copy(_file('data.unreadable.json').path);
          await backup.copy(main.path);
          notice = 'Recovered your records from the last saved copy.';
        }
      } else if (await backup.exists()) {
        _data = _decode(await backup.readAsString());
        await backup.copy(main.path);
        notice = 'Recovered your records from the last saved copy.';
      }
      initialized = true;
      // Remove the old version's connection settings and cached login token.
      try {
        final preferences = await SharedPreferences.getInstance();
        for (final key in preferences.getKeys().where(
          (key) =>
              key == 'supabase_url' ||
              key == 'supabase_key' ||
              (key.startsWith('sb-') && key.endsWith('-auth-token')),
        )) {
          await preferences.remove(key);
        }
      } catch (_) {
        /* Legacy preferences never block opening local records. */
      }
    } catch (_) {
      error =
          'Your saved phone data could not be opened. Check device storage, then try again.';
    } finally {
      loading = false;
      _changed();
    }
  }

  static LocalData _decode(String raw) {
    if (utf8.encode(raw).length > 20 * 1024 * 1024) {
      throw const FormatException('This backup is too large');
    }
    try {
      return LocalData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      if (e is FormatException) rethrow;
      throw const FormatException('Choose a valid Khidmat backup file');
    }
  }

  Future<void> _mutate(
    LocalData Function(LocalData) transform, {
    bool recover = false,
  }) {
    _operations++;
    _changed();
    final operation = _queue.then((_) async {
      if ((!initialized || error != null) && !recover) {
        throw StateError('Open your phone data before saving');
      }
      if (_directory == null) {
        throw StateError('Open your phone data before saving');
      }
      final next = transform(_data);
      final encoded = jsonEncode(next.toJson());
      if (utf8.encode(encoded).length > 20 * 1024 * 1024 ||
          next.workers.length > 5000 ||
          next.jobs.length > 50000) {
        throw const FormatException(
          'Your records are full. Save a backup before removing old records.',
        );
      }
      final pending = _file('data.pending.json');
      await pending.writeAsString(encoded, flush: true);
      final main = _file('data.json');
      if (await main.exists()) {
        await main.copy(_file('data.previous.json').path);
      }
      await pending.rename(main.path);
      if (!_disposed) {
        _data = next;
        initialized = true;
        error = null;
      }
    });
    // A failed write must not poison the queue or change the visible records.
    _queue = operation.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return operation.whenComplete(() {
      _operations--;
      _changed();
    });
  }

  Future<void> saveProfile(KhidmatProfile value) {
    value.validate();
    return _mutate((data) => data.copyWith(profile: value));
  }

  Future<void> saveWorker(WorkerContact value) {
    value.validate();
    return _mutate((data) {
      final contacts = data.workers.where((w) => w.id != value.id).toList()
        ..add(value);
      return data.copyWith(workers: contacts);
    });
  }

  Future<void> removeWorker(String id) => _mutate(
    (data) => data.copyWith(
      workers: data.workers.where((w) => w.id != id).toList(),
      jobs: data.jobs
          .map((j) => j.contactId == id ? j.withoutContact() : j)
          .toList(),
    ),
  );

  Future<void> saveJob(JobRecord value, {bool allowPast = false}) {
    value.validate();
    return _mutate((data) {
      if (data.profile == null) throw StateError('Create your profile first');
      final exists = data.jobs.any((j) => j.id == value.id);
      if (!exists && !allowPast && value.scheduledAt.isBefore(DateTime.now())) {
        throw const FormatException('Choose a future date and time');
      }
      if (value.contactId != null &&
          !data.workers.any((w) => w.id == value.contactId)) {
        throw const FormatException(
          'The worker contact was removed. Choose another contact.',
        );
      }
      _checkAppointment(data, value);
      return data.copyWith(
        jobs: data.jobs.where((j) => j.id != value.id).toList()..add(value),
      );
    });
  }

  Future<void> updateStatus(String id, JobStatus status) => _mutate((data) {
    if (!data.jobs.any((j) => j.id == id)) {
      throw StateError('This job was removed');
    }
    _checkAppointment(
      data,
      data.jobs.firstWhere((j) => j.id == id).withStatus(status),
    );
    return data.copyWith(
      jobs: data.jobs
          .map((j) => j.id == id ? j.withStatus(status) : j)
          .toList(),
    );
  });
  static void _checkAppointment(LocalData data, JobRecord value) {
    final phone = cleanPhone(value.phone);
    if (value.status.active &&
        data.jobs.any(
          (j) =>
              j.id != value.id &&
              j.status.active &&
              j.role == value.role &&
              j.scheduledAt.isAtSameMomentAs(value.scheduledAt) &&
              (value.role == AccountRole.worker ||
                  (phone.isNotEmpty
                      ? cleanPhone(j.phone) == phone
                      : j.personName.trim().toLowerCase() ==
                            value.personName.trim().toLowerCase())),
        )) {
      throw const FormatException(
        'You already have this appointment. Choose another time.',
      );
    }
  }

  Future<void> removeJob(String id) => _mutate(
    (data) => data.copyWith(jobs: data.jobs.where((j) => j.id != id).toList()),
  );

  WorkerContact? worker(String id) {
    for (final w in workers) {
      if (w.id == id) return w;
    }
    return null;
  }

  JobRecord? job(String id) {
    for (final j in jobs) {
      if (j.id == id) return j;
    }
    return null;
  }

  String exportBackup() =>
      const JsonEncoder.withIndent('  ').convert(_data.toJson());
  LocalData inspectBackup(String raw) => _decode(raw);
  Future<void> restoreBackup(String raw) {
    final incoming = _decode(raw);
    return _mutate((_) => incoming, recover: true);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

String localError(Object error) {
  if (error is FormatException) return error.message;
  if (error is StateError) return error.message.toString();
  if (error is FileSystemException) {
    return 'Could not save to your phone. Check device storage and try again.';
  }
  return 'Could not complete this action. Please try again.';
}
