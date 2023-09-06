import 'package:flutter/material.dart';
import 'package:dellas/Components/Constants.dart';

class BotaoIniciarApuracao extends StatelessWidget {
  final Function? onPressed;
  final String? titulo;

  const BotaoIniciarApuracao({
    Key? key,
    this.onPressed,
    this.titulo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      width: MediaQuery.of(context).size.width - 10,
      height: 80,
      child: ElevatedButton(
        onPressed: () => onPressed,
        child: Text(
          titulo!,
          style: TextStyle(
            fontSize: 30,
          ),
        ),
        style: ElevatedButton.styleFrom(
          primary: primaryColor,
        ),
      ),
    );
  }
}