## State management, as simple as it gets

[Flutter Sample and code on Dartpad](https://dartpad.dev/?id=852bb434276d46775f61d74ece554209)

Bloobit is a state management approach inspired by the BloC pattern, but without streams (or any [observer pattern](https://en.wikipedia.org/wiki/Observer_pattern)) by default. Bloobit and the BloC pattern aim to separate presentation from business logic, but Bloobit is not an implementation of the Bloc pattern. You just call `setState()` when the state changes. There is no magic. There are only around [100 lines of code, depending on who's counting](https://github.com/MelbourneDeveloper/bloobit/blob/main/lib/bloobit.dart). You can read and understand the code.

If you need to follow the BloC pattern, I recommend [Cubit](https://pub.dev/documentation/bloc/latest/bloc/Cubit-class.html) in the [Bloc library](https://bloclibrary.dev/#/).

Bloobit is currently in beta but getting closer to a full release.

### Implement Business Logic
Extend [`Bloobit<TState>`](https://pub.dev/documentation/bloobit/latest/bloobit/Bloobit-class.html) and send messages or events to the `Bloobit` via the methods. Call [`setState`](https://pub.dev/documentation/bloobit/latest/bloobit/Bloobit/setState.html) when the state changes. 

```dart
///This extends `Bloobit` and implements the business logic with methods.
///When the state changes, we call `setState()`
class AppBloobit extends Bloobit<AppState> {
  int get callCount => state.callCount;
  bool get isProcessing => state.isProcessing;
  bool get displayWidgets => state.displayWidgets;

  final CountServerService countServerService;

  AppBloobit(this.countServerService, {void Function(AppState)? onSetState})
      : super(const AppState(0, false, true), onSetState: onSetState);

  void hideWidgets() {
    setState(state.copyWith(displayWidgets: false));
  }

  Future<void> callGetCount() async {
    setState(state.copyWith(isProcessing: true));

    final callCount = await countServerService.getCallCount();

    setState(state.copyWith(isProcessing: false, callCount: callCount));
  }
}
```

### State
We usually use immutable state, but there is no reason you can't use mutable state. `Bloobit` is agnostic about this. `Bloobit` is just a wrapper around `setState()`.

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

You can easily inspect the state and the `Bloobit` in the widget tree using the dev tools. See the next section about the [`BloobitPropagator`](https://pub.dev/documentation/bloobit/latest/bloobit/BloobitPropagator-class.html)
![dev tools](https://github.com/MelbourneDeveloper/bloobit/blob/main/images/widgettreestate.png)

### BloobitWidget
This is the easiest way to use bloobit. Put a `BloobitWidget` in the tree and instantiate your bloobit like this. Check out the second example to see how to use bloobit with dependency injection and [ioc_connainer](https://pub.dev/packages/ioc_container).

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Bloobit Sample',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: BloobitWidget<AppBloobit>(
          bloobit: AppBloobit(),
          builder: (context, bloobit) => MyHomePage(
            title: 'Bloobit Sample',
            bloobit: bloobit,
          ),
        ),
      );
}
```

### Expose Bloobit Throughout the Widget Tree
If you want to nest widgets, you need to wrap your widgets in a `BloobitPropagator`. This is an [InheritedWidget](https://api.flutter.dev/flutter/widgets/InheritedWidget-class.html). The `BloobitPropagator` will pass the Bloobit to the children. 

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
You can access the `Bloobit` from any widget in the widget tree under the BloobitPropagator. Use [`BloobitPropagator.of`](https://pub.dev/documentation/bloobit/latest/bloobit/BloobitPropagator/of.html).

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
Bloobit is designed to work with only one `StatefulWidget`. As you can see in the example, you don't mutliple `StatefulWidgets` to power multiple child widgets. Bloc is designed to work with many, but most of the time, it is not necessary to work with multiple `StatefulWidget's. However, you can stream state changes from the `Bloobit` and use the [ioc_container](https://pub.dev/packages/ioc_container) package to wire up streaming for multiple listeners. See the example folder for the streaming code. You could use this with [StreamBuilder](https://api.flutter.dev/flutter/widgets/StreamBuilder-class.html) or multiple other `StatefulWidget's.

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
```

