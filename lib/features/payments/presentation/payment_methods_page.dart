import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../chats/application/cursor_list_controller.dart';
import '../../shared/presentation/flatmates_async_view.dart';
import '../../shared/presentation/flatmates_empty_state.dart';
import '../../shared/presentation/flatmates_header.dart';
import '../../shared/presentation/flatmates_skeleton.dart';
import '../../shared/presentation/flatmates_toast.dart';
import '../application/payments_controller.dart';
import '../domain/payment_method.dart';
import 'payment_method_tile.dart';

/// Lists the user's saved payment methods. Backed by
/// `GET /payments/methods` (cursor-paginated). The actual card capture
/// flow lives behind `AddPaymentMethodPage`; this page is read-only plus
/// per-row edit / delete.
class PaymentMethodsPage extends ConsumerStatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  ConsumerState<PaymentMethodsPage> createState() =>
      _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends ConsumerState<PaymentMethodsPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(paymentMethodsControllerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 240) {
      Future.microtask(() {
        if (!mounted) return;
        ref.read(paymentMethodsControllerProvider.notifier).loadMore();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final state = ref.watch(paymentMethodsControllerProvider);

    return Scaffold(
      appBar: FlatmatesHeader.titleAction(
        title: locale.paymentMethodsTitle,
        actions: [
          IconButton(
            tooltip: locale.addPaymentMethodCta,
            onPressed: () => context.push('/payments/methods/add'),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: FlatmatesAsyncView<CursorListState<PaymentMethod>>(
        value: state,
        isEmpty: (s) => s.items.isEmpty,
        loading: const FlatmatesSkeleton.list(),
        empty: FlatmatesEmptyState(
          title: locale.paymentMethodsEmpty,
          subtitle: locale.addPaymentMethodCta,
          icon: Icons.credit_card_off_outlined,
        ),
        onRetry: () =>
            ref.read(paymentMethodsControllerProvider.notifier).refresh(),
        data: (s) => RefreshIndicator(
          onRefresh: () =>
              ref.read(paymentMethodsControllerProvider.notifier).refresh(),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            itemCount: s.items.length + (s.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= s.items.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(
                    child: s.isLoadingMore
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : TextButton.icon(
                            onPressed: () => ref
                                .read(paymentMethodsControllerProvider.notifier)
                                .loadMore(),
                            icon: const Icon(Icons.expand_more_rounded),
                            label: Text(locale.loadMoreCta),
                          ),
                  ),
                );
              }
              final method = s.items[index];
              return PaymentMethodTile(
                key: ValueKey('payment_method_${method.id}'),
                method: method,
                onDeleted: (deleted) {
                  FlatmatesToast.info(
                    context,
                    locale.paymentMethodDeleteCta,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
