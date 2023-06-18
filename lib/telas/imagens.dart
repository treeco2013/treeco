// ignore_for_file: unnecessary_getters_setters, avoid_print
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:treeco/constantes.dart';
import '../modelo/arvore.dart';

typedef OnIndiceImagemSelecionada = void Function(int indice);
typedef OnImagemParaVisualizar = void Function(Uint8List bytesDaImagem);
typedef OnAtivarCamera = void Function();
typedef OnSelecionarImagem = void Function();

typedef TemUsuarioLogado = bool Function();

class Imagens {
  late Arvore _arvore;
  Arvore get arvore => _arvore;
  set arvore(Arvore value) {
    _arvore = value;
  }

  late OnIndiceImagemSelecionada _onIndiceImagemSelecionada;
  OnIndiceImagemSelecionada get onIndiceImagemSelecionada =>
      _onIndiceImagemSelecionada;
  set onIndiceImagemSelecionada(OnIndiceImagemSelecionada value) {
    _onIndiceImagemSelecionada = value;
  }

  late OnImagemParaVisualizar _onImagemParaVisualizar;
  OnImagemParaVisualizar get onImagemParaVisualizar => _onImagemParaVisualizar;
  set onImagemParaVisualizar(OnImagemParaVisualizar value) {
    _onImagemParaVisualizar = value;
  }

  late OnAtivarCamera _onAtivarCamera;
  OnAtivarCamera get onAtivarCamera => _onAtivarCamera;
  set onAtivarCamera(OnAtivarCamera value) {
    _onAtivarCamera = value;
  }

  late TemUsuarioLogado _temUsuarioLogado;
  TemUsuarioLogado get temUsuarioLogado => _temUsuarioLogado;
  set temUsuarioLogado(TemUsuarioLogado value) {
    _temUsuarioLogado = value;
  }

  Imagens(
      OnIndiceImagemSelecionada onIndiceImagemSelecionada,
      OnImagemParaVisualizar onImagemParaVisualizar,
      OnAtivarCamera onAtivarCamera,
      TemUsuarioLogado temUsuarioLogado) {
    this.onIndiceImagemSelecionada = onIndiceImagemSelecionada;
    this.onImagemParaVisualizar = onImagemParaVisualizar;
    this.onAtivarCamera = onAtivarCamera;

    this.temUsuarioLogado = temUsuarioLogado;
  }

  Widget getSlides() {
    List<Widget> imagens = [];

    if (arvore.imagens.isEmpty) {
      imagens.add(Image.asset("lib/recursos/imagens/marcador.png"));
    } else {
      for (final image in arvore.imagens) {
        final bytes = base64.decode(image);
        imagens.add(GestureDetector(
          child: Image.memory(bytes, fit: BoxFit.fitHeight),
          onTap: () {
            onImagemParaVisualizar(bytes);
          },
        ));
      }
    }

    return Container(
        margin: const EdgeInsets.all(MARGEM_DEFAULT),
        child: ImageSlideshow(
          width: double.infinity,
          height: ALTURA_SLIDE,
          initialPage: 0,
          indicatorColor: Colors.green,
          indicatorBackgroundColor: Colors.grey,
          autoPlayInterval: 0,
          indicatorRadius: 4,
          isLoop: true,
          children: imagens,
          onPageChanged: (indice) => {onIndiceImagemSelecionada(indice)},
        ));
  }

  Widget visualizar(Arvore arvore) {
    this.arvore = arvore;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
            padding: const EdgeInsets.all(MARGEM_DEFAULT),
            child: Text(arvore.identificacao,
                style: const TextStyle(fontWeight: FontWeight.bold))),
        const Padding(
            padding: EdgeInsets.all(MARGEM_DEFAULT),
            child: Divider(thickness: 2)),
        getSlides(),
        Padding(
            padding: const EdgeInsets.all(MARGEM_DEFAULT),
            child: Text(
              "${arvore.imagens.length} foto(s) de $MAXIMO_DE_IMAGENS",
              style: const TextStyle(fontSize: 11),
            )),
        const Padding(
            padding: EdgeInsets.all(MARGEM_DEFAULT),
            child: Divider(thickness: 2))
      ],
    );
  }
}
