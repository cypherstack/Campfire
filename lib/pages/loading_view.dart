import 'package:flutter/material.dart';
import 'package:paymint/utilities/cfcolors.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: CFColors.starryNight,
        child: Center(
          child: Image(
            image: AssetImage(
              "assets/images/splash.png",
            ),
            width: MediaQuery.of(context).size.width * 0.5,
          ),
        ),
      ),
    );
  }
}
