import 'dart:async';
import 'package:bloobit/bloobit.dart';
import 'package:flutter/material.dart';
import 'package:ioc_container/ioc_container.dart';

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

///Shortcuts for setting up streaming etc.
extension IocContainerBuilderExtensions on IocContainerBuilder {
  ///Adds a StreamController for the given type and exposes its
  ///stream as a singleton
  void addStream<T>() => this
    ..addSingletonService(StreamController<T>.broadcast())
    ..addSingleton<Stream<T>>((con) => con.get<StreamController<T>>().stream);
}

void main() {
  //Register services and the view model with an IoC container
  final builder = IocContainerBuilder()
    //A simple singleton service to emulate a server counting calls
    ..addSingletonService(CountServerService())
    //Adds a Stream for AppState changes
    ..addStream<AppState>()
    //The Bloobit
    ..addSingleton((con) => AppBloobit(con.get<CountServerService>(),
        onSetState: (s) =>
            //Streams state changes to the AppState stream
            con.get<StreamController<AppState>>().add(s)));

  var container = builder.toContainer();

  container
      .get<Stream<AppState>>()
      //Stream the state changes to the debug console
      .listen((appState) => debugPrint(appState.callCount.toString()));

  runApp(MyApp(container));
}

class MyApp extends StatelessWidget {
  const MyApp(this.container, {super.key});
  final IocContainer container;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BloobitWidget<AppBloobit>(
        bloobit: container.get<AppBloobit>(),
        builder: (context, bloobit) => Home(
          bloobit,
        ),
      ),
    );
  }
}

class Home extends StatelessWidget {
  const Home(this.bloobit, {super.key});

  final AppBloobit bloobit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Managing Up The State with Management-like Managers"),
      ),
      body: Stack(children: [
        bloobit.state.displayWidgets
            ? Wrap(children: [
                CounterDisplay(bloobit.state),
                CounterDisplay(bloobit.state),
                CounterDisplay(bloobit.state),
                CounterDisplay(bloobit.state),
                CounterDisplay(bloobit.state),
                CounterDisplay(bloobit.state),
                CounterDisplay(bloobit.state)
              ])
            : Text('X', style: Theme.of(context).textTheme.headline1),
        Align(
          alignment: Alignment.bottomRight,
          child: Row(children: [
            FloatingActionButton(
              onPressed: () => bloobit.callGetCount(),
              tooltip: 'Increment',
              child: const Icon(Icons.add),
            ),
            FloatingActionButton(
              onPressed: () => bloobit.hideWidgets(),
              tooltip: 'X',
              child: const Icon(Icons.close),
            )
          ]),
        ),
      ]),
    );
  }
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
