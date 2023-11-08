import 'package:flutter/material.dart';

class Dialogs {
  static Future<void> showLoadingDialog(
      BuildContext context, GlobalKey key) async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Container(
            key: key,
            color: Color.fromRGBO(255, 255, 255, 0.7),
            child: Center(
              child: SizedBox(
                child: Container(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          );
        });
  }

  static Future<void> showFreezePageLinearProgress(
      BuildContext context, GlobalKey key) async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Container(
            key: key,
            // color: Color.fromRGBO(255, 255, 255, 0.7),
            child: Container(
                alignment: Alignment.bottomCenter,
                margin: EdgeInsets.all(20),
                child: LinearProgressIndicator(
                  valueColor: new AlwaysStoppedAnimation<Color>(Colors.grey),
                )),
          );
        });
  }

  static Future<void> showLoadingDialogLogin(
      BuildContext context, GlobalKey key) async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Container(
            key: key,
            color: Color.fromRGBO(255, 255, 255, 0.7),
            child: Center(
              child: Column(
                children: [
                  Center(
                    child: SizedBox(
                      child: Container(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      child: Text(
                        "Preparando tudo para você...",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  static Future<void> showToast(BuildContext context, String message,
      {Duration duration, double elevation, Color bgColor}) async {
    final snackBar = SnackBar(
      content: Text(message),
      elevation: elevation != null ? elevation : 6.0,
      backgroundColor: bgColor != null ? bgColor : Colors.grey.shade700,
      duration: duration != null ? duration : Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
