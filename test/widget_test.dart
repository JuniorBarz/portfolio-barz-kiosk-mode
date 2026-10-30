import 'package:barz_kiosk_mode/ui/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home screen exposes kiosk actions', (tester) async {
    await tester.pumpWidget(const KioskApp());

    expect(find.text('Barz Kiosk Mode'), findsOneWidget);
    expect(find.text('Iniciar modo quiosque'), findsOneWidget);
    expect(find.text('Configuracoes'), findsOneWidget);
  });

  testWidgets('settings opens PIN change screen', (tester) async {
    await tester.pumpWidget(const KioskApp());

    await tester.tap(find.text('Configuracoes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PIN'));
    await tester.pumpAndSettle();

    expect(find.text('Trocar PIN'), findsOneWidget);
    expect(find.text('PIN atual'), findsOneWidget);
    expect(find.text('Novo PIN'), findsOneWidget);
    expect(find.text('Confirmar novo PIN'), findsOneWidget);
  });
}

