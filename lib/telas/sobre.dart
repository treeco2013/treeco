import 'package:flutter/material.dart';

class Sobre {
  Widget visualizar() {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Image.asset("lib/recursos/imagens/ifba.png", width: 110, height: 180),
      const Padding(
          padding: EdgeInsets.all(4),
          child: Text("desenvolvido como projeto de iniciação científica",
              textAlign: TextAlign.center)),
      const Padding(
          padding: EdgeInsets.all(4),
          child: Text("edital no 01/2022/PRPGI/IFBA de 09 de março de 2022",
              textAlign: TextAlign.center))
    ]));
  }
}
