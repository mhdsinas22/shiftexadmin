import 'package:flutter_test/flutter_test.dart';
import 'package:shiftexadmin/shiftex_admin_app.dart';

void main() {
  testWidgets('Login page smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ShiftexAdminApp());
    await tester.pumpAndSettle();

    expect(find.text('ShiftEx Admin'), findsOneWidget);
    expect(find.text('Admin Login'), findsOneWidget);
    expect(find.text('Email or Admin ID'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Remember me'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
