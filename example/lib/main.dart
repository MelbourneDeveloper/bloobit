import 'package:bloobit/bloobit.dart';
import 'package:flutter/material.dart';

//This is a very simple sample that users BloobitWidget. Check out main2.dart in
//the example folder for a more complex example that uses dependency injection
//and BloobitPropagator.

class AppBloobit extends Bloobit<int> {
  AppBloobit() : super(0);

  void increment() => setState(state + 1);
}

void main() {
  runApp(const MyApp());
}

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

class MyHomePage extends StatelessWidget {
  const MyHomePage({
    required this.bloobit,
    required this.title,
    super.key,
  });

  final String title;
  final AppBloobit bloobit;

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
                '${bloobit.state}',
                style: Theme.of(context).textTheme.headline4,
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: bloobit.increment,
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ),
      );
}
