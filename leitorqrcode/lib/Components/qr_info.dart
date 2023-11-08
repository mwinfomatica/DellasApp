import 'dart:async';

import 'package:flutter/material.dart';
import 'package:leitorqrcode/Components/Constants.dart';

class QRInfo extends StatelessWidget {
  const QRInfo(
      {Key key, this.onChangeInput, this.inputController, this.inputFocusNode})
      : super(key: key);
  final StreamController onChangeInput;
  final TextEditingController inputController;
  final FocusNode inputFocusNode;
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: (MediaQuery.of(context).size.height * 0.4) - 50,
      left: 30,
      right: 30,
      child: Column(
        children: [
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   children: [
          //     Container(
          //       decoration: BoxDecoration(
          //           color: secondary, borderRadius: BorderRadius.circular(5)),
          //       child: Padding(
          //         padding: const EdgeInsets.symmetric(vertical: 15),
          //         child: Row(
          //           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //           children: [
          //             Icon(
          //               Icons.qr_code,
          //               color: Colors.white,
          //               size: 50,
          //             ),
          //             Container(
          //               width: 1,
          //               height: 52,
          //               color: Colors.white,
          //             ),
          //             Text.rich(
          //               TextSpan(
          //                 text: "Aguardando leitura externa do QR code",
          //                 style: TextStyle(
          //                   fontSize: 16,
          //                   fontWeight: FontWeight.w400,
          //                   color: Colors.white,
          //                 ),
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //     ),
          //   ],
          // ),

          Stack(
            children: [
              TextField(
                focusNode: inputFocusNode,
                controller: inputController,
                onChanged: onChangeInput.add,
                showCursor: true,
                autocorrect: false,
                obscureText: true,
                autofocus: true,
              ),
              Container(
                color: scalfolding,
                height: 100,
              ),
            ],
          ),

          // Visibility(
          //   visible: true,
          //   child: TextField(
          //     onChanged: onChangeInput.add,
          //     showCursor: true,
          //     autocorrect: false,
          //     obscureText: true,
          //     autofocus: true,
          //   ),
          // ),
        ],
      ),
    );
  }
}
