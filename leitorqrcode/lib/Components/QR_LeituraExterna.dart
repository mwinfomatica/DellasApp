import 'dart:async';

import 'package:animated_card/animated_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:leitorqrcode/Components/Constants.dart';
import 'package:leitorqrcode/Shared/themes/app_images.dart';

class QRLeituraExterna extends StatefulWidget {
  const QRLeituraExterna({
    Key? key,
    this.onChange,
    this.inputController,
    this.inputFocusNode,
    this.progress,
    this.bluetoothDisconect,
    this.bluetoothName,
    this.device,
    this.coletorMode,
  }) : super(key: key);
  final StreamController? onChange;
  final TextEditingController? inputController;
  final FocusNode? inputFocusNode;
  final bool? progress;
  final bool? bluetoothDisconect;
  final bool? coletorMode;
  final String? bluetoothName;
  final BluetoothDevice? device;

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
                onTap: () async {
                  // await widget.device.disconnect();
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
                "Leitura código " + (!widget.coletorMode! ? "externo" : "coletor"),
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
                    color: widget.bluetoothDisconect!
                        ? !widget.coletorMode!
                            ? Colors.red
                            : Colors.blue[300]!
                        : Colors.blue[300]!,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Icon(
                        widget.bluetoothDisconect!
                            ? !widget.coletorMode!
                                ? Icons.bluetooth_disabled
                                : Icons.qr_code_scanner
                            : Icons.bluetooth_connected,
                        color:
                            widget.bluetoothDisconect! && !widget.coletorMode!
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
                        color:
                            widget.bluetoothDisconect! && !widget.coletorMode!
                                ? Colors.red
                                : Colors.blue[300],
                      ),
                      Text(
                        widget.bluetoothDisconect! && !widget.coletorMode!
                            ? "Você ainda não conectou \n nenhum dispositivo para leitura"
                            : widget.coletorMode!
                                ? "Aguardando a realização da leitura"
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
