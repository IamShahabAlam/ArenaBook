import 'package:flutter/widgets.dart';

/// Closes the keyboard when the user touches anywhere outside the focused text field (a tap or the start of a drag).
/// Flutter does this on desktop and web only; phones keep the keyboard open by default. Wrap the app once.
class KeyboardDismisser extends StatelessWidget {
  const KeyboardDismisser({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: {EditableTextTapOutsideIntent: CallbackAction<EditableTextTapOutsideIntent>(onInvoke: (intent) => intent.focusNode.unfocus())},
      child: child,
    );
  }
}
