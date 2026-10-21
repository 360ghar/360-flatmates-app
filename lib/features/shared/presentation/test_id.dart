import 'package:flutter/widgets.dart';

/// Exposes a string [key] (for example `Key('login_submit_button')`) as
/// `Semantics.identifier`, the only id Maestro can read: Flutter keys never
/// reach the accessibility layer. One key then serves widget tests
/// (`find.byKey`) and Maestro flows (`id:`). Any other key passes [child]
/// through unchanged.
///
/// `container: true` gives the id its own semantics node with the child's
/// bounds, so a Maestro tap lands on the widget, not on a merged ancestor.
Widget withTestId(Key? key, Widget child) => key is ValueKey<String>
    ? Semantics(identifier: key.value, container: true, child: child)
    : child;
