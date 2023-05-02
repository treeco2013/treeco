// ignore_for_file: unnecessary_getters_setters, depend_on_referenced_packages, avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import 'arvore.dart';
import '../constantes.dart';

typedef OnArvoreSelecionada = void Function(Arvore arvore, bool duploClique);

class Arvores {
  final uuid = const Uuid();

  List<Arvore> _arvores = [];
  List<Arvore> get arvores => _arvores;
  set arvores(List<Arvore> value) {
    _arvores = value;
  }

  late double _tamanhoMarcador;
  double get tamanhoMarcador => _tamanhoMarcador;
  set tamanhoMarcador(double value) {
    _tamanhoMarcador = value;
  }

  late OnArvoreSelecionada _onArvoreSelecionada;
  OnArvoreSelecionada get onArvoreSelecionada => _onArvoreSelecionada;
  set onArvoreSelecionada(OnArvoreSelecionada value) {
    _onArvoreSelecionada = value;
  }

  Arvores(OnArvoreSelecionada onArvoreSelecionada,
      {double tamanhoMarcador = TAMANHO_MARCADOR_DE_ARVORE}) {
    this.onArvoreSelecionada = onArvoreSelecionada;
    this.tamanhoMarcador = tamanhoMarcador;
  }

  void adicionarArvore(Arvore arvore) {
    if (arvore.id.isNotEmpty) {
      arvores.removeWhere((item) => item.id == arvore.id);
    } else {
      arvore.id = uuid.v1();
    }

    arvores.add(arvore);
  }

  void removerArvore(String id) {
    arvores.removeWhere((item) => item.id == id);
  }

  Widget getMarcadorArvore(Arvore arvore, bool destacar) {
    return GestureDetector(
      child: Stack(children: [
        Image.asset(destacar
            ? "lib/recursos/imagens/marcador_destacado.png"
            : "lib/recursos/imagens/marcador.png"),
        !destacar
            ? Center(
                child: Text(
                arvore.tipo,
                style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    backgroundColor: Colors.blueGrey),
              ))
            : const SizedBox.shrink()
      ]),
      onTap: () {
        onArvoreSelecionada(arvore, false);
      },
      onDoubleTap: () {
        onArvoreSelecionada(arvore, true);
      },
    );
  }

  List<Marker> toMarcadores({String idArvoreParaDestacar = ""}) {
    List<Marker> marcadores = [];

    for (final arvore in arvores) {
      marcadores.add(Marker(
          point: LatLng(arvore.posicao.latitude, arvore.posicao.longitude),
          width: _tamanhoMarcador,
          height: _tamanhoMarcador,
          builder: (context) =>
              getMarcadorArvore(arvore, (idArvoreParaDestacar == arvore.id))));
    }

    return marcadores;
  }
}
