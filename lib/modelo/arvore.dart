// ignore_for_file: unnecessary_getters_setters
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import 'usuario.dart';

class Arvore {
  String _id = "";
  String get id => _id;
  set id(String value) {
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

  List<String> _imagens = [];
  List<String> get imagens => _imagens;
  set imagens(List<String> value) {
    _imagens = value;
  }

  late Usuario _quemMarcou;
  Usuario get quemMarcou => _quemMarcou;
  set quemMarcou(Usuario value) {
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

  static Arvore fromBancoDeDados(Map<String, dynamic> registro) {
    Arvore arvore = Arvore(
        identificacao: registro['identificacao'],
        familia: registro['familia'],
        especie: registro['especie'],
        detalhes: registro['detalhes']);
    arvore.id = registro['id'];
    arvore.comProblema = registro['comProblema'];
    arvore.quemMarcou = Usuario.fromJson(registro['quemMarcou']);
    arvore.posicao = Position.fromMap(registro['posicao']);

    for (final imagem in registro['imagens']) {
      arvore.imagens.add(imagem as String);
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
      'quemMarcou': quemMarcou.toJson(),
      'posicao': posicao.toJson()
    };
  }

  Arvore generateId() {
    final mili = DateTime.now().millisecondsSinceEpoch;
    id = const Uuid().v5(
        Uuid.NAMESPACE_OID, "$identificacao|$familia|$especie|$detalhes|$mili");

    return this;
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
