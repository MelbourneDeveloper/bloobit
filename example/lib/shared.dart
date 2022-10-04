// ignore_for_file: diagnostic_describe_all_properties

import 'package:flutter/material.dart';

///The immutable state of the app
@immutable
class AppState {
  const AppState(
    this.callCount,
    this.isProcessing,
    this.displayWidgets,
  );
  final int callCount;
  final bool isProcessing;
  final bool displayWidgets;

  AppState copyWith({
    int? callCount,
    bool? isProcessing,
    bool? displayWidgets,
  }) =>
      AppState(
        callCount ?? this.callCount,
        isProcessing ?? this.isProcessing,
        displayWidgets ?? this.displayWidgets,
      );
}

///This emulates a server that counts the number of times it has been called.
class CountServerService {
  int _counter = 0;
  Future<int> getCallCount() =>
      Future<int>.delayed(const Duration(seconds: 1), () async {
        //If we return _counter++ the value is incorrect. Something strange here
        // ignore: join_return_with_assignment
        _counter++;
        return _counter;
      });
}

class CounterDisplay extends StatelessWidget {
  const CounterDisplay(
    this.state, {
    Key? key,
  }) : super(key: key);

  final AppState state;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(10),
        child: Container(
          height: 200,
          width: 200,
          color: const Color(0xFFEEEEEE),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'You have pushed the button this many times:',
              ),
              if (state.isProcessing)
                const CircularProgressIndicator()
              else
                Text(
                  '${state.callCount}',
                  style: Theme.of(context).textTheme.headline4,
                ),
            ],
          ),
        ),
      );
}
