// ignore_for_file: unnecessary_getters_setters
import 'package:geolocator/geolocator.dart';

import 'imagem.dart';
import 'usuario.dart';

class Arvore {
  int _id = 0;
  int get id => _id;
  set id(int value) {
    _id = value;
  }

  String _identificacao = "";
  String get identificacao => _identificacao;
  set identificacao(String value) {
    _identificacao = value;
  }

  String _familia = "";
  String get familia => _familia;
  set familia(String value) {
    _familia = value;
  }

  String _especie = "";
  String get especie => _especie;
  set especie(String value) {
    _especie = value;
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

  bool _comProblema = false;
  bool get comProblema => _comProblema;
  set comProblema(bool value) {
    _comProblema = value;
  }

  List<Imagem> _imagens = [];
  List<Imagem> get imagens => _imagens;
  set imagens(List<Imagem> value) {
    _imagens = value;
  }

  late Usuario? _quemMarcou;
  Usuario? get quemMarcou => _quemMarcou;
  set quemMarcou(Usuario? value) {
    _quemMarcou = value;
  }

  Arvore(
      {String identificacao = "",
      String familia = "",
      String especie = "",
      String detalhes = ""}) {
    this.identificacao = identificacao;
    this.familia = familia;
    this.especie = especie;
    this.detalhes = detalhes;
  }

  static Arvore fromJson(Map<String, dynamic> registro) {
    Arvore arvore = Arvore(
        identificacao: registro['identificacao'],
        familia: registro['familia'],
        especie: registro['especie'],
        detalhes: registro['detalhes']);
    arvore.id = registro['id'];
    arvore.comProblema = registro['comProblema'];
    arvore.quemMarcou = Usuario.fromJson(registro['quemMarcou']);

    Position posicao = Position(
        latitude: registro['latitude'].toDouble(),
        longitude: registro['longitude'].toDouble(),
        accuracy: 0.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        timestamp: null);
    arvore.posicao = posicao;

    for (final imagem in registro['imagens']) {
      arvore.imagens.add(Imagem.fromJson(imagem));
    }

    return arvore;
  }

  static Arvore fromClassificacao(Map<String, dynamic> classificacao) {
    Arvore arvore = Arvore(
        identificacao: classificacao['identificacao'],
        familia: classificacao['familia'],
        especie: classificacao['especie']);

    return arvore;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'identificacao': identificacao,
      'familia': familia,
      'especie': especie,
      'detalhes': detalhes,
      'comProblema': comProblema,
      'imagens': imagens,
      'quemMarcou': quemMarcou != null ? quemMarcou!.toJson() : "{}",
      'posicao': posicao.toJson()
    };
  }

  static List<String> validarArvore(Arvore arvore) {
    List<String> erros = [];

    if (arvore.identificacao.isEmpty) {
      erros.add("informe a identificação da árvore");
    }
    if (arvore.familia.isEmpty) {
      erros.add("informe a família da árvore");
    }
    if (arvore.especie.isEmpty) {
      erros.add("informe a espécie da árvore");
    }

    return erros;
  }

  @override
  String toString() {
    return identificacao;
  }

  @override
  bool operator ==(other) {
    return other is Arvore &&
        identificacao.toLowerCase() == other.identificacao.toLowerCase() &&
        familia.toLowerCase() == other.familia.toLowerCase() &&
        especie.toLowerCase() == other.especie.toLowerCase();
  }

  @override
  int get hashCode =>
      identificacao.toLowerCase().hashCode ^
      familia.toLowerCase().hashCode ^
      especie.toLowerCase().hashCode;
}
