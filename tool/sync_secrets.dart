// Copies project-root secrets.json (gitignored) into assets/secrets.json for mobile builds.
// Run: dart run tool/sync_secrets.dart
import 'dart:io';

void main() {
  final root = File('secrets.json');
  if (!root.existsSync()) {
    stderr.writeln(
      'Missing secrets.json in project root. Copy secrets.example.json → secrets.json',
    );
    exit(1);
  }
  final dest = File('assets/secrets.json');
  dest.parent.createSync(recursive: true);
  dest.writeAsStringSync(root.readAsStringSync());
  stdout.writeln('OK: secrets.json → assets/secrets.json');
}
