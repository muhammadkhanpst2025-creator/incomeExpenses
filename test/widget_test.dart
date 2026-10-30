import 'package:flutter_test/flutter_test.dart';
import 'package:income_expenses/main.dart';

void main() {
  testWidgets('app root builds', (tester) async {
    await tester.pumpWidget(const IncomeExpensesApp());
    expect(find.text('Income & Expenses'), findsWidgets);
  });
}
