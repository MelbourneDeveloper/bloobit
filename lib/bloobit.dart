library bloobit;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

///This faciliates separation of Business Logic and Presentation. You must
///extend it. Pass the setState function in by calling attach, or use
///[BloobitPropagator] to do it for you. The [Bloobit] will call the setState
///function when [setState] is called.
abstract class Bloobit<TState> {
  ///Creates a [Bloobit] with the initial state.
  Bloobit(this.initialState, {void Function(TState)? onSetState})
      : _state = initialState,
        onSetState = onSetState ??
            ((s)
                //ignore: no-empty-block
                {});

  void Function(VoidCallback fn)? _setState;

  ///This is the state of the Bloobit on construction
  final TState initialState;

  ///When state changes, the Bloobit calls this. Use this to feed state changes
  ///to a Stream
  final void Function(TState) onSetState;

  ///This is the current state of the Bloobit
  TState get state => _state;

  TState _state;

  ///Pass in the setState function from your state here
  // ignore: use_setters_to_change_properties
  void attach(void Function(VoidCallback fn) setState) => _setState = setState;

  ///This calls the setState() function and updates the state in the setState()
  ///callback
  void setState(TState state) {
    assert(_setState != null, 'You must call attach');

    //This is so we can hook up a stream or any other reactive listener
    onSetState(_state);

    _setState!(() {
      _state = state;
    });
  }
}

///Use with State class to automate the attach method
///Note: attach will not call setState if the state is not mounted
mixin AttachesSetState<TWidget extends StatefulWidget,
    TCallsSetState extends Bloobit<dynamic>> on State<TWidget> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    BloobitPropagator.of<TCallsSetState>(context)
        .bloobit
        .attach((s) => mounted ? setState(s) : null);
  }
}

///This InheritedWidget propagates the [Bloobit] down the widget tree
///much like Provider
class BloobitPropagator<T extends Bloobit<dynamic>> extends InheritedWidget {
  ///Creates and instance of BloobitPropagator
  const BloobitPropagator({
    required this.bloobit,
    required super.child,
    super.key,
  });

  ///This is the [Bloobit] that will be propagated
  final T bloobit;

  ///The state of the bloobit
  dynamic get state => bloobit.state;

  ///Gets the [Bloobit] from the widget tree
  static BloobitPropagator<T> of<T extends Bloobit<dynamic>>(
    BuildContext context,
  ) {
    final result =
        context.dependOnInheritedWidgetOfExactType<BloobitPropagator<T>>();
    assert(result != null, 'No Bloobit of type $T found in context');

    return result!;
  }

  @override
  bool updateShouldNotify(
    covariant InheritedWidget oldWidget,
  ) =>
      bloobit != (oldWidget as BloobitPropagator<T>).bloobit;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<T>('bloobit', bloobit))
      ..add(DiagnosticsProperty<dynamic>('state', state));
  }
}
