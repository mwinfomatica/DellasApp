import 'package:flutter/material.dart';

class BottomBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
      
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
