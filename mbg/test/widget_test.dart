import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mbg/main.dart';

void main() {
  testWidgets('Login screen renders correctly', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const MyApp());

    // Verifikasi bahwa widget utama adalah LoginScreen
    expect(find.text('Login'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2)); // Email dan Password
    expect(find.byType(ElevatedButton), findsOneWidget); // Tombol Login
    expect(find.text('Lupa Password?'), findsOneWidget);
  });
}
