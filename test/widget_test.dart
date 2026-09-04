import 'package:flutter_test/flutter_test.dart';
import 'package:wherewasi/main.dart';
import 'package:wherewasi/shared/widgets/main_nav_bar.dart';

void main() {
  testWidgets('app launches on Home with the floating nav bar', (tester) async {
    await tester.pumpWidget(const WhereWasIApp());

    expect(find.text('Afternoon'), findsOneWidget);
    expect(find.byType(MainNavBar), findsOneWidget);
  });
}
