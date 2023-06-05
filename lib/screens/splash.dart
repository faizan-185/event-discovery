import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:event_discovery/screens/Auth/login.dart';
import 'package:event_discovery/utils/theme.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  void navigateToOtherScreen(BuildContext context) async {
    await Future.delayed(const Duration(seconds: 5));
    Navigator.push(context, MaterialPageRoute(builder: (context) => const LogInScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        elevation: 0,
      ),
      body: Center(
          child: SizedBox(
            child: DefaultTextStyle(
              style: const TextStyle(color: kWhiteColor, fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: 36,),
              child: AnimatedTextKit(
                animatedTexts: [
                  TyperAnimatedText('LocalSavvy', speed: const Duration(milliseconds: 350)),
                ],
              ),
            ),
          )
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    navigateToOtherScreen(context);
  }
}
