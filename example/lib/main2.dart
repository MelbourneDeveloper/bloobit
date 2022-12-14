// ignore_for_file: prefer_const_literals_to_create_immutables,
// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'package:bloobit/bloobit.dart';
import 'package:flutter/material.dart';
import 'package:ioc_container/ioc_container.dart';

///The immutable state of the app
@immutable
class AppState2 {
  const AppState2(
    this.callCount,
    this.isProcessing,
    this.displayWidgets,
  );
  final int callCount;
  final bool isProcessing;
  final bool displayWidgets;

  AppState2 copyWith({
    int? callCount,
    bool? isProcessing,
    bool? displayWidgets,
  }) =>
      AppState2(
        callCount ?? this.callCount,
        isProcessing ?? this.isProcessing,
        displayWidgets ?? this.displayWidgets,
      );
}

///This extends `Bloobit` and implements the business logic with methods.
///When the state changes, we call `setState()`
class AppBloobit2 extends Bloobit<AppState2> {
  AppBloobit2(this.countServerService, {void Function(AppState2)? onSetState})
      : super(const AppState2(0, false, true), onSetState: onSetState);
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

///Shortcuts for setting up streaming etc.
extension IocContainerBuilderExtensions on IocContainerBuilder {
  ///Adds a StreamController for the given type and exposes its
  ///stream as a singleton
  void addStream<T>() => this
    ..addSingletonService(StreamController<T>.broadcast())
    ..addSingleton<Stream<T>>((con) => con.get<StreamController<T>>().stream);
}

// coverage:ignore-start
void main() {
  runApp(
    MyApp2(
      //Register services and the Bloobit with an IoC container
      compose(),
    ),
  );
}
// coverage:ignore-end

IocContainer compose() {
  final builder = IocContainerBuilder()
    //A simple singleton service to emulate a server counting calls
    ..addSingletonService(CountServerService())
    //Adds a Stream for AppState changes
    ..addStream<AppState2>()
    //The Bloobit
    ..addSingleton(
      (con) => AppBloobit2(
        con.get<CountServerService>(),
        onSetState: (s) =>
            //Streams state changes to the AppState stream
            con.get<StreamController<AppState2>>().add(s),
      ),
    );

  return builder.toContainer();
}

const bloobitPropagatorKey = ValueKey('BloobitPropagator');

class MyApp2 extends StatelessWidget {
  const MyApp2(this.container, {super.key});
  final IocContainer container;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: BloobitPropagator<AppBloobit2>(
          key: bloobitPropagatorKey,
          bloobit: container.get<AppBloobit2>(),
          child: const Home(),
        ),
      );
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends
    //This is a normal State class
    State<Home>
    with
        //This automatically adds the ability to call setState() on the model
        AttachesSetState<Home, AppBloobit2> {
  @override
  Widget build(BuildContext context) {
    final bloobit = BloobitPropagator.of<AppBloobit2>(context).bloobit;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bloobit Sample'),
      ),
      body: Stack(
        children: [
          if (bloobit.state.displayWidgets)
            Wrap(
              children: [
                CounterDisplay(),
                CounterDisplay(),
                CounterDisplay(),
                CounterDisplay(),
                CounterDisplay(),
                CounterDisplay(),
                CounterDisplay(),
              ],
            )
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CounterDisplay extends StatelessWidget {
  const CounterDisplay({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bloobit = BloobitPropagator.of<AppBloobit2>(context).bloobit;

    return Padding(
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
            if (bloobit.state.isProcessing)
              const CircularProgressIndicator()
            else
              Text(
                '${bloobit.state.callCount}',
                style: Theme.of(context).textTheme.headline4,
              ),
          ],
        ),
      ),
    );
  }
}
