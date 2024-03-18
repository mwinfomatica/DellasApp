import 'package:flutter/material.dart';
import 'package:leitorqrcode/Components/Constants.dart';

class ButtonConference extends StatelessWidget {
  final String titulo;
  final void Function()? onPressed;
  const ButtonConference({
    Key? key,
    this.onPressed,
    required this.titulo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width * 0.9,
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(),
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor,
              Color.fromARGB(255, 11, 27, 59),
            ],
          ),
        ),
        child: Center(
          child: Text(
            titulo,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
