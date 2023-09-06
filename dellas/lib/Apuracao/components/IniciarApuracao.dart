import 'package:flutter/material.dart';
import 'package:dellas/Apuracao/components/IniciarApuracaoPartial.dart';
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
    return BotaoIniciarApuracaoPartial(
      onPressed: onPressed,
      titulo: titulo,
    );
  }
}
