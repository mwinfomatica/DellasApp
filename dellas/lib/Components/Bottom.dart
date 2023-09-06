import 'package:flutter/material.dart';

class BottomBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color.fromRGBO(255, 255, 255, 1),
            Color.fromRGBO(231, 231, 231, 1),
            Color.fromRGBO(200, 200, 200, 1),
            // Color.fromRGBO(57, 132, 32, 1),
            Color.fromRGBO(200, 200, 200, 1),
            Color.fromRGBO(90, 206, 51, 1),
            Color.fromRGBO(90, 206, 51, 1),
            Color.fromRGBO(231, 231, 231, 1),
            Color.fromRGBO(255, 255, 255, 1),
          ],
        ),
      ),
      width: double.infinity,
      height: 50,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              "assets/img/logo-p2p.png",
              height: 25,
            ),
            Image.asset(
              "assets/img/logo-mw.png",
              height: 50,
            ),
          ],
        ),
      ),
    );
  }
}
