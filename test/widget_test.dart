import 'package:flutter_test/flutter_test.dart';
import 'package:yolo_tracker_app/main.dart';

void main() {
  testWidgets('Приложение запускается и показывает главное меню', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Старт'), findsOneWidget);
    expect(find.text('История'), findsOneWidget);
  });
}