import 'dart:async';

import 'package:animated_card/animated_card.dart';
import 'package:flutter/material.dart';
import 'package:dellas/Components/Constants.dart';
import 'package:dellas/Shared/themes/app_images.dart';

class QRLeituraExterna extends StatefulWidget {
  const QRLeituraExterna(
      {Key? key,
      this.onChange,
      this.inputController,
      this.inputFocusNode,
      this.progress,
      required this.bluetoothDisconect,
      this.bluetoothName})
      : super(key: key);
  final StreamController? onChange;
  final TextEditingController? inputController;
  final FocusNode? inputFocusNode;
  final bool? progress;
  final bool bluetoothDisconect;
  final String? bluetoothName;

  @override
  _QRLeituraExternaState createState() => _QRLeituraExternaState();
}

class _QRLeituraExternaState extends State<QRLeituraExterna> {
  AnimationController? controller;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.1,
              color: primaryColor,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(30),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
              ),
              SizedBox(
                width: 25,
              ),
              Text(
                "Leitura código externo",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (!widget.progress!)
          Center(
            heightFactor: 0,
            child: AnimatedCard(
              direction: AnimatedCardDirection.left,
              child: Container(
                // height: MediaQuery.of(context).size.height * 0.9,
                alignment: Alignment.bottomCenter,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      child: Image.asset(
                        AppImages.barcode,
                        color: Colors.blue,
                        height: 200,
                        width: 130,
                      ),
                    ),
                    Container(
                      width: 130,
                      height: 70,
                      child: Image.asset(
                        AppImages.qrcodescan,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (!widget.progress!)
          Center(
            child: AnimatedCard(
              direction: AnimatedCardDirection.right,
              child: Container(
                margin: const EdgeInsets.only(left: 20, right: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                  border: Border.all(
                    color: Colors.red,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Icon(
                        widget.bluetoothDisconect
                            ? Icons.bluetooth_disabled
                            : Icons.bluetooth_connected,
                        color: widget.bluetoothDisconect
                            ? Colors.red
                            : Colors.blue[300],
                        size: 34,
                      ),
                      // Image.asset(
                      //   AppImages.qrcodescan,
                      //   width: 56,
                      //   height: 34,
                      //   color: background,
                      // ),
                      Container(
                        width: 1,
                        height: 32,
                        color: widget.bluetoothDisconect
                            ? Colors.red
                            : Colors.blue[300],
                      ),
                      Text(
                        widget.bluetoothDisconect
                            ? "Você ainda não conectou \n nenhum dispositivo para leitura"
                            : "Dispositivo conectado para \n realização da leitura",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (widget.progress!)
          Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.blue,
              semanticsLabel: 'Linear progress indicator',
            ),
          ),
      ],
    );
  }
}
