library bloobit;

import 'package:flutter/material.dart';

///This faciliates separation of Business Logic and Presentation. You must extend it.
///Pass the setState function in by calling attach, or use [BloobitPropagator] to do it for you.
///The [Bloobit] will call the setState function when [emit] is called.
abstract class Bloobit<TState> {
  Bloobit(this.initialState, {void Function(TState)? onSetState})
      : _state = initialState,
        onSetState = onSetState ?? ((s) {});

  late final void Function(VoidCallback fn)? _setState;

  ///This is the state of the Bloobit on construction
  final TState initialState;

  //When state changes, the Bloobit calls this
  final void Function(TState) onSetState;
  TState _state;

  ///This is the current state of the Bloobit
  TState get state => _state;

  ///Pass in the setState function from your state here
  void attach(void Function(VoidCallback fn) setState) => _setState = setState;

  ///This calls the setState function and updates the state
  void emit(TState state) {
    assert(_setState != null, 'You must call attach');

    //This is so we can hook up a stream or any other reactive listener
    onSetState(_state);

    _setState!(() {
      _state = state;
    });
  }
}

///Use with State class to automate the attach method
mixin AttachesSetState<TWidget extends StatefulWidget,
    TCallsSetState extends Bloobit<dynamic>> on State<TWidget> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    BloobitPropagator.of<TCallsSetState>(context).bloobit.attach(setState);
  }
}

///This InheritedWidget propagates the [Bloobit] down the widget tree
///much like Provider
class BloobitPropagator<T extends Bloobit<dynamic>> extends InheritedWidget {
  const BloobitPropagator({
    required this.bloobit,
    required Widget child,
    final Key? key,
  }) : super(key: key, child: child);

  ///This is the [Bloobit] that will be propagated
  final T bloobit;

  ///Gets the [Bloobit] from the widget tree
  static BloobitPropagator<T> of<T extends Bloobit<dynamic>>(
      BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<BloobitPropagator<T>>();
    assert(result != null, 'No Bloobit of type $T found in context');

    return result!;
  }

  @override
  bool updateShouldNotify(covariant final InheritedWidget oldWidget) =>
      bloobit != (oldWidget as BloobitPropagator<T>).bloobit;
}
