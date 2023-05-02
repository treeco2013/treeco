// ignore_for_file: unnecessary_getters_setters, avoid_print
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:treeco/modelo/arvores.dart';
import 'package:treeco/camera.dart';
import 'package:treeco/telas/mapa.dart';
import 'package:treeco/constantes.dart';
import 'package:treeco/telas/sobre.dart';

import 'modelo/usuario.dart';
import 'telas/detalhes.dart';
import 'modelo/arvore.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TreeCo',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const TreeCo(),
    );
  }
}

enum Estado { visualizandoMapa, visualizandoArvore, marcandoArvore }

typedef ExecutarAposPosicionar = void Function();
typedef ExecutarAposConfirmar = void Function();

class TreeCo extends StatefulWidget {
  const TreeCo({super.key});

  @override
  State<TreeCo> createState() => TreeCoState();
}

class TreeCoState extends State<TreeCo> {
  Estado _estado = Estado.visualizandoMapa;
  Estado get estado => _estado;
  set estado(Estado value) {
    _estado = value;
  }

  late Mapa _mapa;
  Mapa get mapa => _mapa;
  set mapa(Mapa value) {
    _mapa = value;
  }

  late Camera _camera;
  Camera get camera => _camera;
  set camera(Camera value) {
    _camera = value;
  }

  late Detalhes _detalhes;
  Detalhes get detalhes => _detalhes;
  set detalhes(Detalhes value) {
    _detalhes = value;
  }

  Usuario? _usuario;
  Usuario get usuario => _usuario!;
  set usuario(Usuario value) {
    _usuario = value;
  }

  int _opcaoSelecionada = 0;
  set opcaoSelecionada(int value) {
    _opcaoSelecionada = value;
  }

  late Arvores _arvoresAPI;
  Arvores get arvoresAPI => _arvoresAPI;
  set arvoresAPI(Arvores value) {
    _arvoresAPI = value;
  }

  Arvore? _arvoreSelecionada;
  Arvore get arvoreSelecionada => _arvoreSelecionada!;
  set arvoreSelecionada(Arvore value) {
    _arvoreSelecionada = value;
  }

  late GoogleSignIn _loginGoogle;
  GoogleSignIn get loginGoogle => _loginGoogle;
  set loginGoogle(GoogleSignIn value) {
    _loginGoogle = value;
  }

  bool _posicionando = false;

  @override
  void initState() {
    super.initState();

    mapa = Mapa();
    atualizarPosicao(false, () => {});

    camera = Camera();
    detalhes = Detalhes(onArvoreParaGravar, onImagemParaVisualizar,
        temUsuarioLogado, ativarCamera);

    loginGoogle = GoogleSignIn(
      scopes: ['email'],
    );
    recuperarUsuarioLogado();

    arvoresAPI = Arvores(onArvoreSelecionada);
  }

  void recuperarUsuarioLogado() {
    loginGoogle.isSignedIn().then((logado) => {
          if (logado)
            {
              loginGoogle.signInSilently().then((usuarioGoogle) => {
                    setState(() {
                      usuario = Usuario(
                          conta: usuarioGoogle!.email,
                          nome: usuarioGoogle.displayName.toString());
                    })
                  })
            }
        });
  }

  void onImagemParaVisualizar(Arvore arvore) {
    arvoreSelecionada = arvore;

    setState(() {
      estado = Estado.visualizandoArvore;
    });
  }

  void onArvoreParaGravar(Arvore arvore) {
    arvoreSelecionada = arvore;

    gravarArvore(Estado.marcandoArvore);
  }

  void onArvoreSelecionada(Arvore arvore, _) {
    arvoreSelecionada = arvore;

    destacarArvore(arvoreSelecionada);
  }

  void destacarArvore(Arvore arvore) {
    setState(() {
      estado = Estado.marcandoArvore;

      mapa.marcadores =
          arvoresAPI.toMarcadores(idArvoreParaDestacar: arvore.id);
    });
  }

