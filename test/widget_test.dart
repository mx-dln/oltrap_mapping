import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oltrap_mapping/main.dart';
import 'package:oltrap_mapping/screens/map_screen.dart';

void main() {
  testWidgets('OLTrap Mapping app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const OLTrapMappingApp());

    // Verify that the map screen loads
    expect(find.byType(MapScreen), findsOneWidget);
  });
}
