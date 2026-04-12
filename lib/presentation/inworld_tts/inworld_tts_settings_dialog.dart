import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spokiai/core/config/inworld_tts_config.dart';
import 'package:spokiai/core/inworld_tts_voice_catalog.dart';
import 'package:spokiai/logic/inworld_tts/inworld_tts_cubit.dart';
import 'package:spokiai/logic/inworld_tts/inworld_tts_state.dart';

Future<void> showInworldTtsSettingsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => BlocProvider.value(
      value: context.read<InworldTtsCubit>(),
      child: const _InworldTtsSettingsDialogBody(),
    ),
  );
}

class _InworldTtsSettingsDialogBody extends StatefulWidget {
  const _InworldTtsSettingsDialogBody();

  @override
  State<_InworldTtsSettingsDialogBody> createState() =>
      _InworldTtsSettingsDialogBodyState();
}

class _InworldTtsSettingsDialogBodyState
    extends State<_InworldTtsSettingsDialogBody> {
  late String _draftMale;
  late String _draftFemale;
  late final TextEditingController _modelController;

  @override
  void initState() {
    super.initState();
    final s = context.read<InworldTtsCubit>().state;
    _draftMale = s.maleVoiceId.isNotEmpty
        ? s.maleVoiceId
        : defaultInworldMaleVoiceId;
    if (!isMaleInworldVoiceId(_draftMale)) {
      _draftMale = defaultInworldMaleVoiceId;
    }
    _draftFemale = s.femaleVoiceId.isNotEmpty
        ? s.femaleVoiceId
        : defaultInworldFemaleVoiceId;
    if (!isFemaleInworldVoiceId(_draftFemale)) {
      _draftFemale = defaultInworldFemaleVoiceId;
    }
    _modelController = TextEditingController(
      text: s.modelId.isNotEmpty ? s.modelId : InworldTtsConfig.defaultModelId,
    );
  }

  @override
  void dispose() {
    _modelController.dispose();
    super.dispose();
  }

  Widget _voiceTile(
    InworldTtsVoiceEntry entry, {
    required bool maleSection,
  }) {
    final selected = maleSection
        ? _draftMale == entry.voiceId
        : _draftFemale == entry.voiceId;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(entry.displayName),
      subtitle: entry.isDefault
          ? const Text(
              'Default',
              style: TextStyle(fontSize: 11),
            )
          : null,
      selected: selected,
      selectedTileColor: Theme.of(context)
          .colorScheme
          .primaryContainer
          .withValues(alpha: 0.35),
      onTap: () => setState(() {
        if (maleSection) {
          _draftMale = entry.voiceId;
        } else {
          _draftFemale = entry.voiceId;
        }
      }),
      trailing: selected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Voice settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Inworld voice (male)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...kInworldMaleVoices.map(
              (e) => _voiceTile(e, maleSection: true),
            ),
            const SizedBox(height: 12),
            Text(
              'Inworld voice (female)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...kInworldFemaleVoices.map(
              (e) => _voiceTile(e, maleSection: false),
            ),
            const SizedBox(height: 16),
            Text(
              'Model',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _modelController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                hintText: InworldTtsConfig.defaultModelId,
              ),
            ),
            const SizedBox(height: 12),
            BlocBuilder<InworldTtsCubit, InworldTtsState>(
              buildWhen: (a, b) =>
                  a.status != b.status || a.errorMessage != b.errorMessage,
              builder: (context, state) {
                if (state.status == InworldTtsStatus.error &&
                    (state.errorMessage?.isNotEmpty ?? false)) {
                  return Text(
                    state.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final cubit = context.read<InworldTtsCubit>();
            final modelDraft = _modelController.text.trim();
            await cubit.setMaleVoice(_draftMale);
            await cubit.setFemaleVoice(_draftFemale);
            await cubit.setModel(
              modelDraft.isEmpty
                  ? InworldTtsConfig.defaultModelId
                  : modelDraft,
            );
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
