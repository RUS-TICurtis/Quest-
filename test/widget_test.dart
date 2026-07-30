import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quest/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('QuestApp renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: QuestApp()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
