import 'package:flutter/material.dart';
import 'package:leitorqrcode/Components/Constants.dart';
import 'package:leitorqrcode/Models/APIModels/RetornoCargaModel.dart';

class SelectCardCarga extends StatefulWidget {
  final bool isSelected;
  final Function(bool?)? onCheckboxChanged;
  final Pedido carga;

  const SelectCardCarga({
    Key? key,
    this.isSelected = false,
    this.onCheckboxChanged,
    required this.carga,
  }) : super(key: key);

  @override
  _SelectCardCargaState createState() => _SelectCardCargaState();
}

class _SelectCardCargaState extends State<SelectCardCarga> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: primaryColor),
      ),
      child: ListTile(
        onTap: () {},
        leading: Checkbox(
          value: widget.isSelected,
          onChanged: widget.onCheckboxChanged,
        ),
        title: Text(widget.carga.carga, style: TextStyle(color: primaryColor)),
      ),
    );
  }
}
