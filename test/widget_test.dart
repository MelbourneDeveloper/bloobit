// ignore_for_file: avoid_relative_lib_imports

import 'package:bloobit/bloobit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/main.dart';
import '../example/lib/main2.dart';

void main() {
  //The traditional counter increments smoke test
  testWidgets('Counter increments smoke test', (tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets(
    //This tests the example app and therefore the Bloobit library
    //It is a good example of how to test Bloobit apps
    //Nothing ties this test to Bloobit
    //You could replace the Bloobit with a Cubit and the test would still pass
    'Test The Example App',
    (tester) async {
      var streamCount = 0;

      final container = compose();

      //Listen to the stream
      //Note: streams are not a core part of Bloobit but we can attach them and
      //this test here is to ensure that onSetState is working
      container
          .get<Stream<AppState2>>()
          //Stream the state changes to the debug console
          .listen((appState) => streamCount++);

      await tester.pumpWidget(MyApp2(container));

      //Tap increment button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump(const Duration(milliseconds: 10));

      //Check that we see the progress indicators
      expect(find.byType(CircularProgressIndicator), findsNWidgets(7));

      //Settle and check the progress indicators disappeard
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      //Two set states on increment and one on hide
      expect(streamCount, 3);
    },
  );

  testWidgets(
    //This test tests the widgets and physically acccesses the Bloobit via
    //BloobitPropagator. You shouldn't do this because it couples your test to
    //the Bloobit library. But, this is an example of how easy it is if you
    //need to do this.
    'Test The Example App With Bloobit Access',
    (tester) async {
      await tester.pumpWidget(MyApp2(compose()));

      //Get the bloobit and check the state

      final bloobitPropagator = tester.widget<BloobitPropagator<AppBloobit2>>(
        find.byKey(bloobitPropagatorKey).first,
      );

      expect(bloobitPropagator.bloobit, isNotNull);
      expect(bloobitPropagator.bloobit.state.callCount, 0);

      //Tap increment button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump(const Duration(milliseconds: 10));
      //Check the state is processing
      expect(bloobitPropagator.bloobit.state.isProcessing, true);
      //Check that we see the progress indicators
      expect(find.byType(CircularProgressIndicator), findsNWidgets(7));

      //Settle and check the progress indicators disappeard
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(CircularProgressIndicator), findsNothing);

      //Check the new state
      expect(bloobitPropagator.bloobit.state.callCount, 1);
      expect(bloobitPropagator.bloobit.state.isProcessing, false);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      //Check the final state
      expect(bloobitPropagator.bloobit.state.displayWidgets, false);
    },
  );
}
