library bloobit;

import 'package:flutter/material.dart';

///Use this like a Cubit from the Bloc library
///It's modeled after it Cubit and faciliates separation of Business Logic and
///the View. But doesn't use streams by default
///
///However, it does have a callback so you can hook up a stream if you want
///See the main function for an example of this
class Bloobit<TState> {
  Bloobit(this.initialState, {void Function(TState)? callback})
      : _state = initialState,
        callback = callback ?? ((s) {});

  late final void Function(VoidCallback fn)? _setState;
  final TState initialState;
  final void Function(TState) callback;
  TState _state;

  TState get state => _state;

  ///Pass in the setState function from your state here
  void attach(Function(VoidCallback fn) setState) => _setState = setState;

  void emit(TState state) {
    assert(_setState != null, 'You must call attach');

    //This is kind of controversial to me.
    //Depending on overriding the == operator is a bit of a code smell
    //Leaving this here for now so it works in a similar way to Cubit
    //but this may change
    if (state == _state) {
      return;
    }

    //This is so we can hook up a stream or any other reactive listener
    callback(_state);

    _setState!(() {
      _state = state;
    });
  }
}

///Use with State class to automate the attach method
mixin AttachesSetState<TWidget extends StatefulWidget,
    TCallsSetState extends Bloobit> on State<TWidget> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    BloobitPropagator.of<TCallsSetState>(context).bloobit.attach(setState);
  }
}

///This inherited widget propagates the Bloobit down the widget tree
///much like Provider
class BloobitPropagator<T extends Bloobit> extends InheritedWidget {
  const BloobitPropagator({
    required this.bloobit,
    required Widget child,
    final Key? key,
  }) : super(key: key, child: child);

  final T bloobit;

  static BloobitPropagator<T> of<T extends Bloobit>(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<BloobitPropagator<T>>();
    assert(result != null, 'No Bloobit of type $T found in context');

    return result!;
  }

  @override
  bool updateShouldNotify(covariant final InheritedWidget oldWidget) =>
      bloobit != (oldWidget as BloobitPropagator<T>).bloobit;
}
