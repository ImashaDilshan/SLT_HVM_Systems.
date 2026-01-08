import 'package:flutter/material.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:Column(
        children: [
          Container(
            width: 100,
            height: 100,
            color: Colors.red,
           child: Center(
             child: Container(
              height: 50,
              width: 150,
              color: Colors.lightBlue,
               
             ),
           ),
          )
        ],
      ) ,
    );
  }
}