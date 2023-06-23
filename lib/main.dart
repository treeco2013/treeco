// ignore_for_file: unnecessary_getters_setters, avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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
  detalhandoArvore,
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
  Arvore? get arvoreSelecionada => _arvoreSelecionada;
  set arvoreSelecionada(Arvore? value) {
    _arvoreSelecionada = value;
  }

  Image? _imagemSelecionada;
  Image get imagemSelecionada => _imagemSelecionada!;
  set imagemSelecionada(Image value) {
    _imagemSelecionada = value;
  }

  late GoogleSignIn _loginGoogle;
  GoogleSignIn get loginGoogle => _loginGoogle;
  set loginGoogle(GoogleSignIn value) {
    _loginGoogle = value;
  }

  int _indiceImagemSelecionada = 0;
  bool _compartilhando = false;
  bool _posicionando = false;

  bool _apiLocal = false;

  @override
  void initState() {
    super.initState();

    setState(() {
      estado = Estado.iniciando;
    });

    exibirComoRetrato();

    final api = getAPI();
    api.iniciar().then((resultado) {
      if (resultado == ResultadoOperacao.sucesso) {
        arvores = Arvores(ativarDesativarDestaque, api);

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
    detalhes = Detalhes(gravarArvore, classificacaoSelecionada,
        temUsuarioLogado, classificacoes);

    imagens = Imagens(indiceImagemSelecionada, imagemParaVisualizar,
        ativarCamera, temUsuarioLogado);
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

  void exibirComoRetrato() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  void exibirMarcadores() {
    arvores
        .toMarcadores(
            idArvoreParaDestacar:
                arvoreSelecionada != null ? arvoreSelecionada!.id : "")
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

  void indiceImagemSelecionada(int indice) {
    _indiceImagemSelecionada = indice;
  }

  void imagemParaVisualizar(Uint8List bytesDaImagem) {
    imagemSelecionada = Image.memory(bytesDaImagem, fit: BoxFit.fill);

    setState(() {
      estado = Estado.visualizandoArvore;
    });
  }

  void classificacaoSelecionada(Arvore arvore) {
    setState(() {
      arvoreSelecionada!.identificacao = arvore.identificacao;
      arvoreSelecionada!.familia = arvore.familia;
      arvoreSelecionada!.especie = arvore.especie;
      arvoreSelecionada!.detalhes = arvore.detalhes;
    });
  }

  void ativarDesativarDestaque(Arvore arvore) {
    if (arvoreSelecionada == null) {
      destacarArvore(arvore);
    } else {
      removerDestaque();
    }
  }

  void destacarArvore(Arvore arvore) {
    arvoreSelecionada = arvore;

    setState(() {
      estado = Estado.marcandoArvore;
      opcaoSelecionada = MAPA;

      exibirMarcadores();
    });
  }

  void removerDestaque() {
    arvoreSelecionada = null;

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

  void alertarExecutar(
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

    if (arvoreSelecionada!.identificacao.isEmpty) {
      erros.add("informe a identificação da árvore");
    }
    if (arvoreSelecionada!.familia.isEmpty) {
      erros.add("informe a família da árvore");
    }
    if (arvoreSelecionada!.especie.isEmpty) {
      erros.add("informe a espécie da árvore");
    }

    return erros;
  }

  void atualizarClassificacoes() {
    if (!detalhes.classificacoes.arvores.contains(arvoreSelecionada)) {
      detalhes.classificacoes.arvores.add(arvoreSelecionada!);
    }
  }

  void gravarArvore({bool exibirMapa = true}) {
    final erros = validarArvore();

    if (erros.isNotEmpty) {
      alertar(erros.first);
    } else {
      arvores.gravarArvore(arvoreSelecionada!).then((resultado) async {
        exibirMarcadores();

        if (exibirMapa) {
          setState(() {
            estado = Estado.marcandoArvore;
            opcaoSelecionada = MAPA;
          });
        }

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
        arvoreSelecionada!.imagens.add(base64.encode(bytes));

        gravarArvore(exibirMapa: false);
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
        setState(() {
          imagem.readAsBytes().then((bytes) {
            String string = base64.encode(bytes);
            arvoreSelecionada!.imagens.add(string);

            gravarArvore(exibirMapa: false);
          });
        });
      }
    });
  }

  marcarUmaArvore() {
    arvoreSelecionada = Arvore();
    arvoreSelecionada!.posicao = mapa.posicao;
    arvoreSelecionada!.quemMarcou = usuario;

    atualizarPosicao(
        true,
        () => setState(() {
              estado = Estado.detalhandoArvore;
              opcaoSelecionada = DETALHES;
            }));
  }

  marcarDesmarcarProblema() {
    arvoreSelecionada!.comProblema = !arvoreSelecionada!.comProblema;

    gravarArvore();
  }

  void compartilhar() {
    arvores.exportarArvores().then((json) {
      if (json.isNotEmpty) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _compartilhando = true;
          });

          getTemporaryDirectory().then((dirTemporario) {
            final microsegs = DateTime.now().microsecondsSinceEpoch;

            final arquivo =
                File("${dirTemporario.path}/treeco.$microsegs.json");
            arquivo.writeAsStringSync(json);

            String zipado = "${dirTemporario.path}/treeco.$microsegs.zip";
            final zip = ZipFileEncoder();
            zip.create(zipado);
            zip.addFile(arquivo);
            zip.close();

            Share.shareXFiles([XFile(zipado)]).then((_) => setState(() {
                  _compartilhando = false;
                }));
          });
        });
      } else {
        alertar("não há árvores para serem compartilhadas");
      }
    });
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
          : const SizedBox.shrink(),
      temUsuarioLogado() && _apiLocal
          ? Container(
              margin: const EdgeInsets.all(MARGEM_DEFAULT),
              child: FloatingActionButton(
                  enableFeedback: true,
                  onPressed: () {
                    compartilhar();
                  },
                  child: const Icon(Icons.share)))
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
                    alertarExecutar("desejar remover a árvore?", () {
                      arvores
                          .removerArvore(arvoreSelecionada!.id)
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
      temUsuarioLogado()
          ? Container(
              margin: const EdgeInsets.all(MARGEM_DEFAULT),
              child: FloatingActionButton(
                  enableFeedback: true,
                  onPressed: () {
                    marcarDesmarcarProblema();
                  },
                  child: arvoreSelecionada!.comProblema
                      ? const Icon(Icons.verified)
                      : const Icon(Icons.report_problem_outlined)))
          : const SizedBox.shrink(),
      Container(
          margin: const EdgeInsets.all(MARGEM_DEFAULT),
          child: FloatingActionButton(
              enableFeedback: true,
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
              onPressed: () {
                setState(() {
                  camera.estadoCamera = EstadoCamera.desativada;
                });
              },
              child: const Icon(Icons.arrow_back)))
    ]);

    return botoes;
  }

  Widget getBotoesVisualizacaoArvore() {
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

  void removerImagem() {
    arvoreSelecionada!.imagens.removeAt(_indiceImagemSelecionada);

    gravarArvore(exibirMapa: false);
  }

  Widget getBotoesImagens() {
    final botoes = Column(children: [
      temUsuarioLogado() &&
              (arvoreSelecionada!.imagens.length < MAXIMO_DE_IMAGENS)
          ? Container(
              margin: const EdgeInsets.all(MARGEM_DEFAULT),
              child: FloatingActionButton(
                  enableFeedback: true,
                  onPressed: () {
                    ativarCamera();
                  },
                  child: const Icon(Icons.camera_alt_sharp)))
          : const SizedBox.shrink(),
      temUsuarioLogado() &&
              (arvoreSelecionada!.imagens.length < MAXIMO_DE_IMAGENS)
          ? Container(
              margin: const EdgeInsets.all(MARGEM_DEFAULT),
              child: FloatingActionButton(
                  enableFeedback: true,
                  onPressed: () {
                    selecionarImagem();
                  },
                  child: const Icon(Icons.folder)))
          : const SizedBox.shrink(),
      temUsuarioLogado() && arvoreSelecionada!.imagens.isNotEmpty
          ? Container(
              margin: const EdgeInsets.all(MARGEM_DEFAULT),
              child: FloatingActionButton(
                  enableFeedback: true,
                  onPressed: () {
                    alertarExecutar("deseja remover a imagem?", () {
                      removerImagem();
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

    bool temArvoreSelecionada = (arvoreSelecionada != null);
    bool arvoreSelecionadaGravada =
        temArvoreSelecionada && arvoreSelecionada!.id.isNotEmpty;

    if (estado == Estado.visualizandoArvore) {
      tela = Stack(children: [
        SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: imagemSelecionada),
        Container(
            alignment: Alignment.topRight, child: getBotoesVisualizacaoArvore())
      ]);
    } else if (_opcaoSelecionada == MAPA) {
      tela = Stack(children: [
        Center(child: _mapa.visualizar(!_posicionando)),
        _posicionando || _compartilhando
            ? Container(
                constraints: const BoxConstraints.expand(),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [CircularProgressIndicator(color: Colors.amber)],
                ))
            : Container(
                alignment: Alignment.topRight,
                child: arvoreSelecionadaGravada
                    ? getBotoesArvore()
                    : getBotoesMapa())
      ]);
    } else if (_opcaoSelecionada == DETALHES) {
      if (temArvoreSelecionada) {
        tela = detalhes.visualizar(arvoreSelecionada!);
      } else {
        tela = getSelecionarArvorePrimeiro();
      }
    } else if (_opcaoSelecionada == IMAGENS) {
      if (arvoreSelecionadaGravada) {
        tela = Stack(children: [
          camera.estadoCamera == EstadoCamera.ativada
              ? camera.iniciarCapturaDeFoto()
              : imagens.visualizar(arvoreSelecionada!),
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
              title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                const Text(" TREECO"),
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
