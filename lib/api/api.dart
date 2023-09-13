// ignore_for_file: avoid_print, constant_identifier_names, unnecessary_getters_setters, depend_on_referenced_packages, non_constant_identifier_names
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encript;
import 'package:encrypt/encrypt.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// ignore: implementation_imports
import 'package:http_parser/src/media_type.dart';
import '../modelo/arvore.dart';

enum ResultadoOperacao { sucesso, erro }

typedef OnErro = Function(Object erro);

abstract class API {
  Future<ResultadoOperacao> iniciar(OnErro onErro);

  Future<bool> disponivel();

  Future<Map<String, dynamic>> getConfiguracoes();

  Future<List<Arvore>> getArvores();

  Future<Arvore?> getArvore(int id);

  Future<ResultadoOperacao> adicionar(Arvore arvore);

  Future<ResultadoOperacao> atualizar(Arvore arvore);

  Future<ResultadoOperacao> remover(int id);

  Future<ResultadoOperacao> adicionarImagem(int idArvore, String arquivo);

  Future<ResultadoOperacao> removerImagem(int id);
}

const CLASSIFICACOES = "lib/recursos/estaticos/classificacoes.json";
const CHAVE_DE_ENCRIPTACAO = "ECRAp5ja6DKADoukZm8SapZoLSd5KN9S";
final IV_DE_ENCRIPTACAO =
    "a|b|c|d|e|f|g|h|i|j|k|l|m|n|o|p|q|r|s|t|u|v|x|y|w|z".substring(0, 16);
const SUCESSO_ENVIO = 201;

class Classificacoes extends API {
  late List<Arvore> _arvores = [];
  List<Arvore> get arvores => _arvores;
  set arvores(List<Arvore> value) {
    _arvores = value;
  }

  bool _temClassificacoes = false;
  bool get temClassificacoes => _temClassificacoes;
  set temClassificacoes(bool value) {
    _temClassificacoes = value;
  }

  @override
  Future<ResultadoOperacao> iniciar(OnErro onErro) async {
    ResultadoOperacao resultado = ResultadoOperacao.sucesso;
    temClassificacoes = false;

    try {
      final string = await rootBundle.loadString(CLASSIFICACOES);
      final classificacoes = json.decode(string);

      _arvores.clear();
      for (final classificacao in classificacoes) {
        _arvores.add(Arvore.fromClassificacao(classificacao));
      }

      temClassificacoes = true;
    } catch (erro) {
      resultado = ResultadoOperacao.erro;

      print("ocorreu um erro recuperando classificações de árvores: $erro");
    }

    return resultado;
  }

  @override
  Future<bool> disponivel() async {
    return temClassificacoes;
  }

  @override
  Future<Map<String, dynamic>> getConfiguracoes() {
    throw UnimplementedError();
  }

  Future<void> adicionarClassificacoes(API api) async {
    final outrasArvores = await api.getArvores();

    for (final outraArvore in outrasArvores) {
      if (!arvores.contains(outraArvore)) {
        arvores.add(outraArvore);
      }
    }
  }

  @override
  Future<ResultadoOperacao> adicionar(Arvore arvore) {
    throw UnimplementedError();
  }

  @override
  Future<ResultadoOperacao> atualizar(Arvore arvore) {
    throw UnimplementedError();
  }

  @override
  Future<Arvore?> getArvore(int id) {
    throw UnimplementedError();
  }

  @override
  Future<List<Arvore>> getArvores() {
    throw UnimplementedError();
  }

  @override
  Future<ResultadoOperacao> remover(int id) {
    throw UnimplementedError();
  }

  @override
  Future<ResultadoOperacao> adicionarImagem(int idArvore, String arquivo) {
    throw UnimplementedError();
  }

  @override
  Future<ResultadoOperacao> removerImagem(int id) {
    throw UnimplementedError();
  }
}

class Remota extends API {
  late OnErro _onErro;
  OnErro get onErro => _onErro;
  set onErro(OnErro onErro) {
    _onErro = onErro;
  }

  late Uri _urlAlive;
  Uri get urlAlive => _urlAlive;
  set urlAlive(Uri url) {
    _urlAlive = url;
  }

  late Uri _urlConfiguracoes;
  Uri get urlConfiguracoes => _urlConfiguracoes;
  set urlConfiguracoes(Uri url) {
    _urlConfiguracoes = url;
  }

