import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:leitorqrcode/Components/Bottom.dart';
import 'package:leitorqrcode/Components/Constants.dart';
import 'package:leitorqrcode/OrdemProducao/components/MenuOrdemProducao.dart';

class OrdemProducaoScreen extends StatefulWidget {
  @override
  _OrdemProducaoScreenState createState() => _OrdemProducaoScreenState();
}

class _OrdemProducaoScreenState extends State<OrdemProducaoScreen> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: primaryColor,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return SafeArea(
      child: Scaffold(
          body: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height * 0.2,
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
                      "Ordem de Produção",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              MenuOrdemProducao(),
            ],
          ),
          bottomNavigationBar: BottomBar()),
    );
  }

}
