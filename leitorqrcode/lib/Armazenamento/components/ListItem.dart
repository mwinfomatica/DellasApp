import 'package:flutter/material.dart';
import 'package:leitorqrcode/Models/ArmazenamentoModel.dart';

class ListItem extends StatelessWidget {
  final ArmazenamentoModel? armazenamento;
  final Function()? ontap;
  final Animation<double>? animation;

  const ListItem({
    Key? key,
    this.armazenamento,
    this.ontap,
    this.animation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: animation!,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              child: Row(
                children: [
                  GestureDetector(
                    onTap: ontap,
                    child: Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(armazenamento!.nome!),
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        armazenamento!.descricao!,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color.fromRGBO(132, 141, 149, 1),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Divider(),
        ],
      ),
    );
  }
}
