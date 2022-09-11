import 'dart:async';

import 'package:bloobit/bloobit.dart';
import 'package:flutter/material.dart';
import 'package:ioc_container/ioc_container.dart';

///The immutable state of the app
@immutable
class AppState {
  final int callCount;
  final bool isProcessing;
  final bool displayWidgets;

  const AppState(
    this.callCount,
    this.isProcessing,
    this.displayWidgets,
  );

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

///This basically works like a Cubit
class AppBloobit extends Bloobit<AppState> {
  int get callCount => state.callCount;
  bool get isProcessing => state.isProcessing;
  bool get displayWidgets => state.displayWidgets;

  final CountServerService countServerService;

  AppBloobit(this.countServerService, {void Function(AppState)? callback})
      : super(const AppState(0, false, true), callback: callback);

  void hideWidgets() {
    emit(state.copyWith(displayWidgets: false));
  }

  Future<void> callGetCount() async {
    emit(state.copyWith(isProcessing: true));

    final callCount = await countServerService.getCallCount();

    emit(state.copyWith(isProcessing: false, callCount: callCount));
  }
}

///This emulates a server that counts the number of times it has been called.
class CountServerService {
  int _counter = 0;
  Future<int> getCallCount() =>
      Future<int>.delayed(const Duration(seconds: 1), () async {
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
        callback: (s) =>
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
  final IocContainer container;

  const MyApp(this.container, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BloobitPropagator<AppBloobit>(
        bloobit: container.get<AppBloobit>(),
        child: const Home(),
      ),
    );
  }
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
        AttachesSetState<Home, AppBloobit> {
  @override
  Widget build(BuildContext context) {
    final bloobit = BloobitPropagator.of<AppBloobit>(context).bloobit;
    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Managing Up The State with Management-like Managers"),
      ),
      body: Stack(children: [
        bloobit.displayWidgets
            ? Wrap(children: [
                CounterDisplay(),
                CounterDisplay(),
                CounterDisplay(),
                CounterDisplay(),
                CounterDisplay(),
                CounterDisplay(),
                CounterDisplay()
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
  const CounterDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloobit = BloobitPropagator.of<AppBloobit>(context).bloobit;
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
            if (bloobit.isProcessing)
              const CircularProgressIndicator()
            else
              Text(
                '${bloobit.callCount}',
                style: Theme.of(context).textTheme.headline4,
              ),
          ],
        ),
      ),
    );
  }
}
