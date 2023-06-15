// ignore_for_file: unnecessary_getters_setters, avoid_print
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:treeco/constantes.dart';
import '../modelo/arvore.dart';

typedef OnArvoreParaGravar = void Function(Arvore arvore);
typedef OnImagemParaVisualizar = void Function(String string);
typedef OnAtivarCamera = void Function();
typedef OnSelecionarImagem = void Function();

typedef TemUsuarioLogado = bool Function();

class Imagens {
  late Arvore _arvore;
  Arvore get arvore => _arvore;
  set arvore(Arvore value) {
    _arvore = value;
  }

  late OnArvoreParaGravar _onArvoreParaGravar;
  OnArvoreParaGravar get onArvoreParaGravar => _onArvoreParaGravar;
  set onArvoreParaGravar(OnArvoreParaGravar value) {
    _onArvoreParaGravar = value;
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
      OnArvoreParaGravar onArvoreParaGravar,
      OnImagemParaVisualizar onImagemParaVisualizar,
      OnAtivarCamera onAtivarCamera,
      TemUsuarioLogado temUsuarioLogado) {
    this.onArvoreParaGravar = onArvoreParaGravar;
    this.onImagemParaVisualizar = onImagemParaVisualizar;
    this.onAtivarCamera = onAtivarCamera;

    this.temUsuarioLogado = temUsuarioLogado;
  }

  void gravarImagem() {
    onArvoreParaGravar(arvore);
  }

  Widget getSlides() {
    List<Image> imagens = [];

    if (arvore.imagens.isEmpty) {
      imagens.add(Image.asset("lib/recursos/imagens/marcador.png",
          fit: BoxFit.fitHeight));
    } else {
      final bytes = base64.decode(arvore.imagens.first);

      imagens.add(Image.memory(bytes, fit: BoxFit.fitHeight));
    }

    return Container(
        // color: Colors.amber,
        decoration: BoxDecoration(
            // color: Colors.green[100],
            border: Border.all(
          color: Colors.green,
          width: 4,
        )),
        margin: const EdgeInsets.all(MARGEM_DEFAULT),
        child: ImageSlideshow(
          width: double.infinity,
          height: ALTURA_SLIDE,
          initialPage: 0,
          indicatorColor: Colors.green,
          indicatorBackgroundColor: Colors.grey,
          onPageChanged: (value) {
            print('Page changed: $value');
          },
          autoPlayInterval: 0,
          indicatorRadius: 4,
          isLoop: true,
          children: imagens,
        ));
  }

  Widget visualizar(Arvore arvore) {
    this.arvore = arvore;

    final formKey = GlobalKey<FormState>();
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              getSlides(),
              Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 6, right: 4),
                  child:
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Text(
                        "última fotografia capturada por ${arvore.quemFotografou.nome}",
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black45))
                  ])),
              temUsuarioLogado()
                  ? Padding(
                      padding: const EdgeInsets.all(6),
                      child: Container(
                          width: double.infinity,
                          color: Colors.transparent,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green),
                            onPressed: () {
                              gravarImagem();
                            },
                            icon: const Icon(
                              Icons.check,
                              size: 24.0,
                            ),
                            label: const Text('gravar'),
                          )))
                  : const SizedBox.shrink()
            ],
          )),
    );
  }
}
