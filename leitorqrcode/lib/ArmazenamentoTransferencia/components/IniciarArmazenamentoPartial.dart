import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:leitorqrcode/Components/Constants.dart';

class BotaoIniciarArmazenamentoTransfPartial extends StatefulWidget {
  final Function()? onPressed;
  final String? titulo;

  const BotaoIniciarArmazenamentoTransfPartial({
    Key? key,
    this.onPressed,
    this.titulo,
  }) : super(key: key);

  @override
  State<BotaoIniciarArmazenamentoTransfPartial> createState() =>
      _BotaoIniciarArmazenamentoTransfPartialState();

  ontap() => this.onPressed!();
}

class _BotaoIniciarArmazenamentoTransfPartialState
    extends State<BotaoIniciarArmazenamentoTransfPartial> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      width: MediaQuery.of(context).size.width - 10,
      height: 80,
      child: ElevatedButton(
        onPressed: widget.ontap,
        child: Text(
          widget.titulo!,
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
