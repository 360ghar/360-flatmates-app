import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';

/// Shows a dialog for reporting a listing and returns the selected reason,
/// or null if the user cancels.
Future<String?> showReportListingDialog(BuildContext context) {
  final locale = AppLocalizations.of(context);
  final reasons = [
    locale.reportReasonInappropriate,
    locale.reportReasonScam,
    locale.reportReasonOutdated,
    locale.reportReasonOther,
  ];

  return showDialog<String>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(locale.reportListingTitle),
      children: reasons
          .map(
            (reason) => SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(reason),
              child: Text(reason),
            ),
          )
          .toList(),
    ),
  );
}
