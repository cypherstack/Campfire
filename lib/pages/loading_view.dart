import 'package:flutter/material.dart';
import 'package:paymint/utilities/cfcolors.dart';

class LoadingView extends StatefulWidget {
  const LoadingView({Key key}) : super(key: key);

  @override
  _LoadingViewState createState() => _LoadingViewState();
}

class _LoadingViewState extends State<LoadingView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
    //     overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: CFColors.starryNight,
        child: Center(
          // gradient fails to render with flutter_svg
          // child: SvgPicture.asset(
          //   "assets/svg/splash.svg",
          //   width: 188,
          //   height: 137,
          // ),
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
