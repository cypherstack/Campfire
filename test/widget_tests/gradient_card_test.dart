import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/widgets/gradient_card.dart';

void main() {
  testWidgets("Builds successfully", (tester) async {
    final card = GradientCard(
      gradient: CFColors.fireGradientVertical,
      child: Center(),
    );

    await tester.pumpWidget(card);

    expect(find.byType(Container), findsOneWidget);
    expect(find.byType(Center), findsOneWidget);
  });
}
