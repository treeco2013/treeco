// ignore_for_file: unnecessary_getters_setters, avoid_print
import 'package:flutter/material.dart';
import 'package:treeco/api/api.dart';
import '../constantes.dart';
import '../modelo/arvore.dart';
import '../recursos/login.dart';

typedef OnGravarArvore = void Function({bool exibirMapa});
typedef OnClassificacaoSelecionada = void Function(Arvore arvore);

typedef TemUsuarioLogado = bool Function();

class Detalhes {
  late Arvore _arvore;
  Arvore get arvore => _arvore;
  set arvore(Arvore value) {
    _arvore = value;
  }

  late OnGravarArvore _onGravarArvore;
  OnGravarArvore get onGravarArvore => _onGravarArvore;
  set onGravarArvore(OnGravarArvore value) {
    _onGravarArvore = value;
  }

  late OnClassificacaoSelecionada _onClassificacaoSelecionada;
  OnClassificacaoSelecionada get onClassificacaoSelecionada =>
      _onClassificacaoSelecionada;
  set onClassificacaoSelecionada(OnClassificacaoSelecionada value) {
    _onClassificacaoSelecionada = value;
  }

  late Classificacoes _classificacoes;
  Classificacoes get classificacoes => _classificacoes;
  set classificacoes(Classificacoes value) {
    _classificacoes = value;
  }

  Detalhes(
      OnGravarArvore onGravarArvore,
      OnClassificacaoSelecionada onClassificacaoSelecionada,
      Classificacoes classificacoes) {
    this.onClassificacaoSelecionada = onClassificacaoSelecionada;
    this.onGravarArvore = onGravarArvore;

    this.classificacoes = classificacoes;
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
                  padding: const EdgeInsets.all(MARGEM_DEFAULT),
                  child: Autocomplete<Arvore>(
                      initialValue:
                          TextEditingValue(text: arvore.identificacao),
                      optionsBuilder: (TextEditingValue value) {
                        if (value.text.isEmpty) {
                          return const Iterable<Arvore>.empty();
                        }
                        return classificacoes.arvores
                            .where((final Arvore arvore) {
                          return arvore.identificacao
                              .toLowerCase()
                              .startsWith(value.text.toLowerCase());
                        });
                      },
                      onSelected: (final Arvore arvoreSelecionada) {
                        onClassificacaoSelecionada(arvoreSelecionada);
                      },
                      fieldViewBuilder: (BuildContext context,
                          TextEditingController textEditingController,
                          FocusNode focusNode,
                          VoidCallback onFieldSubmitted) {
                        return TextFormField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          onChanged: (String identificacao) {
                            arvore.identificacao = identificacao;
                          },
                          onFieldSubmitted: (String identificacao) {
                            arvore.identificacao = identificacao;

                            onFieldSubmitted();
                          },
                          decoration:
                              const InputDecoration(hintText: 'identificação'),
                        );
                      })),
              Padding(
                padding: const EdgeInsets.all(MARGEM_DEFAULT),
                child: TextFormField(
                    initialValue: arvore.familia,
                    enabled: temUsuarioLogado(),
                    decoration: const InputDecoration(hintText: 'familia'),
                    onChanged: (value) => arvore.familia = value),
              ),
              Padding(
                padding: const EdgeInsets.all(MARGEM_DEFAULT),
                child: TextFormField(
                    initialValue: arvore.especie,
                    enabled: temUsuarioLogado(),
                    decoration: const InputDecoration(hintText: 'especie'),
                    onChanged: (value) => arvore.especie = value),
              ),
              Padding(
                padding: const EdgeInsets.all(MARGEM_DEFAULT),
                child: TextFormField(
                    initialValue: arvore.detalhes,
                    enabled: temUsuarioLogado(),
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    decoration:
                        const InputDecoration(hintText: 'mais detalhes'),
                    onChanged: (value) => arvore.detalhes = value),
              ),
              arvore.identificacao.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(MARGEM_DEFAULT),
                      child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                              "últimas alterações realizadas por ${arvore.quemMarcou!.nome}",
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black45))))
                  : const SizedBox.shrink(),
              temUsuarioLogado()
                  ? Padding(
                      padding: const EdgeInsets.all(MARGEM_DEFAULT),
                      child: Container(
                          width: double.infinity,
                          color: Colors.transparent,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green),
                            onPressed: () {
                              onGravarArvore(exibirMapa: false);
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
