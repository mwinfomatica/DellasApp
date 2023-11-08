import 'package:flutter/material.dart';
import 'package:leitorqrcode/Components/Constants.dart';

class AppBarSettings extends StatelessWidget {
  const AppBarSettings({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 152,
      color: primaryColor,
      child: Center(
        child: ListTile(
          title: Text.rich(
            TextSpan(
              text: "Configurações",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          subtitle: Text(
            "Realize suas configurações para utilização do app",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
          leading: InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              height: 48,
              width: 48,
              child: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
