import 'dart:async';
import 'package:bloobit/bloobit.dart';
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

///This extends `Bloobit` and implements the business logic with methods.
///When the state changes, we call `setState()`
class AppBloobit extends Bloobit<AppState> {
  AppBloobit(this.countServerService, {void Function(AppState)? onSetState})
      : super(const AppState(0, false, true), onSetState: onSetState);
  final CountServerService countServerService;

  void hideWidgets() {
    setState(state.copyWith(displayWidgets: false));
  }

  Future<void> callGetCount() async {
    setState(state.copyWith(isProcessing: true));

    final callCount = await countServerService.getCallCount();

    setState(state.copyWith(isProcessing: false, callCount: callCount));
  }
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

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Bloobit Sample',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: BloobitWidget<AppBloobit>(
          bloobit: AppBloobit(
            CountServerService(),
          ),
          builder: (context, bloobit) => Home(
            bloobit,
          ),
        ),
      );
}

class Home extends StatelessWidget {
  const Home(
    this.bloobit, {
    super.key,
  });

  final AppBloobit bloobit;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Bloobit Sample'),
        ),
        body: Stack(
          children: [
            if (bloobit.state.displayWidgets)
              CounterDisplay(bloobit.state)
            else
              Text('X', style: Theme.of(context).textTheme.headline1),
            Align(
              alignment: Alignment.bottomRight,
              child: Row(
                children: [
                  FloatingActionButton(
                    onPressed: bloobit.callGetCount,
                    tooltip: 'Increment',
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
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
