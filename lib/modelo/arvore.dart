// ignore_for_file: unnecessary_getters_setters
import 'package:geolocator/geolocator.dart';

import 'usuario.dart';

class Arvore {
  String _id = "";
  String get id => _id;
  set id(String value) {
    _id = value;
  }

  String _tipo = "";
  String get tipo => _tipo;
  set tipo(String value) {
    _tipo = value;
  }

  String _detalhes = "";
  String get detalhes => _detalhes;
  set detalhes(String value) {
    _detalhes = value;
  }

  late Position _posicao;
  Position get posicao => _posicao;
  set posicao(Position value) {
    _posicao = value;
  }

  String _imagem = "";
  String get imagem => _imagem;
  set imagem(String value) {
    _imagem = value;
  }

  late Usuario _quemMarcou;
  Usuario get quemMarcou => _quemMarcou;
  set quemMarcou(Usuario value) {
    _quemMarcou = value;
  }

  Arvore({String tipo = "", String detalhes = ""}) {
    _tipo = tipo;
    _detalhes = detalhes;
  }
}
