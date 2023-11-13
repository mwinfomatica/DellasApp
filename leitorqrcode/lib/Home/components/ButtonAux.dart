import 'package:flutter/material.dart';
import 'package:leitorqrcode/Components/Constants.dart';

class ButtonAux extends StatefulWidget {
  final String? titulo;
  final String? descricao;
  final IconData? icone;
  final Function()? func;
  const ButtonAux({
    Key? key,
    this.titulo,
    this.descricao,
    this.icone,
    this.func,
  }) : super(key: key);

  ontap() => func;

  @override
  State<ButtonAux> createState() => _ButtonAuxState();
}

class _ButtonAuxState extends State<ButtonAux> {
  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(10),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: widget.ontap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              width: 1,
              color: primaryColor,
            ),
          ),
          width: (MediaQuery.of(context).size.width * 0.4),
          child: Padding(
            padding:
                const EdgeInsets.only(left: 10, top: 20, right: 10, bottom: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  widget.icone,
                  size: 30,
                  color: primaryColor,
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  widget.titulo!,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  widget.descricao!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color.fromRGBO(132, 141, 149, 1),
                    fontSize: 12,
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
