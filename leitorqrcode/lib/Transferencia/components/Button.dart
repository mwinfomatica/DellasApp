import 'package:flutter/material.dart';
import 'package:leitorqrcode/Components/Constants.dart';

class ButtonMenuTransferencia extends StatelessWidget {
  final String titulo;
  final String descricao;
  final IconData icone;
  final Function onTap;

  const ButtonMenuTransferencia({
    Key key,
    this.titulo,
    this.descricao,
    this.icone,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(10),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              width: 1,
              color: primaryColor,
            ),
          ),
          width: (MediaQuery.of(context).size.width * 0.8),
          child: Padding(
            padding:
                const EdgeInsets.only(left: 0, top: 20, right: 0, bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  icone,
                  size: 30,
                  color: primaryColor,
                ),
                SizedBox(
                  width: 10,
                ),
                Text(
                  titulo,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
