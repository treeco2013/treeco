// ignore_for_file: unnecessary_getters_setters
import 'dart:io';

import 'package:flutter/material.dart';
import '../modelo/arvore.dart';

typedef OnArvoreParaGravar = void Function(Arvore arvore);
typedef OnImagemParaVisualizar = void Function(Arvore arvore);
typedef TemUsuarioLogado = bool Function();
typedef AtivarCamera = void Function();

class Detalhes {
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

  late TemUsuarioLogado _temUsuarioLogado;
  TemUsuarioLogado get temUsuarioLogado => _temUsuarioLogado;
  set temUsuarioLogado(TemUsuarioLogado value) {
    _temUsuarioLogado = value;
  }

  late AtivarCamera _ativarCamera;
  AtivarCamera get ativarCamera => _ativarCamera;
  set ativarCamera(AtivarCamera value) {
    _ativarCamera = value;
  }

  Detalhes(
      OnArvoreParaGravar onArvoreParaGravar,
      OnImagemParaVisualizar onImagemParaVisualizar,
      TemUsuarioLogado temUsuarioLogado,
      AtivarCamera ativarCamera) {
    this.onArvoreParaGravar = onArvoreParaGravar;
    this.onImagemParaVisualizar = onImagemParaVisualizar;
    this.temUsuarioLogado = temUsuarioLogado;
    this.ativarCamera = ativarCamera;
  }

  void gravarArvore() {
    onArvoreParaGravar(arvore);
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
              Padding(
                padding: const EdgeInsets.all(6),
                child: Center(
                    child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: Colors.green[100],
                      border: Border.all(
                        color: Colors.green,
                        width: 5,
                      )),
                  child: arvore.imagem.isEmpty
                      ? GestureDetector(
                          onTap: () => {ativarCamera()},
                          child: Image.asset(
                              "lib/recursos/imagens/marcador.png",
                              width: 100,
                              height: 160))
                      : GestureDetector(
                          onTap: () => {onImagemParaVisualizar(arvore)},
                          child: Image.file(File(arvore.imagem),
                              width: 100, height: 160)),
                )),
              ),
              Padding(
                padding: const EdgeInsets.all(4),
                child: TextFormField(
                    initialValue: arvore.tipo,
                    decoration:
                        const InputDecoration(hintText: 'tipo da árvore'),
                    onChanged: (value) => arvore.tipo = value),
              ),
              Padding(
                padding: const EdgeInsets.all(4),
                child: TextFormField(
                    initialValue: arvore.detalhes,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    decoration:
                        const InputDecoration(hintText: 'mais detalhes'),
                    onChanged: (value) => arvore.detalhes = value),
              ),
              Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text("marcada por ${arvore.quemMarcou.nome}")
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
                              gravarArvore();
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
