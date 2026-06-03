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
import '../../shared/presentation/flatmates_ui.dart';
import '../data/feedback_repository.dart';
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

  // Only used for the bug variant.
  String _bugType = 'functionality_bug';
  String _severity = 'medium';

  bool _submitting = false;

  bool get _isBug => widget.type == FeedbackType.bug;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final locale = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    final repository = ref.read(feedbackRepositoryProvider);
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    try {
      if (_isBug) {
        await repository.submitBugReport(
          title: title,
          description: description,
          bugType: _bugType,
          severity: _severity,
        );
      } else {
        await repository.submitFeatureRequest(
          title: title,
          description: description,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(locale.feedbackSubmitSuccess)));
      context.pop();
    } on AppFailure catch (failure) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure.userMessage(locale.toUserMessageL10n())),
        ),
      );
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

    return Scaffold(
      appBar: FlatmatesHeader.backTitle(title: title),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppSemanticColors.accent.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    _isBug
                        ? Icons.bug_report_outlined
                        : Icons.lightbulb_outline,
                    size: 32,
                    color: AppSemanticColors.accent,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                _isBug ? locale.reportABugIntro : locale.requestAFeatureIntro,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppSemanticColors.textSecondaryFor(theme.brightness),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
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
              const SizedBox(height: AppSpacing.section),
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
      ),
    );
  }

  List<DropdownMenuItem<String>> _bugTypeItems(AppLocalizations locale) {
    return [
      DropdownMenuItem(
        value: 'functionality_bug',
        child: Text(locale.feedbackBugTypeFunctionality),
      ),
      DropdownMenuItem(value: 'ui_bug', child: Text(locale.feedbackBugTypeUi)),
      DropdownMenuItem(
        value: 'performance_issue',
        child: Text(locale.feedbackBugTypePerformance),
      ),
      DropdownMenuItem(
        value: 'crash',
        child: Text(locale.feedbackBugTypeCrash),
      ),
      DropdownMenuItem(
        value: 'other',
        child: Text(locale.feedbackBugTypeOther),
      ),
    ];
  }

  List<DropdownMenuItem<String>> _severityItems(AppLocalizations locale) {
    return [
      DropdownMenuItem(value: 'low', child: Text(locale.feedbackSeverityLow)),
      DropdownMenuItem(
        value: 'medium',
        child: Text(locale.feedbackSeverityMedium),
      ),
      DropdownMenuItem(value: 'high', child: Text(locale.feedbackSeverityHigh)),
      DropdownMenuItem(
        value: 'critical',
        child: Text(locale.feedbackSeverityCritical),
      ),
    ];
  }
}
