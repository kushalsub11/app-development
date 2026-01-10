import 'package:flutter_test/flutter_test.dart';

import 'package:final_year_project/main.dart';

void main() {
  testWidgets('renders login screen and can switch to registration',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Sajelo Guru'), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Login'), findsWidgets);

    await tester.tap(find.text('Create New Account'));
    await tester.pumpAndSettle();

    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
    expect(find.text('Phone Number'), findsOneWidget);
  });
}
