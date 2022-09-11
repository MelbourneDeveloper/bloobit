## State management, as simple as it gets

[Flutter Sample and code on Dartpad](https://dartpad.dev/?id=47b6619b67348dbd3c53e3563463a707)

Bloobit is a state management approach inspired by [Cubit](https://pub.dev/packages/bloc) but without the streams by default. This might look familiar. Cubit is an implementation of the Bloc pattern. The Bloc pattern aims to separate presentation from business logic. However, the Bloc pattern can add complexity because it depends on Streams. Bloobit aims to simplify the Bloc pattern by removing the need for streams and focuses on the core concept of calling `setState()` when the state changes. There is no magic. There are only [78 lines of code](https://github.com/MelbourneDeveloper/bloobit/blob/main/lib/bloobit.dart) that you can read and understand.

This is the [Bloc library](https://bloclibrary.dev/#/). It remains the most popular Bloc library, and I recommend it if you intend to follow the Bloc pattern. Bloobit is an experimental library, and I make no guarantees about using it in production yet.

### State
We usually use immutable state, but there is no reason you can't use mutable state. Bloobit is agnostic about this. Bloobit is also agnostic about the type of state you use. Bloobit is just a wrapper around `setState()`.

```dart
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
```

### Implementing Logic
Send messages or events to the Bloobit via the methods. Call emit when the state changes. 
If the state is mutable, you need to send a new instance of the state anyway.

```dart
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
```

### Put the Bloobit in the Widget Tree
You need to wrap your widgets in a BloobitPropagator. This is an [InheritedWidget](https://api.flutter.dev/flutter/widgets/InheritedWidget-class.html). The BloobitPropagator will pass the Bloobit to the children. 

```dart
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
```

### Accessing the Bloobit
You can access the Bloobit from any widget in the widget tree under the BloobitPropagator. 

```dart
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
```

### Convert To a Stream
You can stream state changes from the Bloobit, but we don't do this by default. You can use the [ioc_container](https://pub.dev/packages/ioc_container) package to wire up streaming. See the example folder for all the code. You could use this with [StreamBuilder](https://api.flutter.dev/flutter/widgets/StreamBuilder-class.html) if you like, but that's probably not necessary.

```dart
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
```

