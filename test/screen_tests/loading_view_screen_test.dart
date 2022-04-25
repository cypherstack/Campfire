import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paymint/pages/loading_view.dart';

void main() {
  testWidgets("LoadingView build correctly", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoadingView(),
      ),
    );

    final imageFinder = find.byType(Image);
    expect(imageFinder, findsOneWidget);

    final imageSource =
        ((imageFinder.evaluate().single.widget as Image).image as AssetImage)
            .assetName;
    expect(imageSource, "assets/images/splash.png");
  });
}
