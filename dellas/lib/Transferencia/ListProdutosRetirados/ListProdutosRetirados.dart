// import 'package:flutter/material.dart';
// import 'package:dellas/Components/Bottom.dart';
// import 'package:dellas/Components/Constants.dart';
// import 'package:dellas/Components/GetTipoOperacao.dart';
// import 'package:dellas/Models/APIModels/ProdutoModel.dart';

// class ListProdutosRetirados extends StatefulWidget {
//   @override
//   _ListProdutosRetiradosState createState() => _ListProdutosRetiradosState();
// }

// class _ListProdutosRetiradosState extends State<ListProdutosRetirados> {
//   List<ProdutoModel> listOp = [];
//   @override
//   void initState() {
//     new ProdutoModel().getByStituacao().then((value) => {
//           listOp = value
//         });
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Scaffold(
//           appBar: AppBar(
//             backgroundColor: primaryColor,
//             title: Text("Operações"),
//           ),
//           body: ListView.separated(
//             padding: const EdgeInsets.all(8),
//             itemCount: listOp.length,
//             separatorBuilder: (BuildContext context, int index) => SizedBox(
//               height: 15,
//               child: Divider(),
//             ),
//             itemBuilder: (BuildContext context, int index) {
//               return InkWell(
//                 child: Container(
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   height: 30,
//                   child: Row(
//                     children: [
//                       Align(
//                         alignment: Alignment.centerLeft,
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           crossAxisAlignment: CrossAxisAlignment.center,
//                           children: [
//                             Text(
//                              "Op.: "+ getTipo(listOp[index].tipo) + " | " + listOp[index].cnpj ,
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ],
//                         ),
//                       ),
//                       SizedBox(
//                         height: 5,
//                       ),
//                     ],
//                   ),
//                 ),
//                 onTap: () {},
//               );
//             },
//           ),
//           bottomNavigationBar: BottomBar()),
//     );
//   }
// }
