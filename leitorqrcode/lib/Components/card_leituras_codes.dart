import 'package:flutter/material.dart';

class CardeReadCodesWidget extends StatefulWidget {
  CardeReadCodesWidget({Key key}) : super(key: key);

  @override
  _CardeReadCodesWidgetState createState() => _CardeReadCodesWidgetState();
}

class _CardeReadCodesWidgetState extends State<CardeReadCodesWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
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
                Icons.bluetooth_disabled,
                color: Colors.white,
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
                color: Colors.red,
              ),
              Text.rich(
                TextSpan(
                  text: "Você ainda ",
                  style: TextStyle(color: Colors.white),
                  children: [
                    TextSpan(
                      text: "não conectou \n",
                    ),
                    TextSpan(
                      text: "nenhum dispositivo para leitura",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
