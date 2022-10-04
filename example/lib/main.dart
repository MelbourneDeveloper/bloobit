// ignore_for_file: diagnostic_describe_all_properties

import 'dart:async';
import 'package:bloobit/bloobit.dart';
import 'package:example/shared.dart';
import 'package:flutter/material.dart';

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

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: BloobitWidget<AppBloobit>(
          bloobit: AppBloobit(CountServerService()),
          builder: (context, bloobit) => Home(
            bloobit,
          ),
        ),
      );
}

class Home extends StatelessWidget {
  const Home(this.bloobit, {super.key});

  final AppBloobit bloobit;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Bloobit Example'),
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
                  FloatingActionButton(
                    onPressed: bloobit.hideWidgets,
                    tooltip: 'X',
                    child: const Icon(Icons.close),
                  )
                ],
              ),
            ),
          ],
        ),
      );
}
