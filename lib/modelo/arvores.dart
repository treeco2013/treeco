// ignore_for_file: unnecessary_getters_setters, depend_on_referenced_packages, avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../api/api.dart';
import 'arvore.dart';
import '../constantes.dart';

typedef OnArvoreSelecionada = void Function(Arvore arvore, bool duploClique);

class Arvores {
  late OnArvoreSelecionada _onArvoreSelecionada;
  OnArvoreSelecionada get onArvoreSelecionada => _onArvoreSelecionada;
  set onArvoreSelecionada(OnArvoreSelecionada value) {
    _onArvoreSelecionada = value;
  }

  late API _api;
  API get api => _api;
  set api(API value) {
    _api = value;
  }

  late double _tamanhoMarcador;
  double get tamanhoMarcador => _tamanhoMarcador;
  set tamanhoMarcador(double value) {
    _tamanhoMarcador = value;
  }

  Arvores(OnArvoreSelecionada onArvoreSelecionada, API api,
      {double tamanhoMarcador = TAMANHO_MARCADOR_DE_ARVORE}) {
    this.onArvoreSelecionada = onArvoreSelecionada;
    this.tamanhoMarcador = tamanhoMarcador;
    this.api = api;
  }

  Future<ResultadoOperacao> gravarArvore(Arvore arvore) async {
    ResultadoOperacao resultado;

    if (arvore.id.isNotEmpty) {
      resultado = await api.atualizar(arvore);
    } else {
      resultado = await api.adicionar(arvore.generateId());
    }

    return resultado;
  }

  Future<ResultadoOperacao> removerArvore(String id) async {
    return await api.remover(id);
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
                arvore.identificacao,
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

  Future<List<Marker>> toMarcadores({String idArvoreParaDestacar = ""}) async {
    List<Marker> marcadores = [];

    final arvores = await api.getArvores();
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
