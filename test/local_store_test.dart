import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:khidmat/models/local_data.dart';
import 'package:khidmat/services/local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

const profile = KhidmatProfile(
  name: 'Ali Khan',
  city: 'Lahore',
  role: AccountRole.customer,
);
const worker = WorkerContact(
  id: 'worker-1',
  name: 'Aslam',
  phone: '+923001234567',
  category: 'Plumber',
  city: 'Lahore',
  experienceYears: 5,
  rate: 500,
);
JobRecord appointment(
  String id, {
  AccountRole role = AccountRole.customer,
  JobStatus status = JobStatus.planned,
}) => JobRecord(
  id: id,
  role: role,
  service: 'Plumber',
  personName: 'Aslam',
  phone: worker.phone,
  contactId: worker.id,
  scheduledAt: DateTime(2090, 5, 10, 12),
  address: 'Garden Town, Lahore',
  amount: 1500,
  status: status,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late LocalStore store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('khidmat-test-');
    store = LocalStore(directory: directory);
    await store.initialize();
  });
  tearDown(() async {
    store.dispose();
    await directory.delete(recursive: true);
  });

  test(
    'profile, contacts, jobs and status survive a new store instance',
    () async {
      await store.saveProfile(profile);
      await store.saveWorker(worker);
      await store.saveJob(appointment('job-1'));
      await store.updateStatus('job-1', JobStatus.completed);
      final reopened = LocalStore(directory: directory);
      await reopened.initialize();
      expect(reopened.error, isNull);
      expect(reopened.profile!.name, 'Ali Khan');
      expect(reopened.workers.single.rate, 500);
      expect(reopened.jobs.single.status, JobStatus.completed);
      expect(reopened.jobs.single.address, 'Garden Town, Lahore');
      reopened.dispose();
    },
  );

  test('simultaneous saves are serialized without losing contacts', () async {
    await Future.wait(
      List.generate(
        20,
        (i) => store.saveWorker(
          WorkerContact(
            id: 'worker-$i',
            name: 'Worker $i',
            phone: worker.phone,
            category: 'Plumber',
            city: 'Lahore',
          ),
        ),
      ),
    );
    expect(store.workers.length, 20);
    expect(store.busy, isFalse);
    expect(
      (jsonDecode(await File('${directory.path}/data.json').readAsString())
              as Map)['workers']
          .length,
      20,
    );
  });

  test(
    'failed disk write does not report success and the next write can recover',
    () async {
      await store.saveProfile(profile);
      final obstacle = Directory('${directory.path}/data.pending.json');
      await obstacle.create();
      await expectLater(
        store.saveWorker(worker),
        throwsA(isA<FileSystemException>()),
      );
      expect(store.workers, isEmpty);
      expect(store.busy, isFalse);
      await obstacle.delete();
      await store.saveWorker(worker);
      expect(store.workers.single.id, worker.id);
    },
  );

  test('invalid backup leaves existing phone records unchanged', () async {
    await store.saveProfile(profile);
    await store.saveWorker(worker);
    final before = store.exportBackup();
    expect(
      () => store.restoreBackup('{"app":"Another app"}'),
      throwsFormatException,
    );
    final duplicate = LocalData(profile: profile, workers: [worker, worker]);
    expect(
      () => store.restoreBackup(jsonEncode(duplicate.toJson())),
      throwsFormatException,
    );
    expect(store.exportBackup(), before);
  });

  test('backup transfers the complete local profile and records', () async {
    await store.saveProfile(profile);
    await store.saveWorker(worker);
    await store.saveJob(appointment('job-1'));
    final otherDirectory = await Directory.systemTemp.createTemp(
      'khidmat-restore-',
    );
    final other = LocalStore(directory: otherDirectory);
    await other.initialize();
    await other.restoreBackup(store.exportBackup());
    expect(other.exportBackup(), store.exportBackup());
    other.dispose();
    await otherDirectory.delete(recursive: true);
  });

  test(
    'damaged primary file recovers the previous copy and preserves damage',
    () async {
      await store.saveProfile(profile);
      await store.saveWorker(worker);
      final main = File('${directory.path}/data.json');
      await main.writeAsString('broken-json');
      final reopened = LocalStore(directory: directory);
      await reopened.initialize();
      expect(reopened.initialized, isTrue);
      expect(reopened.profile!.name, profile.name);
      expect(reopened.notice, contains('Recovered'));
      expect(
        await File('${directory.path}/data.unreadable.json').readAsString(),
        'broken-json',
      );
      reopened.dispose();
    },
  );

  test(
    'two damaged files are retained and a validated backup can repair storage',
    () async {
      await store.saveProfile(profile);
      final validBackup = store.exportBackup();
      await File('${directory.path}/data.json').writeAsString('damaged-main');
      await File(
        '${directory.path}/data.previous.json',
      ).writeAsString('damaged-backup');
      final reopened = LocalStore(directory: directory);
      await reopened.initialize();
      expect(reopened.initialized, isFalse);
      expect(reopened.error, isNotNull);
      expect(
        await File('${directory.path}/data.json').readAsString(),
        'damaged-main',
      );
      await reopened.restoreBackup(validBackup);
      expect(reopened.initialized, isTrue);
      expect(reopened.error, isNull);
      expect(reopened.profile!.name, profile.name);
      reopened.dispose();
    },
  );

  test('removing a worker keeps appointment contact details', () async {
    await store.saveProfile(profile);
    await store.saveWorker(worker);
    await store.saveJob(appointment('job-1'));
    await store.removeWorker(worker.id);
    expect(store.workers, isEmpty);
    expect(store.jobs.single.contactId, isNull);
    expect(store.jobs.single.phone, worker.phone);
    expect(store.jobs.single.personName, worker.name);
    expect(store.inspectBackup(store.exportBackup()).jobs.length, 1);
  });

  test('duplicate appointments and reopening conflicts are rejected', () async {
    await store.saveProfile(profile);
    await store.saveWorker(worker);
    await store.saveJob(appointment('job-1'));
    await expectLater(
      store.saveJob(appointment('job-2')),
      throwsFormatException,
    );
    await store.saveJob(appointment('job-2', status: JobStatus.cancelled));
    await expectLater(
      store.updateStatus('job-2', JobStatus.confirmed),
      throwsFormatException,
    );
    expect(store.job('job-2')!.status, JobStatus.cancelled);
    await store.updateStatus('job-1', JobStatus.completed);
    await store.updateStatus('job-2', JobStatus.confirmed);
    expect(store.job('job-2')!.status, JobStatus.confirmed);
  });

  test('role switch retains records and filters each dashboard', () async {
    await store.saveProfile(profile);
    await store.saveWorker(worker);
    await store.saveJob(appointment('customer-job'));
    await store.saveJob(appointment('worker-job', role: AccountRole.worker));
    expect(store.roleJobs.single.id, 'customer-job');
    await store.saveProfile(
      const KhidmatProfile(
        name: 'Ali Khan',
        city: 'Lahore',
        role: AccountRole.worker,
        profession: 'Plumber',
        experienceYears: 8,
      ),
    );
    expect(store.roleJobs.single.id, 'worker-job');
    expect(store.jobs.length, 2);
  });

  test('new jobs in the past are rejected', () async {
    await store.saveProfile(profile);
    await expectLater(
      store.saveJob(
        JobRecord(
          id: 'past',
          role: AccountRole.customer,
          service: 'Cleaning',
          personName: 'Aslam',
          scheduledAt: DateTime(2001),
          address: 'Lahore',
        ),
      ),
      throwsFormatException,
    );
    expect(store.jobs, isEmpty);
  });

  test(
    'obsolete connection and auth preferences are removed while Urdu stays',
    () async {
      SharedPreferences.setMockInitialValues({
        'supabase_url': 'old-url',
        'supabase_key': 'old-key',
        'sb-old-auth-token': 'old-token',
        'app_language': 'ur',
      });
      final reopened = LocalStore(directory: directory);
      await reopened.initialize();
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getKeys(), {'app_language'});
      expect(preferences.getString('app_language'), 'ur');
      reopened.dispose();
    },
  );
}
