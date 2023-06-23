// ignore_for_file: avoid_print, constant_identifier_names, unnecessary_getters_setters
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import '../modelo/arvore.dart';

enum ResultadoOperacao { sucesso, erro }

abstract class API {
  bool disponivel();

  Future<ResultadoOperacao> iniciar();

  Future<List<Arvore>> getArvores();

  Future<Arvore?> getArvore(String id);

  Future<ResultadoOperacao> adicionar(Arvore arvore);

  Future<ResultadoOperacao> atualizar(Arvore arvore);

  Future<ResultadoOperacao> remover(String id);
}

const CLASSIFICACOES = "lib/recursos/estaticos/classificacoes.json";

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
  bool disponivel() {
    return temClassificacoes;
  }

  @override
  Future<ResultadoOperacao> iniciar() async {
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
  Future<Arvore?> getArvore(String id) {
    throw UnimplementedError();
  }

  @override
  Future<List<Arvore>> getArvores() {
    throw UnimplementedError();
  }

  @override
  Future<ResultadoOperacao> remover(String id) {
    throw UnimplementedError();
  }
}

const ARMAZENAMENTO_LOCAL = "treeco.d1cdeab0-ef63-11ed-a05b-0242ac120003.db";

class Local extends API {
  late Database _banco;

  @override
  bool disponivel() {
    return true;
  }

  @override
  Future<ResultadoOperacao> iniciar() async {
    ResultadoOperacao resultado = ResultadoOperacao.sucesso;

    var caminhoBanco = await getDatabasesPath();
    caminhoBanco = "$caminhoBanco/$ARMAZENAMENTO_LOCAL";

    try {
      await openDatabase(caminhoBanco, version: 1,
          onCreate: (Database banco, int version) async {
        await banco
            .execute("CREATE TABLE arvores(id TEXT PRIMARY KEY, json TEXT)");

        _banco = banco;
      }, onOpen: (Database banco) async {
        _banco = banco;
      });
    } catch (erro) {
      resultado = ResultadoOperacao.erro;

      print("ocorreu um erro adicionando/atualizando a árvore: $erro");
    }

    return resultado;
  }

  String getDatabasePath() {
    return _banco.path;
  }

  @override
  Future<Arvore?> getArvore(String id) async {
    Arvore? arvore;

    try {
      final registros =
          await _banco.rawQuery("SELECT json FROM arvores WHERE id = ?", [id]);
      for (final registro in registros) {
        String json = registro["json"] as String;

        arvore = Arvore.fromBancoDeDados(jsonDecode(json));
      }
    } catch (erro) {
      arvore = null;
    }

    return arvore;
  }

  @override
  Future<List<Arvore>> getArvores() async {
    List<Arvore> arvores = [];

    try {
      final registros = await _banco.rawQuery("SELECT json FROM arvores");
      for (final registro in registros) {
        String json = registro["json"] as String;

        arvores.add(Arvore.fromBancoDeDados(jsonDecode(json)));
      }
    } catch (erro) {
      arvores = [];
    }

    return arvores;
  }

  @override
  Future<ResultadoOperacao> adicionar(Arvore arvore) async {
    ResultadoOperacao resultado = ResultadoOperacao.erro;

    try {
      final json = jsonEncode(arvore.toJson());

      await _banco.rawInsert(
          "INSERT INTO arvores(id, json) VALUES (?, ?)", [arvore.id, json]);

      resultado = ResultadoOperacao.sucesso;
    } catch (erro) {
      print("ocorreu um erro adicionando a árvore: $erro");
    }

    return resultado;
  }

  @override
  Future<ResultadoOperacao> atualizar(Arvore arvore) async {
    ResultadoOperacao resultado = ResultadoOperacao.erro;

    try {
      final json = jsonEncode(arvore.toJson());

      await _banco.rawUpdate(
          "UPDATE arvores SET json = ? WHERE id = ?", [json, arvore.id]);

      resultado = ResultadoOperacao.sucesso;
    } catch (erro) {
      print("ocorreu um erro atualizando a árvore: $erro");
    }

    return resultado;
  }

  @override
  Future<ResultadoOperacao> remover(String id) async {
    ResultadoOperacao resultado = ResultadoOperacao.erro;

    try {
      await _banco.rawDelete("DELETE FROM arvores WHERE id = ?", [id]);

      resultado = ResultadoOperacao.sucesso;
    } catch (erro) {
      print("ocorreu um erro removendo a árvore: $erro");
    }

    return resultado;
  }
}

// api remota (ainda nao implementada)
class Remota extends API {
  @override
  bool disponivel() {
    return false;
  }

  @override
  Future<ResultadoOperacao> iniciar() {
    throw UnimplementedError();
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
  Future<Arvore?> getArvore(String id) {
    throw UnimplementedError();
  }

  @override
  Future<List<Arvore>> getArvores() {
    throw UnimplementedError();
  }

  @override
  Future<ResultadoOperacao> remover(String id) {
    throw UnimplementedError();
  }
}
