import 'package:flutter_test/flutter_test.dart';
import 'package:study_focus_app/app.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const StudyTrackerApp());

    // Verify app is loaded
    expect(find.byType(StudyTrackerApp), findsOneWidget);
  });
}
