import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/errors/l10n_bridge.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../shared/presentation/flatmates_card.dart';
import '../../shared/presentation/flatmates_header.dart';
import '../../shared/presentation/flatmates_screen.dart';
import '../../shared/presentation/flatmates_toast.dart';
import '../../shared/presentation/flatmates_ui.dart';
import '../application/feedback_controller.dart';
import '../domain/feedback_model.dart';

/// In-app feedback form for reporting a bug or requesting a feature.
///
/// Both variants submit to `POST /api/v1/bugs`; a feature request is simply a
/// bug report with `bug_type: "feature_request"`.
class FeedbackFormPage extends ConsumerStatefulWidget {
  const FeedbackFormPage({required this.type, super.key});

  final FeedbackType type;

  @override
  ConsumerState<FeedbackFormPage> createState() => _FeedbackFormPageState();
}

class _FeedbackFormPageState extends ConsumerState<FeedbackFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _submitting = false;
  String _bugType = 'functionality_bug';
  String _severity = 'medium';

  bool get _isBug => widget.type == FeedbackType.bug;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Same-frame double-tap guard: two taps can land before the rebuild
    // that disables the button.
    if (_submitting) return;
    final locale = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    final controller = ref.read(feedbackControllerProvider);
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    try {
      if (_isBug) {
        await controller.submitBugReport(
          title: title,
          description: description,
          bugType: _bugType,
          severity: _severity,
        );
      } else {
        await controller.submitFeatureRequest(
          title: title,
          description: description,
        );
      }
      if (!mounted) return;
      FlatmatesToast.success(context, locale.feedbackSubmitSuccess);
      context.pop();
    } catch (e) {
      debugPrint('FeedbackFormPage._submit failed: $e');
      if (!mounted) return;
      final msg = e is AppFailure
          ? e.userMessage(locale.toUserMessageL10n())
          : locale.errorUnknown;
      FlatmatesToast.error(context, msg);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final title = _isBug ? locale.reportABug : locale.requestAFeature;

    return FlatmatesScreen(
      appBar: FlatmatesHeader.backTitle(title: title),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.lg,
            AppSpacing.screen,
            AppSpacing.lg,
          ),
          children: [
            Text(
              _isBug ? locale.reportABugIntro : locale.requestAFeatureIntro,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppSemanticColors.textSecondaryFor(theme.brightness),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FlatmatesCard(
              child: Column(
                children: [
                  TextFormField(
                    key: const Key('feedback_title_field'),
                    controller: _titleController,
                    maxLength: 200,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: locale.feedbackTitleLabel,
                      hintText: _isBug
                          ? locale.feedbackTitleBugHint
                          : locale.feedbackTitleFeatureHint,
                    ),
                    validator: (value) {
                      final text = (value ?? '').trim();
                      if (text.isEmpty) {
                        return locale.feedbackTitleRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_isBug) ...[
                    DropdownButtonFormField<String>(
                      key: const Key('feedback_bug_type_field'),
                      // Long labels ellipsize instead of overflowing at 2x.
                      isExpanded: true,
                      initialValue: _bugType,
                      decoration: InputDecoration(
                        labelText: locale.feedbackBugTypeLabel,
                      ),
                      items: _bugTypeItems(locale),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _bugType = value);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    DropdownButtonFormField<String>(
                      key: const Key('feedback_severity_field'),
                      // Long labels ellipsize instead of overflowing at 2x.
                      isExpanded: true,
                      initialValue: _severity,
                      decoration: InputDecoration(
                        labelText: locale.feedbackSeverityLabel,
                      ),
                      items: _severityItems(locale),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _severity = value);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  TextFormField(
                    key: const Key('feedback_description_field'),
                    controller: _descriptionController,
                    minLines: 4,
                    maxLines: 8,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      labelText: locale.feedbackDescriptionLabel,
                      hintText: _isBug
                          ? locale.feedbackDescriptionBugHint
                          : locale.feedbackDescriptionFeatureHint,
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return locale.feedbackDescriptionRequired;
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FlatmatesButton(
              key: const Key('feedback_submit_button'),
              label: locale.feedbackSubmitCta,
              fullWidth: true,
              onPressed: _submitting ? null : _submit,
              icon: _submitting ? null : Icons.send_outlined,
            ),
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _bugTypeItems(AppLocalizations locale) {
    return [
      DropdownMenuItem(
        value: 'functionality_bug',
        child: Text(
          locale.feedbackBugTypeFunctionality,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      DropdownMenuItem(
        value: 'ui_bug',
        child: Text(locale.feedbackBugTypeUi, overflow: TextOverflow.ellipsis),
      ),
      DropdownMenuItem(
        value: 'performance_issue',
        child: Text(
          locale.feedbackBugTypePerformance,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      DropdownMenuItem(
        value: 'crash',
        child: Text(
          locale.feedbackBugTypeCrash,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      DropdownMenuItem(
        value: 'other',
        child: Text(
          locale.feedbackBugTypeOther,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ];
  }

  List<DropdownMenuItem<String>> _severityItems(AppLocalizations locale) {
    return [
      DropdownMenuItem(
        value: 'low',
        child: Text(
          locale.feedbackSeverityLow,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      DropdownMenuItem(
        value: 'medium',
        child: Text(
          locale.feedbackSeverityMedium,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      DropdownMenuItem(
        value: 'high',
        child: Text(
          locale.feedbackSeverityHigh,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      DropdownMenuItem(
        value: 'critical',
        child: Text(
          locale.feedbackSeverityCritical,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ];
  }
}
