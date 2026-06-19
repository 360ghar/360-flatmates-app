import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/errors/l10n_bridge.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/payments_controller.dart';
import '../data/payment_method_dto.dart';
import '../domain/payment_method.dart';

/// Single-row tile for a saved payment method. Exposes edit (default /
/// nickname) and delete actions via a long-press menu so the row stays
/// tappable for primary navigation flows.
class PaymentMethodTile extends ConsumerWidget {
  const PaymentMethodTile({
    required this.method,
    required this.onDeleted,
    super.key,
  });

  final PaymentMethod method;
  final ValueChanged<PaymentMethod> onDeleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final last4 = method.last4;
    final title = last4 != null && last4.isNotEmpty
        ? locale.paymentMethodCardEnding(last4)
        : (method.nickname ??
            paymentMethodBrandLabel(method.brand ?? method.methodType));

    final subtitle = [
      paymentMethodBrandLabel(method.brand ?? method.methodType),
      if (method.nickname != null && method.nickname!.trim().isNotEmpty)
        method.nickname!,
    ].join(' • ');

    return InkWell(
      onLongPress: () => _showActions(context, ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? AppSemanticColors.blueSoftDark
                    : AppSemanticColors.blueSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                _iconForMethod(method.methodType),
                color: AppSemanticColors.blueMid,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (method.isDefault) ...[
                        const SizedBox(width: AppSpacing.sm),
                        _DefaultBadge(),
                      ],
                    ],
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppSemanticColors.textSecondaryFor(
                          theme.brightness,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'More options',
              onPressed: () => _showActions(context, ref),
              icon: const Icon(Icons.more_vert_rounded),
            ),
          ],
        ),
      ),
    );
  }

  void _showActions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final locale = AppLocalizations.of(ctx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(locale.paymentMethodNicknameLabel),
                subtitle: Text(method.nickname ?? ''),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final newNickname = await _promptNickname(context);
                  if (newNickname == null) return;
                  await _safeUpdate(
                    ref,
                    nickname: newNickname,
                    errorLabel: locale.paymentMethodsUpdateFailed,
                    locale: locale,
                  );
                },
              ),
              if (!method.isDefault)
                ListTile(
                  leading: const Icon(Icons.star_outline_rounded),
                  title: Text(locale.paymentMethodSetDefaultCta),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await _safeUpdate(
                      ref,
                      isDefault: true,
                      errorLabel: locale.paymentMethodsUpdateFailed,
                      locale: locale,
                    );
                  },
                ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                ),
                title: Text(
                  locale.paymentMethodDeleteCta,
                  style: const TextStyle(color: Colors.redAccent),
                ),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final confirmed = await _confirmDelete(context);
                  if (confirmed != true) return;
                  if (!context.mounted) return;
                  try {
                    await ref
                        .read(paymentMethodsControllerProvider.notifier)
                        .delete(method.id);
                    if (!context.mounted) return;
                    onDeleted(method);
                  } catch (e) {
                    if (!context.mounted) return;
                    final msg = e is AppFailure
                        ? e.userMessage(locale.toUserMessageL10n())
                        : locale.paymentMethodsDeleteFailed;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(msg)),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _promptNickname(BuildContext context) async {
    final locale = AppLocalizations.of(context);
    final controller = TextEditingController(text: method.nickname ?? '');
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(locale.paymentMethodNicknameLabel),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: locale.paymentMethodNicknameHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(locale.cancelCta),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(locale.commonSave),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<bool?> _confirmDelete(BuildContext context) async {
    final locale = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(locale.paymentMethodDeleteConfirmTitle),
        content: Text(locale.paymentMethodDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(locale.cancelCta),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(locale.paymentMethodDeleteConfirmCta),
          ),
        ],
      ),
    );
  }

  Future<void> _safeUpdate(
    WidgetRef ref, {
    String? nickname,
    bool? isDefault,
    required String errorLabel,
    required AppLocalizations locale,
  }) async {
    try {
      await ref.read(paymentMethodsControllerProvider.notifier).update(
            method.id,
            PaymentMethodUpdateDto(nickname: nickname, isDefault: isDefault),
          );
    } catch (e) {
      final msg = e is AppFailure
          ? e.userMessage(locale.toUserMessageL10n())
          : errorLabel;
      debugPrint('PaymentMethodTile: update failed: $e');
      // Toast is surfaced by the caller via ScaffoldMessenger; here we only
      // log so we don't double-toast when the modal is still alive.
    }
  }

  IconData _iconForMethod(String methodType) {
    switch (methodType.toLowerCase()) {
      case 'card':
      case 'credit_card':
      case 'debit_card':
        return Icons.credit_card_rounded;
      case 'upi':
        return Icons.account_balance_wallet_outlined;
      case 'netbanking':
        return Icons.account_balance_outlined;
      case 'wallet':
        return Icons.wallet_outlined;
      default:
        return Icons.payment_outlined;
    }
  }
}

class _DefaultBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? AppSemanticColors.greenSoftDark
            : AppSemanticColors.greenSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        locale.paymentMethodDefaultBadge,
        style: theme.textTheme.labelSmall?.copyWith(
          color: AppSemanticColors.greenMid,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
