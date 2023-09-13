import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void exibirComoRetrato() {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

typedef ExecutarAposPosicionar = void Function();
typedef ExecutarAposConfirmar = void Function();

void alertarExecutar(BuildContext contexto, String mensagemDeAlerta,
    ExecutarAposConfirmar executarAposConfirmar) {
  Widget cancelar = TextButton(
    onPressed: () {
      Navigator.of(contexto).pop();
    },
    child: const Text('não'),
  );
  Widget confirmar = TextButton(
    onPressed: () {
      executarAposConfirmar();

      Navigator.of(contexto).pop();
    },
    child: const Text('sim'),
  );

  AlertDialog alert = AlertDialog(
    content: Text(mensagemDeAlerta),
    actions: [
      cancelar,
      confirmar,
    ],
  );

  showDialog(
    barrierDismissible: false,
    context: contexto,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

Future<void> alertar(BuildContext contexto, String alerta) async {
  return showDialog<void>(
    context: contexto,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        content: Text(alerta),
        actions: [
          TextButton(
            child: const Text('Ok'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
