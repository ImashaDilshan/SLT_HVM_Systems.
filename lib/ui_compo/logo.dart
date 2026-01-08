import 'package:flutter/material.dart';

class Logo extends StatelessWidget {
  
  const Logo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 30),
      alignment: Alignment.topCenter,
      height: 200,
      width: 300,
      child: Image.asset("assets/SLTMobitel_Logo.png", width: 250, height: 100),
    );
  }
}
