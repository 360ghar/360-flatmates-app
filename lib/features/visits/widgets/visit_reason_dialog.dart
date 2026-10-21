import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../shared/presentation/flatmates_button.dart';
import '../../shared/presentation/flatmates_dialog.dart';

/// The cancel route (`POST /visits/{id}/cancel`) stores a reason and refuses an
/// empty one, so the confirm dialog asks for it.
const int kVisitCancelReasonMaxLength = 1000;

/// Asks the user to confirm a visit cancel and to say why. Resolves to the
/// trimmed reason, or null when the user backs out.
Future<String?> askVisitCancelReason(BuildContext context) {
  final locale = AppLocalizations.of(context);
  var reason = '';
  return FlatmatesDialog.custom<String>(
    context,
    title: locale.visitCancelCta,
    body: (ctx, setState) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          locale.visitCancelConfirm,
          style: Theme.of(ctx).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        _ReasonField(
          label: locale.visitCancelReasonLabel,
          onChanged: (value) => setState(() => reason = value),
        ),
      ],
    ),
    actions: (ctx, setState, close) => [
      FlatmatesButton.tertiary(
        key: const Key('visit_cancel_dialog_back'),
        label: locale.cancelCta,
        onPressed: () => close(),
      ),
      FlatmatesButton(
        key: const Key('visit_cancel_dialog_confirm'),
        label: locale.visitCancelCta,
        destructive: true,
        onPressed: reason.trim().isEmpty ? null : () => close(reason.trim()),
      ),
    ],
  );
}

/// Owns the text controller so the dialog route disposes it with the field.
class _ReasonField extends StatefulWidget {
  const _ReasonField({required this.label, required this.onChanged});

  final String label;
  final ValueChanged<String> onChanged;

  @override
  State<_ReasonField> createState() => _ReasonFieldState();
}

class _ReasonFieldState extends State<_ReasonField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('visit_cancel_reason_field'),
      controller: _controller,
      minLines: 2,
      maxLines: 4,
      textInputAction: TextInputAction.newline,
      inputFormatters: [
        LengthLimitingTextInputFormatter(kVisitCancelReasonMaxLength),
      ],
      decoration: InputDecoration(labelText: widget.label),
      onChanged: widget.onChanged,
    );
  }
}
