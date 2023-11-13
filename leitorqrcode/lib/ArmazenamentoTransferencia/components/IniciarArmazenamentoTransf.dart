import 'package:flutter/material.dart';
import 'package:leitorqrcode/Components/Constants.dart';

class BotaoIniciarArmazenamentoTransf extends StatelessWidget {
  final Function()? onPressed;
  final String? titulo;

  const BotaoIniciarArmazenamentoTransf({
    Key? key,
    this.onPressed,
    this.titulo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      width: MediaQuery.of(context).size.width - 10,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(
          titulo!,
          style: TextStyle(
            fontSize: 20,
          ),
        ),
        style: ElevatedButton.styleFrom(
          primary: primaryColor,
        ),
      ),
    );
  }
}
