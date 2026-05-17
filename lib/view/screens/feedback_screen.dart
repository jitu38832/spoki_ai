import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spokiai/model/commonresponse.dart';
import 'package:spokiai/view/utils/colors.dart';
import 'package:spokiai/view/utils/custom_widgets.dart';
import 'package:spokiai/view/utils/preference_manager.dart';
import 'package:spokiai/viewmodel/cubit/app_state.dart';
import 'package:spokiai/viewmodel/cubit/appcubit.dart';

/// ~20% smaller type/icons on the feedback screen only.
double _feedbackFs(double px) => px * 0.8;

enum _FeedbackKind { bug, suggestion }

/// Unified bug report + improvement suggestion (matches product mockups).
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  _FeedbackKind _kind = _FeedbackKind.bug;
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

  static const int _maxDesc = 500;
  static const int _maxUploadBytes = 5 * 1024 * 1024;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (x == null || !mounted) return;
    final path = x.path;
    final lower = path.toLowerCase();
    if (!lower.endsWith('.png') &&
        !lower.endsWith('.jpg') &&
        !lower.endsWith('.jpeg')) {
      if (!mounted) return;
      showToast(
        context: context,
        message: 'Please choose a PNG or JPG image.',
      );
      return;
    }
    final len = await File(path).length();
    if (len > _maxUploadBytes) {
      if (!mounted) return;
      showToast(
        context: context,
        message: 'Image must be 5MB or smaller.',
      );
      return;
    }
    setState(() => _imagePath = path);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final token = PreferenceManager.getStringValue(key: 'token') ?? '';
    if (token.isEmpty) {
      showToast(context: context, message: 'Please sign in again.');
      return;
    }
    context.read<AppCubit>().submitFeedback(
          token: token,
          type: _kind == _FeedbackKind.bug ? 'bug' : 'suggestion',
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          screenshotPath: _imagePath,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = theme.scaffoldBackgroundColor;
    final border = textFieldBorderColor;

    final titleStr = _kind == _FeedbackKind.bug
        ? 'Give Feedback'
        : 'Suggest Improvement';
    final subtitle = _kind == _FeedbackKind.bug
        ? 'We value your feedback! Let us know how we can improve Spoki AI for you.'
        : 'Share your ideas to help us make Spoki AI even better!';
    final titleLabel =
        _kind == _FeedbackKind.bug ? 'Issue Title *' : 'Idea Title *';
    final titleHint = _kind == _FeedbackKind.bug
        ? 'Short title of the issue.'
        : 'Short title for your suggestion';
    final descLabel = _kind == _FeedbackKind.bug
        ? 'Describe the issue *'
        : 'Describe your idea *';
    final descHint = _kind == _FeedbackKind.bug
        ? 'Please describe the issue in detail...'
        : 'Please describe your suggestion in detail...';
    final bannerText = _kind == _FeedbackKind.bug
        ? 'Your feedback helps us improve Spoki AI. We may contact you for more details if needed.'
        : 'Your suggestion helps us improve Spoki AI. We may contact you for more details if needed.';

    return BlocListener<AppCubit, AppStates>(
      listenWhen: (p, c) => p.status != c.status,
      listener: (context, state) {
        if (state.status == AppStatus.submitFeedbackSuccess) {
          final msg = state.responseData?.response is CommonResponse
              ? (state.responseData!.response as CommonResponse)
                      .message ??
                  'Thank you!'
              : 'Thank you!';
          showToast(context: context, message: msg);
          context.read<AppCubit>().resetToInitial();
          Navigator.of(context).pop();
        } else if (state.status == AppStatus.submitFeedbackError) {
          final msg = state.errorData?.message ??
              state.error ??
              'Something went wrong';
          showToast(context: context, message: msg);
          context.read<AppCubit>().resetToInitial();
        }
      },
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: theme.colorScheme.onSurface),
            iconSize: _feedbackFs(24),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            titleStr,
            style: GoogleFonts.inter(
              color: theme.colorScheme.onSurface,
              fontSize: _feedbackFs(18),
              fontWeight: FontWeight.w800,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: _feedbackFs(13.5),
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                _KindToggle(
                  kind: _kind,
                  onChanged: (k) => setState(() => _kind = k),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                  decoration: BoxDecoration(
                    color: cardSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: border),
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        titleLabel,
                        style: GoogleFonts.inter(
                          fontSize: _feedbackFs(13),
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        style: GoogleFonts.inter(
                          fontSize: _feedbackFs(14),
                          color: textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: titleHint,
                          hintStyle: GoogleFonts.inter(
                            fontSize: _feedbackFs(14),
                            color: textMuted,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF252530)
                              : const Color(0xFFFAFAFA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: appColor, width: 1.4),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        descLabel,
                        style: GoogleFonts.inter(
                          fontSize: _feedbackFs(13),
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descCtrl,
                        minLines: 5,
                        maxLines: 8,
                        maxLength: _maxDesc,
                        textCapitalization: TextCapitalization.sentences,
                        style: GoogleFonts.inter(
                          fontSize: _feedbackFs(14),
                          color: textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: descHint,
                          hintStyle: GoogleFonts.inter(
                            fontSize: _feedbackFs(14),
                            color: textMuted,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF252530)
                              : const Color(0xFFFAFAFA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: appColor, width: 1.4),
                          ),
                          alignLabelWithHint: true,
                          contentPadding: const EdgeInsets.fromLTRB(
                            14,
                            14,
                            14,
                            12,
                          ),
                          counterText: '',
                        ),
                        buildCounter: (
                          _,
                          {
                            required currentLength,
                            required isFocused,
                            maxLength,
                          }) =>
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '$currentLength/${maxLength ?? _maxDesc}',
                                  style: GoogleFonts.inter(
                                    fontSize: _feedbackFs(12),
                                    color: textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Required';
                          }
                          if (v.trim().length > _maxDesc) {
                            return 'Max $_maxDesc characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Add Screenshot (Optional)',
                        style: GoogleFonts.inter(
                          fontSize: _feedbackFs(13),
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _pickImage,
                          borderRadius: BorderRadius.circular(12),
                          child: Ink(
                            height: _imagePath == null ? 120 : null,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF252530)
                                  : const Color(0xFFFAFAFA),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: appColor.withValues(alpha: 0.45),
                                width: 1.2,
                              ),
                            ),
                            child: _imagePath == null
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.image_outlined,
                                          color: appColor,
                                          size: _feedbackFs(32),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Tap to upload screenshot',
                                          style: GoogleFonts.inter(
                                            fontSize: _feedbackFs(13),
                                            fontWeight: FontWeight.w600,
                                            color: appColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'PNG, JPG up to 5MB',
                                          style: GoogleFonts.inter(
                                            fontSize: _feedbackFs(11.5),
                                            color: textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          File(_imagePath!),
                                          height: 140,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextButton.icon(
                                        onPressed: () =>
                                            setState(() => _imagePath = null),
                                        icon: Icon(Icons.close_rounded,
                                            size: _feedbackFs(18),
                                            color: errorColor),
                                        label: Text(
                                          'Remove',
                                          style: GoogleFonts.inter(
                                            fontSize: _feedbackFs(13),
                                            color: errorColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                        decoration: BoxDecoration(
                          color: appColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              color: appColor,
                              size: _feedbackFs(22),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                bannerText,
                                style: GoogleFonts.inter(
                                  fontSize: _feedbackFs(12.5),
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                  color: textPrimary.withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      BlocBuilder<AppCubit, AppStates>(
                        buildWhen: (p, c) => p.status != c.status,
                        builder: (context, state) {
                          final loading =
                              state.status == AppStatus.submitFeedbackLoading;
                          return button(
                            context: context,
                            width: double.infinity,
                            title: 'Submit',
                            fontSize: _feedbackFs(15),
                            fontWeight: FontWeight.w800,
                            isLoading: loading,
                            icon: Icons.send_rounded,
                            onPressed: loading ? null : _submit,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline_rounded,
                        size: _feedbackFs(15), color: textMuted),
                    const SizedBox(width: 6),
                    Text(
                      'Your feedback is private and secure.',
                      style: GoogleFonts.inter(
                        fontSize: _feedbackFs(12),
                        color: textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KindToggle extends StatelessWidget {
  const _KindToggle({
    required this.kind,
    required this.onChanged,
  });

  final _FeedbackKind kind;
  final ValueChanged<_FeedbackKind> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ToggleChip(
            selected: kind == _FeedbackKind.bug,
            icon: Icons.bug_report_outlined,
            label: 'Report a Bug',
            onTap: () => onChanged(_FeedbackKind.bug),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ToggleChip(
            selected: kind == _FeedbackKind.suggestion,
            icon: Icons.lightbulb_outline_rounded,
            label: 'Suggest Improvement',
            onTap: () => onChanged(_FeedbackKind.suggestion),
          ),
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: selected ? purpleGradient : null,
            color: selected ? null : cardSurface,
            border: Border.all(
              color: selected ? Colors.transparent : appColor.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: appColor.withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: _feedbackFs(18),
                color: selected ? Colors.white : appColor,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: _feedbackFs(11.5),
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : textPrimary,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
