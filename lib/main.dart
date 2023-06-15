// ignore_for_file: unnecessary_getters_setters, avoid_print
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:treeco/api/api.dart';
import 'package:treeco/modelo/arvores.dart';
import 'package:treeco/camera.dart';
import 'package:treeco/telas/mapa.dart';
import 'package:treeco/constantes.dart';
import 'package:treeco/telas/imagens.dart';

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
      theme: ThemeData(
        primaryColor: Colors.green,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          color: Colors.green,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.green, selectedItemColor: Colors.white),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            color: Colors.black54,
          ),
        ),
      ),
      home: const TreeCo(),
    );
  }
}

enum Estado {
  iniciando,
  inicializacaoFalhou,
  visualizandoMapa,
  visualizandoArvore,
  marcandoArvore
}

typedef ExecutarAposPosicionar = void Function();
typedef ExecutarAposConfirmar = void Function();

class TreeCo extends StatefulWidget {
  const TreeCo({super.key});

  @override
  State<TreeCo> createState() => TreeCoState();
}

class TreeCoState extends State<TreeCo> {
  Estado _estado = Estado.iniciando;
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

  late Imagens _imagens;
  Imagens get imagens => _imagens;
  set imagens(Imagens value) {
    _imagens = value;
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

  late Arvores _arvores;
  Arvores get arvores => _arvores;
  set arvores(Arvores value) {
    _arvores = value;
  }

  Arvore? _arvoreSelecionada;
  Arvore get arvoreSelecionada => _arvoreSelecionada!;
  set arvoreSelecionada(Arvore value) {
    _arvoreSelecionada = value;
  }

  String? _imagemSelecionada;
  String get imagemSelecionada => _imagemSelecionada!;
  set imagemSelecionada(String value) {
    _imagemSelecionada = value;
  }

  late GoogleSignIn _loginGoogle;
  GoogleSignIn get loginGoogle => _loginGoogle;
  set loginGoogle(GoogleSignIn value) {
    _loginGoogle = value;
  }

  bool _posicionando = false;
  bool _apiLocal = false;

  @override
  void initState() {
    super.initState();

    setState(() {
      estado = Estado.iniciando;
    });

    final api = getAPI();
    api.iniciar().then((resultado) {
      if (resultado == ResultadoOperacao.sucesso) {
        arvores = Arvores(onArvoreSelecionada, api);

        iniciarMapa();
        exibirMarcadores();

        iniciarLogin();
        iniciarCamera();

        final classificacoes = getClassificacoes();
        classificacoes.iniciar().then((_) {
          classificacoes
              .adicionarClassificacoes(api)
              .then((_) => {iniciarTelas(classificacoes)});
        });

        setState(() {
          estado = Estado.visualizandoMapa;
        });

        if (_apiLocal) {
          alertar("você está usando armazenamento local");
        }
      } else {
        setState(() {
          estado = Estado.inicializacaoFalhou;
        });
      }
    });
  }

  void iniciarMapa() {
    mapa = Mapa();
    atualizarPosicao(false, () => {});
  }

  void iniciarLogin() {
    loginGoogle = GoogleSignIn(
      scopes: ['email'],
    );
    recuperarUsuarioLogado();
  }

  void iniciarCamera() {
    camera = Camera();
  }

  void iniciarTelas(final Classificacoes classificacoes) {
    detalhes = Detalhes(onArvoreParaGravar, onClassificacaoSelecionada,
        temUsuarioLogado, classificacoes);

    imagens = Imagens(onArvoreParaGravar, onImagemParaVisualizar,
        onAtivarCamera, temUsuarioLogado);
  }

  API getAPI() {
    _apiLocal = false;

    API api = Remota();
    if (!api.disponivel()) {
      api = Local();

      _apiLocal = true;
    }

    return api;
  }

  Classificacoes getClassificacoes() {
    final classificoes = Classificacoes();

    return classificoes;
  }

  void exibirMarcadores({String idArvoreParaDestacar = ""}) {
    arvores
        .toMarcadores(idArvoreParaDestacar: idArvoreParaDestacar)
        .then((marcadores) => setState(() {
              mapa.marcadores = marcadores;
            }));
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

  bool temUsuarioLogado() {
    return _usuario != null;
  }

  void onImagemParaVisualizar(String imagem) {
    imagemSelecionada = imagem;

    setState(() {
      estado = Estado.visualizandoArvore;
    });
  }

  void onClassificacaoSelecionada(Arvore arvore) {
    setState(() {
      arvoreSelecionada.identificacao = arvore.identificacao;
      arvoreSelecionada.familia = arvore.familia;
      arvoreSelecionada.especie = arvore.especie;
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

      exibirMarcadores(idArvoreParaDestacar: arvore.id);
    });
  }

  void removerDestaque() {
    setState(() {
      estado = Estado.visualizandoMapa;

      exibirMarcadores();
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

    if (arvoreSelecionada.identificacao.isEmpty) {
      erros.add("informe o tipo da árvore");
    }

    return erros;
  }

  void atualizarClassificacoes() {
    if (!detalhes.classificacoes.arvores.contains(arvoreSelecionada)) {
      detalhes.classificacoes.arvores.add(arvoreSelecionada);
    }
  }

  void gravarArvore(Estado estado) {
    final erros = validarArvore();

    if (erros.isNotEmpty) {
      alertar(erros.first);
    } else {
      arvores.gravarArvore(arvoreSelecionada).then((resultado) async {
        setState(() {
          this.estado = estado;

          exibirMarcadores();
        });

        if (resultado == ResultadoOperacao.sucesso) {
          atualizarClassificacoes();

          Fluttertoast.showToast(msg: "árvore gravada com sucesso");
        } else {
          Fluttertoast.showToast(msg: "não foi possível gravar árvore");
        }
      });
    }
  }

  void capturarImagem() {
    camera.capturar().then((imagem) {
      imagem.readAsBytes().then((bytes) {
        String string = base64.encode(bytes);
        arvoreSelecionada.imagens.add(string);
      });

      setState(() {
        camera.estadoCamera = EstadoCamera.desativada;
      });
    });
  }

  void selecionarImagem() {
    final imgPicker = ImagePicker();
    imgPicker.pickImage(source: ImageSource.gallery).then((imagem) {
      if (imagem != null) {
        print("imagem selecionada: ${imagem.path}");
        setState(() {
          imagem.readAsBytes().then((bytes) {
            String string = base64.encode(bytes);
            arvoreSelecionada.imagens.add(string);
          });
        });
      }
    });
  }

  marcarUmaArvore() {
    atualizarPosicao(
        true,
        () => setState(() {
              arvoreSelecionada = Arvore();
              arvoreSelecionada.posicao = mapa.posicao;
              arvoreSelecionada.quemMarcou = usuario;
              arvoreSelecionada.quemFotografou = usuario;

              estado = Estado.marcandoArvore;
              opcaoSelecionada = DETALHES;
            }));
  }

  Widget getBotoesMapa() {
    final botoes = Column(children: [
      Container(
          margin: const EdgeInsets.all(MARGEM_DEFAULT),
          child: FloatingActionButton(
              enableFeedback: true,
              onPressed: () {
                atualizarPosicao(true, () => {});
              },
              child: const Icon(Icons.gps_fixed_sharp))),
      temUsuarioLogado()
          ? Container(
              margin: const EdgeInsets.all(MARGEM_DEFAULT),
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
              margin: const EdgeInsets.all(MARGEM_DEFAULT),
              child: FloatingActionButton(
                  enableFeedback: true,
                  onPressed: () {
                    setState(() {
                      opcaoSelecionada = DETALHES;
                    });
                  },
                  child: const Icon(Icons.edit)))
          : const SizedBox.shrink(),
      temUsuarioLogado()
          ? Container(
              margin: const EdgeInsets.all(MARGEM_DEFAULT),
              child: FloatingActionButton(
                  enableFeedback: true,
                  onPressed: () {
                    remover("desejar remover a árvore?", () {
                      arvores
                          .removerArvore(arvoreSelecionada.id)
                          .then((resultado) {
                        removerDestaque();

                        if (resultado == ResultadoOperacao.sucesso) {
                          Fluttertoast.showToast(
                              msg: "árvore removida com sucesso");
                        } else {
                          Fluttertoast.showToast(
                              msg: "não foi possível remover a árvore");
                        }
                      });
                    });
                  },
                  child: const Icon(Icons.delete)))
          : const SizedBox.shrink(),
      Container(
          margin: const EdgeInsets.all(MARGEM_DEFAULT),
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

  void onAtivarCamera() {
    camera.iniciar().then((estado) => {
          if (estado == EstadoCamera.disponivel)
            setState(() {
              camera.ativarCamera();
            })
        });
  }

  Widget getBotoesCamera() {
    final botoes = Column(children: [
      Container(
          margin: const EdgeInsets.all(MARGEM_DEFAULT),
          child: FloatingActionButton(
              enableFeedback: true,
              onPressed: () => capturarImagem(),
              child: const Icon(Icons.check))),
      Container(
          margin: const EdgeInsets.all(MARGEM_DEFAULT),
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
          margin: const EdgeInsets.all(MARGEM_DEFAULT),
          child: FloatingActionButton(
              enableFeedback: true,
              backgroundColor: Colors.blue,
              onPressed: () {
                setState(() {
                  estado = Estado.marcandoArvore;
                });
              },
              child: const Icon(Icons.arrow_back)))
    ]);

    return botoes;
  }

  Widget getBotoesImagens() {
    final botoes = Column(children: [
      temUsuarioLogado()
          ? Container(
              margin: const EdgeInsets.all(MARGEM_DEFAULT),
              child: FloatingActionButton(
                  enableFeedback: true,
                  onPressed: () {
                    onAtivarCamera();
                  },
                  child: const Icon(Icons.camera_alt_sharp)))
          : const SizedBox.shrink(),
      temUsuarioLogado() && arvoreSelecionada.imagens.isNotEmpty
          ? Container(
              margin: const EdgeInsets.all(MARGEM_DEFAULT),
              child: FloatingActionButton(
                  enableFeedback: true,
                  onPressed: () {
                    remover("deseja remover a foto?", () {
                      setState(() {
                        // arvoreSelecionada.imagem = "";
                      });
                    });
                  },
                  child: const Icon(Icons.delete)))
          : const SizedBox.shrink()
    ]);

    return botoes;
  }

  void onOpcaoSelecionada(int opcao) {
    setState(() {
      opcaoSelecionada = opcao;
    });
  }

  Widget getSelecionarArvorePrimeiro() {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      FloatingActionButton(
          enableFeedback: true,
          onPressed: () {
            setState(() {
              opcaoSelecionada = MAPA;
            });
          },
          child: const Icon(Icons.arrow_back)),
      const Padding(
          padding: EdgeInsets.all(6),
          child: Text("selecione uma árvore primeiro",
              textAlign: TextAlign.center))
    ]));
  }

  Widget getTelaDaOpcaoSelecionada() {
    Widget tela = const SizedBox.shrink();

    if (estado == Estado.visualizandoArvore) {
      final bytes = base64.decode(imagemSelecionada);

      tela = Stack(children: [
        SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Image.memory(bytes, fit: BoxFit.fill)),
        Container(
            alignment: Alignment.topRight, child: getBotoesVisualizacaoArvore())
      ]);
    } else if (_opcaoSelecionada == MAPA) {
      tela = Stack(children: [
        Center(child: _mapa.visualizar(!_posicionando)),
        _posicionando
            ? Container(
                constraints: const BoxConstraints.expand(),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [CircularProgressIndicator(color: Colors.amber)],
                ))
            : Container(
                alignment: Alignment.topRight,
                child: estado == Estado.marcandoArvore
                    ? getBotoesArvore()
                    : getBotoesMapa())
      ]);
    } else if (_opcaoSelecionada == DETALHES) {
      if (estado == Estado.marcandoArvore) {
        tela = detalhes.visualizar(arvoreSelecionada);
      } else {
        tela = getSelecionarArvorePrimeiro();
      }
    } else if (_opcaoSelecionada == IMAGENS) {
      if (estado == Estado.marcandoArvore) {
        tela = Stack(children: [
          camera.estadoCamera == EstadoCamera.ativada
              ? camera.iniciarCapturaDeFoto()
              : imagens.visualizar(arvoreSelecionada),
          Container(
              alignment: Alignment.topRight,
              child: camera.estadoCamera == EstadoCamera.ativada
                  ? getBotoesCamera()
                  : getBotoesImagens())
        ]);
      } else {
        tela = getSelecionarArvorePrimeiro();
      }
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
      setState(() => _usuario = null);

      Fluttertoast.showToast(msg: "você foi desconectado com sucesso!");
    });
  }

  @override
  Widget build(BuildContext context) {
    late Widget tela;

    if (estado == Estado.iniciando) {
      tela = Stack(children: [
        SizedBox.expand(
            child: Container(
          color: const Color(0xfffdf69e),
          child: const SizedBox.shrink(),
        )),
        const Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [CircularProgressIndicator(color: Colors.green)]))
      ]);
    } else if (estado == Estado.inicializacaoFalhou) {
      tela = Stack(children: [
        SizedBox.expand(
            child: Container(
          color: const Color(0xfffdf69e),
          child: const SizedBox.shrink(),
        )),
        Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Image(
            image: AssetImage('lib/recursos/icones/icon.png'),
            width: 160,
            height: 160,
          ),
          Material(
              color: Colors.transparent,
              child: Text("ocorreu uma falha iniciando o aplicativo :(",
                  style: TextStyle(fontSize: 14, color: Colors.red[800])))
        ]))
      ]);
    } else {
      tela = Scaffold(
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
                        icon: Icon(Icons.image),
                        label: 'Imagens',
                      ),
                    ],
                  currentIndex: _opcaoSelecionada,
                  onTap: (value) => onOpcaoSelecionada(value)));
    }

    return tela;
  }
}
