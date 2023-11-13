import 'package:flutter/material.dart';
import 'package:leitorqrcode/Models/APIModels/ProdutoModel.dart';

class ListItem extends StatelessWidget {
  final ProdutoModel? produto;
  final Function()? ontap;
  final Animation<double>? animation;

  const ListItem({
    Key? key,
    this.produto,
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
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(produto!.nome!),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            produto!.qtd!,
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ],
                    ),
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
