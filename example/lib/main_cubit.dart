// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppCubit extends Cubit<int> {
  AppCubit() : super(0);

  void increment() => emit(state + 1);
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appCubit = AppCubit();
    return MaterialApp(
      title: 'Bloobit Sample',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BlocBuilder<AppCubit, int>(
        bloc: appCubit,
        builder: (context, state) => MyHomePage(
          title: 'Bloobit Sample',
          bloc: appCubit,
        ),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({
    required this.bloc,
    required this.title,
    super.key,
  });

  final String title;
  final AppCubit bloc;

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
                '${bloc.state}',
                style: Theme.of(context).textTheme.headline4,
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: bloc.increment,
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ),
      );
}