  void removerDestaque() {
    setState(() {
      estado = Estado.visualizandoMapa;

      mapa.marcadores = arvoresAPI.toMarcadores();
    });
  }

  void atualizarPosicao(
      bool centralizar, ExecutarAposPosicionar executarAposPosicionar) {
    setState(() {
      _posicionando = true;
    });

    mapa
        .atualizarPosicao()
        .then((value) => mapa.atualizarPosicao().then((estado) {
              if (estado == EstadoPosicionamento.atualizado) {
                setState(() {
                  if (centralizar) {
                    mapa.centralizar();
                  }

                  _posicionando = false;
                  Fluttertoast.showToast(msg: "sua posição foi atualizada");

                  executarAposPosicionar();
                });
              } else {
                setState(() {
                  _posicionando = false;
                  Fluttertoast.showToast(
                      msg: "não foi possível atualizar sua posição");
                });
              }
            }));
  }

  void remover(
      String mensagemDeAlerta, ExecutarAposConfirmar executarAposConfirmar) {
    Widget cancelar = TextButton(
      onPressed: () {
        Navigator.of(context).pop();
      },
      child: const Text('não'),
    );
    Widget confirmar = TextButton(
      onPressed: () {
        executarAposConfirmar();

        Navigator.of(context).pop();
      },
      child: const Text('sim'),
    );

    AlertDialog alert = AlertDialog(
      content: Text(mensagemDeAlerta),
      actions: [
        cancelar,
        confirmar,
      ],
    );

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Future<void> alertar(String alerta) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(alerta),
          actions: [
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  List<String> validarArvore() {
    List<String> erros = [];

    if (arvoreSelecionada.tipo.isEmpty) {
      erros.add("informe o tipo da árvore");
    }
    if (arvoreSelecionada.imagem.isEmpty) {
      erros.add("capture uma foto da árvore");
    }

    return erros;
  }

  gravarArvore(Estado estado) {
    final erros = validarArvore();

    if (erros.isNotEmpty) {
      alertar(erros.first);
    } else {
      arvoresAPI.adicionarArvore(arvoreSelecionada);

      setState(() {
        this.estado = estado;
        mapa.marcadores = arvoresAPI.toMarcadores(
            idArvoreParaDestacar:
                estado == Estado.marcandoArvore ? arvoreSelecionada.id : "");

        Fluttertoast.showToast(msg: "dados gravados com sucesso!");
      });
    }
  }

  marcarUmaArvore() {
    atualizarPosicao(
        true,
        () => {
              setState(() {
                arvoreSelecionada = Arvore();
                arvoreSelecionada.posicao = mapa.posicao;
                arvoreSelecionada.quemMarcou = usuario;

                estado = Estado.marcandoArvore;
                opcaoSelecionada = DETALHES_DE_ARVORE;
              })
            });
  }

  Widget getBotoesMapa() {
    final botoes = Column(children: [
      Container(
          margin: const EdgeInsets.all(5),
          child: FloatingActionButton(
              enableFeedback: true,
              onPressed: () {
                atualizarPosicao(true, () => {});
              },
              child: const Icon(Icons.gps_fixed_sharp))),
      temUsuarioLogado()
          ? Container(
              margin: const EdgeInsets.all(5),
              child: FloatingActionButton(
                  enableFeedback: true,
                  onPressed: () {
                    marcarUmaArvore();
                  },
                  child: const Icon(Icons.add_location_alt_sharp)))
          : const SizedBox.shrink()
    ]);

    return botoes;
  }

  Widget getBotoesArvore() {
    final botoes = Column(children: [
      temUsuarioLogado()
          ? Container(
              margin: const EdgeInsets.all(5),
              child: FloatingActionButton(
                  enableFeedback: true,
                  onPressed: () {
                    setState(() {
                      opcaoSelecionada = DETALHES_DE_ARVORE;
                    });
                  },
                  child: const Icon(Icons.edit)))
          : const SizedBox.shrink(),
      Container(
          margin: const EdgeInsets.all(5),
          child: FloatingActionButton(
              enableFeedback: true,
              onPressed: () {
                onImagemParaVisualizar(arvoreSelecionada);
              },
              child: const Icon(Icons.preview))),
      temUsuarioLogado()
          ? Container(
              margin: const EdgeInsets.all(5),
              child: FloatingActionButton(
                  enableFeedback: true,
                  onPressed: () {
                    remover("desejar remover a árvore?", () {
                      arvoresAPI.removerArvore(arvoreSelecionada.id);

                      setState(() {
                        mapa.marcadores = arvoresAPI.toMarcadores();
                        estado = Estado.visualizandoMapa;

                        Fluttertoast.showToast(
                            msg: "árvore removida com sucesso");
                      });
                    });
                  },
                  child: const Icon(Icons.delete)))
          : const SizedBox.shrink(),
      Container(
          margin: const EdgeInsets.all(5),
          child: FloatingActionButton(
              enableFeedback: true,
              mini: true,
              backgroundColor: Colors.blue,
              onPressed: () {
                removerDestaque();
              },
              child: const Icon(Icons.check)))
    ]);

    return botoes;
  }

  void ativarCamera() {
    camera.iniciar().then((estado) => {
          if (estado == EstadoCamera.disponivel)
            setState(() {
              camera.ativarCamera();
            })
        });
  }

  Widget getBotoesDetalhes() {
    final botoes = Column(children: [
      temUsuarioLogado()
          ? Container(
              margin: const EdgeInsets.all(5),
              child: FloatingActionButton(
                  enableFeedback: true,
                  onPressed: () {
                    ativarCamera();
                  },
                  child: const Icon(Icons.camera_alt_sharp)))
          : const SizedBox.shrink(),
      temUsuarioLogado() && arvoreSelecionada.imagem.isNotEmpty
          ? Container(
              margin: const EdgeInsets.all(5),
              child: FloatingActionButton(
                  enableFeedback: true,
                  onPressed: () {
                    remover("deseja remover a foto?", () {
                      setState(() {
                        arvoreSelecionada.imagem = "";
                      });
                    });
                  },
                  child: const Icon(Icons.delete)))
          : const SizedBox.shrink(),
      Container(
          margin: const EdgeInsets.all(5),
          child: FloatingActionButton(
              enableFeedback: true,
              backgroundColor: Colors.blue,
              mini: true,
              onPressed: () {
                setState(() {
                  opcaoSelecionada = MAPA_DE_ARVORES;
                });
              },
              child: const Icon(Icons.arrow_back)))
    ]);

    return botoes;
  }

  Widget getBotoesCamera() {
    final botoes = Column(children: [
      Container(
          margin: const EdgeInsets.all(5),
          child: FloatingActionButton(
              enableFeedback: true,
              onPressed: () {
                camera.capturar().then((foto) {
                  detalhes.arvore.imagem = foto.path;

                  setState(() {
                    camera.estadoCamera = EstadoCamera.desativada;
                  });
                });
              },
              child: const Icon(Icons.check))),
      Container(
          margin: const EdgeInsets.all(5),
          child: FloatingActionButton(
              enableFeedback: true,
              backgroundColor: Colors.blue,
              mini: true,
              onPressed: () {
                setState(() {
                  camera.estadoCamera = EstadoCamera.desativada;
                });
              },
              child: const Icon(Icons.arrow_back)))
    ]);

    return botoes;
  }

  getBotoesVisualizacaoArvore() {
    final botoes = Column(children: [
      Container(
          margin: const EdgeInsets.all(5),
          child: FloatingActionButton(
              enableFeedback: true,
              backgroundColor: Colors.blue,
              mini: true,
              onPressed: () {
                setState(() {
                  estado = Estado.marcandoArvore;
                });
              },
              child: const Icon(Icons.arrow_back)))
    ]);

    return botoes;
  }

  void onOpcaoSelecionada(int opcao) {
    setState(() {
      opcaoSelecionada = opcao;
    });
  }

  Widget getTelaDaOpcaoSelecionada() {
    Widget tela = const SizedBox.shrink();

    if (estado == Estado.visualizandoArvore) {
      final file = File(arvoreSelecionada.imagem);

      tela = Stack(children: [
        SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Image.file(file, fit: BoxFit.fill)),
        Container(
            alignment: Alignment.topRight, child: getBotoesVisualizacaoArvore())
      ]);
    } else if (_opcaoSelecionada == MAPA_DE_ARVORES) {
      tela = Stack(children: [
        Center(child: _mapa.visualizar(!_posicionando)),
        _posicionando
            ? Container(
                constraints: const BoxConstraints.expand(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(color: Colors.amber)
                  ],
                ))
            : Container(
                alignment: Alignment.topRight,
                child: estado == Estado.marcandoArvore
                    ? getBotoesArvore()
                    : getBotoesMapa())
      ]);
    } else if (_opcaoSelecionada == DETALHES_DE_ARVORE) {
      if (estado == Estado.marcandoArvore) {
        tela = Stack(children: [
          camera.estadoCamera == EstadoCamera.ativada
              ? camera.iniciarCapturaDeFoto()
              : detalhes.visualizar(arvoreSelecionada),
          Container(
              alignment: Alignment.topRight,
              child: camera.estadoCamera == EstadoCamera.ativada
                  ? getBotoesCamera()
                  : getBotoesDetalhes())
        ]);
      } else {
        tela = Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          FloatingActionButton(
              enableFeedback: true,
              onPressed: () {
                setState(() {
                  opcaoSelecionada = MAPA_DE_ARVORES;
                });
              },
              child: const Icon(Icons.arrow_back)),
          const Padding(
              padding: EdgeInsets.all(6),
              child: Text("selecione uma árvore primeiro",
                  textAlign: TextAlign.center))
        ]));
      }
    } else if (_opcaoSelecionada == SOBRE) {
      tela = Sobre().visualizar();
    }

    return tela;
  }

  void login() {
    loginGoogle
        .signIn()
        .then((usuarioGoogle) => {
              setState(() {
                usuario = Usuario(
                    conta: usuarioGoogle!.email,
                    nome: usuarioGoogle.displayName.toString());

                Fluttertoast.showToast(msg: "seja bem-vindo, ${usuario.nome}");
              })
            })
        .catchError((error) =>
            {Fluttertoast.showToast(msg: "não foi possível realizar o login")});
  }

  void logout() {
    loginGoogle.disconnect().then((_) {
      setState(() => {_usuario = null});

      Fluttertoast.showToast(msg: "você foi desconectado com sucesso!");
    });
  }

  bool temUsuarioLogado() {
    return _usuario != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Row(children: [
          const Text("TREECO marque "),
          const Icon(Icons.add_location_alt_sharp),
          const Text(" uma árvore"),
          const Spacer(),
          GestureDetector(
              onTap: () {
                if (temUsuarioLogado()) {
                  logout();
                } else {
                  login();
                }
              },
              child: temUsuarioLogado()
                  ? const Icon(Icons.logout)
                  : const Icon(Icons.login))
        ])),
        body: getTelaDaOpcaoSelecionada(),
        bottomNavigationBar: camera.estadoCamera == EstadoCamera.ativada
            ? const SizedBox.shrink()
            : BottomNavigationBar(
                items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      icon: Icon(Icons.add_location_alt_sharp),
                      label: "Mapa",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.more),
                      label: 'Detalhes',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.info),
                      label: "Sobre",
                    ),
                  ],
                currentIndex: _opcaoSelecionada,
                backgroundColor: Colors.green,
                selectedItemColor: Colors.black,
                onTap: (value) => onOpcaoSelecionada(value)));
  }
}
