import 'package:flutter/material.dart';

class AppChangeNotifier extends ChangeNotifier {
  int counter = 0;

  void increment() {
    counter++;
    notifyListeners();
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appChangeNotifier = AppChangeNotifier();

    return MaterialApp(
      title: 'Change Notifier Sample',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AnimatedBuilder(
        animation: appChangeNotifier,
        builder: (context, bloobit) => MyHomePage(
          title: 'Change Notifier Sample',
          changeNotifier: appChangeNotifier,
        ),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({
    required this.changeNotifier,
    required this.title,
    super.key,
  });

  final String title;
  final AppChangeNotifier changeNotifier;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'You have pushed the button this many times:',
              ),
              Text(
                '${changeNotifier.counter}',
                style: Theme.of(context).textTheme.headline4,
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: changeNotifier.increment,
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ),
      );
}
