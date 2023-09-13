// ignore_for_file: unnecessary_getters_setters, avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:treeco/constantes.dart';
import '../modelo/arvore.dart';

typedef OnIndiceImagemSelecionada = void Function(int indice);
typedef OnImagemParaVisualizar = void Function(String url);
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

  late String _hostDeImagens;
  String get hostDeImagens => _hostDeImagens;
  set hostDeImagens(String value) {
    _hostDeImagens = value;
  }

  Imagens(OnIndiceImagemSelecionada onIndiceImagemSelecionada,
      OnImagemParaVisualizar onImagemParaVisualizar, String hostDeImagens) {
    this.onIndiceImagemSelecionada = onIndiceImagemSelecionada;
    this.onImagemParaVisualizar = onImagemParaVisualizar;
    this.hostDeImagens = hostDeImagens;
  }

  Widget _getSlides(int indiceImagemSelecionada) {
    List<Widget> imagens = [];

    if (arvore.imagens.isEmpty) {
      imagens.add(Image.asset("lib/recursos/imagens/marcador.png"));
    } else {
      for (final imagem in arvore.imagens) {
        String url = '$hostDeImagens${imagem.arquivo}';
        imagens.add(GestureDetector(
          child: Image.network(url, fit: BoxFit.fitHeight),
          onTap: () {
            onImagemParaVisualizar(url);
          },
        ));
      }
    }

    return Container(
        margin: const EdgeInsets.all(MARGEM_DEFAULT),
        child: ImageSlideshow(
          width: double.infinity,
          height: ALTURA_SLIDE,
          initialPage: indiceImagemSelecionada,
          indicatorColor: Colors.green,
          indicatorBackgroundColor: Colors.grey,
          autoPlayInterval: 0,
          indicatorRadius: 4,
          isLoop: true,
          children: imagens,
          onPageChanged: (indice) => {onIndiceImagemSelecionada(indice)},
        ));
  }

  Widget visualizar(Arvore arvore, {int indiceImagemSelecionada = 0}) {
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
        _getSlides(indiceImagemSelecionada),
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
