import 'package:flutter/material.dart';
import 'package:leitorqrcode/Components/Constants.dart';

class ButtonHome extends StatelessWidget {
  final String? titulo;
  final String? descricao;
  final IconData? icone;
  final Function()? onTap;

  const ButtonHome({
    Key? key,
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
          width: (MediaQuery.of(context).size.width * 0.4),
          child: Padding(
            padding:
                const EdgeInsets.only(left: 10, top: 20, right: 10, bottom: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icone,
                  size: 30,
                  color: primaryColor,
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  titulo!,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  descricao!,
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
