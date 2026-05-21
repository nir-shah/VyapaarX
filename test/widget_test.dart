import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyapaarx/screens/home/home_screen.dart';

void main() {
  testWidgets('dashboard foundation renders reusable widgets', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.text('VyapaarX'), findsOneWidget);
    expect(find.text('Business dashboard'), findsOneWidget);
    expect(find.text('New invoice'), findsOneWidget);
  });
}
