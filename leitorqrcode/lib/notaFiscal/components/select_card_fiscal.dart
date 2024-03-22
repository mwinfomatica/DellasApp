import 'package:flutter/material.dart';
import 'package:leitorqrcode/Components/Constants.dart';

class SelectCardFiscal extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final String numeroNota;
  final String serieNota;
  final String nomeNota;
  const SelectCardFiscal(
      {Key? key,
      required this.isSelected,
      required this.onTap,
      required this.numeroNota,
      required this.serieNota,
      required this.nomeNota})
      : super(key: key);

  @override
  State<SelectCardFiscal> createState() => _SelectCardFiscalState();
}

class _SelectCardFiscalState extends State<SelectCardFiscal> {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: widget.onTap,
      child: Center(
        child: Container(
          width: width * 0.9,
          height: 80,
          decoration: BoxDecoration(
            color: widget.isSelected ? primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: primaryColor),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Stack(
              children: [
                Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        border: Border.all(),
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(60),
                      ),
                    )),
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${widget.numeroNota}/ ${widget.serieNota}',
                        style: TextStyle(
                          color: !widget.isSelected ? primaryColor : Colors.white,
                          fontSize: 15.0,
                        ),
                      ),
                      Text(
                        widget.nomeNota,
                        style: TextStyle(
                          color: !widget.isSelected ? primaryColor : Colors.white,
                          fontSize: 15.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
