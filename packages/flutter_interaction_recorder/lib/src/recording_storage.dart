import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'recording_session.dart';

/// Persists [RecordingSession]s to disk as JSON files.
///
/// Recordings are stored in a `recordings` directory inside the
/// app's documents folder. Each recording is a separate `.json`
/// file named after the session ID.
///
/// Accounts ([TestAccount]) are stored in an `accounts.json` file
/// and can be used to parameterize test flows with different
/// credentials and roles.
class RecordingStorage {
  Directory? _dir;

  /// Gets (or creates) the recordings directory.
  Future<Directory> _getDir() async {
    if (_dir != null) return _dir!;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/recordings');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    _dir = dir;
    return dir;
  }

  /// Saves a recording session to disk.
  Future<String> save(RecordingSession session) async {
    final dir = await _getDir();
    final file = File('${dir.path}/${session.id}.json');
    await file.writeAsString(jsonEncode(session.toJson()));
    return file.path;
  }

  /// Loads a recording session by ID.
  Future<RecordingSession?> load(String id) async {
    final dir = await _getDir();
    final file = File('${dir.path}/$id.json');
    if (!file.existsSync()) return null;
    final json = jsonDecode(await file.readAsString());
    return RecordingSession.fromJson(json as Map<String, dynamic>);
  }

  /// Lists all saved recording sessions (sorted by start time, newest first).
  Future<List<RecordingSession>> listAll() async {
    final dir = await _getDir();
    final files = dir
        .listSync()
        .where((f) => f is File && f.path.endsWith('.json') && !f.path.endsWith('accounts.json'))
        .cast<File>()
        .toList();

    final sessions = <RecordingSession>[];
    for (final file in files) {
      try {
        final json = jsonDecode(file.readAsStringSync());
        sessions.add(RecordingSession.fromJson(json as Map<String, dynamic>));
      } catch (_) {
        // Skip corrupt files
      }
    }

    sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
    return sessions;
  }

  /// Deletes a recording by ID.
  Future<void> delete(String id) async {
    final dir = await _getDir();
    final file = File('${dir.path}/$id.json');
    if (file.existsSync()) file.deleteSync();
  }

  /// Exports a recording as a JSON string (for sharing or processing
  /// by the AI skill).
  Future<String> export(RecordingSession session) async {
    return jsonEncode(session.toJson());
  }

  // ── Account management ──────────────────────────────────────

  /// Loads all saved test accounts.
  Future<List<TestAccount>> loadAccounts() async {
    final dir = await _getDir();
    final file = File('${dir.path}/accounts.json');
    if (!file.existsSync()) return [];
    final json = jsonDecode(file.readAsStringSync()) as List;
    return json.map((e) => TestAccount.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Saves the list of test accounts.
  Future<void> saveAccounts(List<TestAccount> accounts) async {
    final dir = await _getDir();
    final file = File('${dir.path}/accounts.json');
    await file.writeAsString(jsonEncode(accounts.map((a) => a.toJson()).toList()));
  }

  /// Adds a single test account.
  Future<void> addAccount(TestAccount account) async {
    final accounts = await loadAccounts();
    accounts.removeWhere((a) => a.name == account.name);
    accounts.add(account);
    await saveAccounts(accounts);
  }

  /// Removes a test account by name.
  Future<void> removeAccount(String name) async {
    final accounts = await loadAccounts();
    accounts.removeWhere((a) => a.name == name);
    await saveAccounts(accounts);
  }
}
