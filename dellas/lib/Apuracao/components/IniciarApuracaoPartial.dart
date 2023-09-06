import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:dellas/Components/Constants.dart';

class BotaoIniciarApuracaoPartial extends StatefulWidget {
  final Function? onPressed;
  final String? titulo;

  const BotaoIniciarApuracaoPartial({
    Key? key,
    this.onPressed,
    this.titulo,
  }) : super(key: key);

  @override
  State<BotaoIniciarApuracaoPartial> createState() =>
      _BotaoIniciarApuracaoPartialState();

      ontap() => this.onPressed!();
}

class _BotaoIniciarApuracaoPartialState
    extends State<BotaoIniciarApuracaoPartial> {
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
