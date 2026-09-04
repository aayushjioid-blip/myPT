import 'package:flutter_test/flutter_test.dart';
import 'package:fittrainer/app.dart';
import 'package:fittrainer/data/mock/mock_data_store.dart';

void main() {
  testWidgets('FitTrainerApp smoke test', (WidgetTester tester) async {
    final mockDataStore = MockDataStore();
    await tester.pumpWidget(FitTrainerApp(dataStore: mockDataStore));
    await tester.pumpAndSettle();
    expect(find.byType(FitTrainerApp), findsOneWidget);
  });
}
