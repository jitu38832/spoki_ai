import 'dart:convert';
import 'dart:io';

/// Best-effort read of `secrets.json` next to the process cwd (e.g. project root on `flutter run`).
Future<String?> loadInworldKeyFromRootFile() async {
  try {
    final candidates = [
      File('secrets.json'),
      File('${Directory.current.path}/secrets.json'),
    ];
    for (final f in candidates) {
      if (await f.exists()) {
        final raw = await f.readAsString();
        final j = jsonDecode(raw);
        if (j is Map<String, dynamic>) {
          final k = j['INWORLD_API_KEY']?.toString().trim() ?? '';
          if (k.isNotEmpty) return k;
        }
      }
    }
  } catch (_) {}
  return null;
}