  late Uri _urlArvores;
  Uri get urlArvores => _urlArvores;
  set urlArvores(Uri url) {
    _urlArvores = url;
  }

  late Uri _urlImagens;
  Uri get urlImagens => _urlImagens;
  set urlImagens(Uri url) {
    _urlImagens = url;
  }

  String _encriptar(String dados) {
    final chave = encript.Key.fromUtf8(CHAVE_DE_ENCRIPTACAO);

    final encriptador =
        encript.Encrypter(encript.AES(chave, mode: AESMode.cbc));
    final encriptado =
        encriptador.encrypt(dados, iv: encript.IV.fromUtf8(IV_DE_ENCRIPTACAO));

    return Uri.encodeComponent(encriptado.base64);
  }

  String _desencriptar(String dados) {
    final chave = encript.Key.fromUtf8(CHAVE_DE_ENCRIPTACAO);

    final encriptador =
        encript.Encrypter(encript.AES(chave, mode: AESMode.cbc));
    final desencriptado = encriptador.decrypt(
        encript.Encrypted.fromBase64(dados),
        iv: encript.IV.fromUtf8(IV_DE_ENCRIPTACAO));

    return desencriptado;
  }

  Future<Map<String, dynamic>> _adicionarArvore(String dados) async {
    final encriptado = _encriptar(dados);
    final urlAdicionar = Uri.parse("${urlArvores.toString()}/$encriptado");

    final resposta = await http.post(urlAdicionar);
    final desencriptado = _desencriptar(resposta.body);
    final resultado = jsonDecode(desencriptado);

    return resultado;
  }

  Future<Map<String, dynamic>> _atualizarArvore(String dados) async {
    final encriptado = _encriptar(dados);
    final urlAtualizar = Uri.parse("${urlArvores.toString()}/$encriptado");

    final resposta = await http.put(urlAtualizar);
    final desencriptado = _desencriptar(resposta.body);
    final resultado = jsonDecode(desencriptado);

    return resultado;
  }

  Future<Map<String, dynamic>> _isAlive() async {
    final resposta = await http.get(urlAlive);

    final desencriptado = _desencriptar(resposta.body);
    final resultado = jsonDecode(desencriptado);

    return resultado;
  }

  Future<Map<String, dynamic>> _getConfiguracoes() async {
    final resposta = await http.get(urlConfiguracoes);

    final desencriptado = _desencriptar(resposta.body);
    final resultado = jsonDecode(desencriptado);

    return resultado;
  }

  Future<Map<String, dynamic>> _listarArvores() async {
    final resposta = await http.get(urlArvores);

    final desencriptado = _desencriptar(resposta.body);
    final resultado = jsonDecode(desencriptado);

    return resultado;
  }

  Future<Map<String, dynamic>> _encontrarArvore(String dados) async {
    final encriptado = _encriptar(dados);
    final urlEncontrar = Uri.parse("${urlArvores.toString()}/$encriptado");

    final resposta = await http.get(urlEncontrar);
    final desencriptado = _desencriptar(resposta.body);
    final resultado = jsonDecode(desencriptado);

    return resultado;
  }

  Future<Map<String, dynamic>> _removerArvore(String dados) async {
    final encriptado = _encriptar(dados);
    final urlRemover = Uri.parse("${urlArvores.toString()}/$encriptado");

    final resposta = await http.delete(urlRemover);

    final desencriptado = _desencriptar(resposta.body);
    final resultado = jsonDecode(desencriptado);

    return resultado;
  }

  Future<http.StreamedResponse> _adicionarImagem(
      String dados, String arquivo) async {
    final encriptado = _encriptar(dados);
    final urlAdicionar = Uri.parse("${urlImagens.toString()}/$encriptado");

    final requisicao = http.MultipartRequest('POST', urlAdicionar);
    requisicao.files.add(await http.MultipartFile.fromPath("imagem", arquivo,
        contentType: MediaType("image", "png")));

    return await requisicao.send();
  }

  Future<Map<String, dynamic>> _removerImagem(String dados) async {
    final encriptado = _encriptar(dados);
    final urlRemover = Uri.parse("${urlImagens.toString()}/$encriptado");

    final resposta = await http.delete(urlRemover);
    final desencriptado = _desencriptar(resposta.body);
    final resultado = jsonDecode(desencriptado);

    return resultado;
  }

