import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spokiai/view/utils/custom_widgets.dart';

/// Saves [bytes] to the first writable location (public Downloads → app Documents).
///
/// Folder: `Spoki AI` inside each candidate root. [safeFileStem] must not contain `.pdf`.
Future<File?> writeStoryPdfWithFallback({
  required List<int> bytes,
  required String safeFileStem,
}) async {
  final candidateDirs = <Directory>[];

  final downloadsDir = await getDownloadsDirectory();
  if (downloadsDir != null) {
    candidateDirs.add(Directory('${downloadsDir.path}/Spoki AI'));
  }
  if (Platform.isAndroid) {
    candidateDirs.add(Directory('/storage/emulated/0/Download/Spoki AI'));
  }
  final appDocs = await getApplicationDocumentsDirectory();
  candidateDirs.add(Directory('${appDocs.path}/Spoki AI'));

  File? savedFile;
  for (final folder in candidateDirs) {
    try {
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }
      final file = File('${folder.path}/$safeFileStem.pdf');
      await file.writeAsBytes(bytes, flush: true);
      if (await file.exists() && await file.length() > 0) {
        savedFile = file;
        break;
      }
    } catch (_) {
      continue;
    }
  }
  return savedFile;
}

/// After a PDF is saved, shows a dialog with **Open** to launch the viewer.
Future<void> presentPdfSavedOpenDialog({
  required BuildContext context,
  required File savedFile,
}) async {
  if (!context.mounted) return;

  final name = savedFile.path.split(Platform.pathSeparator).last;

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return AlertDialog(
        title: const Text('PDF saved'),
        content: SingleChildScrollView(
          child: Text(
            name,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await openPdfExternal(context: context, path: savedFile.path);
            },
            child: const Text('Open'),
          ),
        ],
      );
    },
  );
}

/// Opens PDF with default app; shows toast if launcher fails.
Future<void> openPdfExternal({
  required BuildContext context,
  required String path,
}) async {
  try {
    final result = await OpenFilex.open(
      path,
      type: 'application/pdf',
    );

    if (!context.mounted) return;

    switch (result.type) {
      case ResultType.done:
        return;
      case ResultType.noAppToOpen:
        showToast(
          context: context,
          message: 'Install a PDF reader from the store to open this file.',
        );
        return;
      case ResultType.fileNotFound:
      case ResultType.permissionDenied:
      case ResultType.error:
        final msg = result.message.trim();
        showToast(
          context: context,
          message: msg.isEmpty ? 'Could not open this PDF.' : msg,
        );
    }
  } catch (e) {
    if (!context.mounted) return;
    showToast(context: context, message: 'Could not open PDF: $e');
  }
}