  @override
  Future<ResultadoOperacao> iniciar(OnErro onErro) async {
    this.onErro = onErro;

    urlAlive = Uri.parse(
        "${dotenv.env['API_REMOTA_HOST']!}:${dotenv.env['API_REMOTA_PORTA']!}/alive");
    urlConfiguracoes = Uri.parse(
        "${dotenv.env['API_REMOTA_HOST']!}:${dotenv.env['API_REMOTA_PORTA']!}/configuracoes");
    urlArvores = Uri.parse(
        "${dotenv.env['API_REMOTA_HOST']!}:${dotenv.env['API_REMOTA_PORTA']!}/arvore");
    urlImagens = Uri.parse(
        "${dotenv.env['API_REMOTA_HOST']!}:${dotenv.env['API_REMOTA_PORTA']!}/imagem");

    return ResultadoOperacao.sucesso;
  }

  @override
  Future<bool> disponivel() async {
    bool alive = false;

    try {
      final resposta = await _isAlive();

      alive = resposta['alive'];
    } catch (erro) {
      onErro(erro);
    }

    return alive;
  }

  @override
  Future<Map<String, dynamic>> getConfiguracoes() async {
    Map<String, dynamic> resultado = {};

    try {
      resultado = await _getConfiguracoes();
    } catch (erro) {
      onErro(erro);
    }

    return resultado;
  }

  @override
  Future<ResultadoOperacao> adicionar(Arvore arvore) async {
    ResultadoOperacao resultado = ResultadoOperacao.erro;

    try {
      final resposta = await _adicionarArvore(jsonEncode(arvore.toJson()));
      if (resposta['sucesso']) {
        resultado = ResultadoOperacao.sucesso;
      }
    } catch (erro) {
      onErro(erro);
    }

    return resultado;
  }

  @override
  Future<ResultadoOperacao> atualizar(Arvore arvore) async {
    ResultadoOperacao resultado = ResultadoOperacao.erro;

    try {
      final resposta = await _atualizarArvore(jsonEncode(arvore.toJson()));
      if (resposta['sucesso']) {
        resultado = ResultadoOperacao.sucesso;
      }
    } catch (erro) {
      onErro(erro);
    }

    return resultado;
  }

  @override
  Future<List<Arvore>> getArvores() async {
    List<Arvore> arvores = [];

    try {
      final resposta = await _listarArvores();
      if (resposta['quantidade'] > 0) {
        final jsons = resposta["arvores"];
        for (final json in jsons) {
          arvores.add(Arvore.fromJson(json));
        }
      }
    } catch (erro) {
      onErro(erro);
    }

    return arvores;
  }

  @override
  Future<Arvore?> getArvore(int id) async {
    Arvore? arvore;

    try {
      final resultado = await _encontrarArvore('{ "id": $id }');
      if (resultado["encontrada"]) {
        arvore = Arvore.fromJson(resultado["arvore"]);
      }
    } catch (erro) {
      onErro(erro);
    }

    return arvore;
  }

  @override
  Future<ResultadoOperacao> remover(int id) async {
    var resultado = ResultadoOperacao.erro;

    try {
      final resposta = await _removerArvore('{ "id": $id }');
      if (resposta['sucesso']) {
        resultado = ResultadoOperacao.sucesso;
      }
    } catch (erro) {
      onErro(erro);
    }

    return resultado;
  }

  @override
  Future<ResultadoOperacao> adicionarImagem(
      int idArvore, String arquivo) async {
    ResultadoOperacao resultado = ResultadoOperacao.erro;

    try {
      final resposta =
          await _adicionarImagem('{ "idArvore": $idArvore }', arquivo);
      if (resposta.statusCode == SUCESSO_ENVIO) {
        resultado = ResultadoOperacao.sucesso;
      }
    } catch (erro) {
      onErro(erro);
    }

    return resultado;
  }

  @override
  Future<ResultadoOperacao> removerImagem(int id) async {
    var resultado = ResultadoOperacao.erro;

    try {
      final resposta = await _removerImagem('{ "id": $id }');
      if (resposta['sucesso']) {
        resultado = ResultadoOperacao.sucesso;
      }
    } catch (erro) {
      onErro(erro);
    }

    return resultado;
  }
}

late API api;
