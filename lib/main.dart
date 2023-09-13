// ignore_for_file: unnecessary_getters_setters, avoid_print, depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:treeco/api/api.dart';
import 'package:treeco/recursos/camera.dart';
import 'package:treeco/telas/mapa.dart';
import 'package:treeco/constantes.dart';
import 'package:treeco/telas/imagens.dart';
import 'package:treeco/recursos/utils.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'recursos/login.dart';
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
  comErro,
  visualizandoMapa,
  visualizandoArvore,
  detalhandoArvore,
  marcandoArvore
}

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

  int _opcaoSelecionada = 0;
  set opcaoSelecionada(int value) {
    _opcaoSelecionada = value;
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

  int _indiceImagemSelecionada = 0;
  bool _posicionando = false;

  @override
  void initState() {
    super.initState();

    setState(() {
      estado = Estado.iniciando;
    });

    exibirComoRetrato();

    dotenv.load(fileName: ".env").then((_) => _iniciar());
  }

  void _iniciar() {
    mapa = Mapa();

    api = Remota();
    api.iniciar((Object erro) {
      debugPrint('ocorreu um erro usando o Treeco: $erro');

      setState(() {
        estado = Estado.comErro;
      });
    }).then((resultado) {
      if (resultado == ResultadoOperacao.sucesso) {
        api.disponivel().then((final disponivel) {
          if (disponivel) {
            _atualizarPosicao(false, () => {});
            _atualizarArvoresMarcadas();

            recuperarUsuarioLogado((_) {});

            iniciarCamera();

            _configurarTelas(api);

            setState(() {
              estado = Estado.visualizandoMapa;
            });
          } else {
            setState(() {
              estado = Estado.comErro;
            });
          }
        });
      } else {
        setState(() {
          estado = Estado.comErro;
        });
      }
    });
  }

  void _configurarTelas(API api) {
    api.getConfiguracoes().then((configuracoes) {
      final classificacoes = Classificacoes();
      classificacoes.iniciar(
        (_) {
          setState(() => estado = Estado.comErro);
        },
      ).then((_) {
        classificacoes
            .adicionarClassificacoes(api)
            .then((_) => {_iniciarTelas(classificacoes, configuracoes)});
      });
    });
  }

  void _destacarArvore(Arvore arvore) {
    arvoreSelecionada = arvore;

    setState(() {
      estado = Estado.marcandoArvore;
      opcaoSelecionada = MAPA;

      _atualizarArvoresMarcadas();
    });
  }

  void _removerDestaque() {
    arvoreSelecionada = null;

    setState(() {
      estado = Estado.visualizandoMapa;

      _atualizarArvoresMarcadas();
    });
  }

  void _iniciarTelas(final Classificacoes classificacoes,
      final Map<String, dynamic> configuracoes) {
    detalhes =
        Detalhes(_gravarArvore, _classificacaoSelecionada, classificacoes);

    imagens = Imagens((indice) => _indiceImagemSelecionada = indice, (url) {
      imagemSelecionada = Image.network(url, fit: BoxFit.fill);

      setState(() {
        estado = Estado.visualizandoArvore;
      });
    }, configuracoes['hostImagens']);
  }

  Widget _getMarcadorArvore(Arvore arvore, bool destacar) {
    String imagem = "";

    if (arvore.comProblema) {
      imagem = "lib/recursos/imagens/marcador_problema.png";
      if (destacar) {
        imagem = "lib/recursos/imagens/marcador_problema_destacado.png";
      }
    } else {
      imagem = "lib/recursos/imagens/marcador.png";
      if (destacar) {
        imagem = "lib/recursos/imagens/marcador_destacado.png";
      }
    }

    return GestureDetector(
        child: Stack(children: [
          Image.asset(imagem,
              width: TAMANHO_MARCADOR, height: TAMANHO_MARCADOR),
          !destacar
              ? Center(
                  child: Text(
                  arvore.identificacao,
                  style: const TextStyle(
                      fontSize: TAMANHO_FONTE_MARCADOR,
                      color: Colors.white,
                      backgroundColor: Colors.blueGrey),
                ))
              : const SizedBox.shrink()
        ]),
        onTap: () {
          if (arvoreSelecionada == null) {
            _destacarArvore(arvore);
          } else {
            _removerDestaque();
          }
        });
  }

  Future<List<Marker>> _getMarcadoresArvores(
      {int idArvoreSelecionada = 0}) async {
    List<Marker> marcadores = [];

    final arvores = await api.getArvores();
    for (final arvore in arvores) {
      bool arvoreSelecionada = (idArvoreSelecionada == arvore.id);

      marcadores.add(Marker(
          point: LatLng(arvore.posicao.latitude, arvore.posicao.longitude),
          width: TAMANHO_MARCADOR_DE_ARVORE,
          height: TAMANHO_MARCADOR_DE_ARVORE,
          builder: (context) => _getMarcadorArvore(arvore, arvoreSelecionada)));
    }

    return marcadores;
  }

  void _atualizarArvoresMarcadas() {
    _getMarcadoresArvores(
            idArvoreSelecionada:
                arvoreSelecionada != null ? arvoreSelecionada!.id : 0)
        .then((marcadores) => setState(() {
              mapa.marcadores = marcadores;
            }));
  }

  void _classificacaoSelecionada(Arvore arvore) {
    setState(() {
      arvoreSelecionada!.identificacao = arvore.identificacao;
      arvoreSelecionada!.familia = arvore.familia;
      arvoreSelecionada!.especie = arvore.especie;
      arvoreSelecionada!.detalhes = arvore.detalhes;
    });
  }

  void _atualizarPosicao(
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

  Future<void> _gravarArvore({bool exibirMapa = true}) async {
    final erros = Arvore.validarArvore(arvoreSelecionada!);

    if (erros.isNotEmpty) {
      alertar(context, erros.first);
    } else {
      ResultadoOperacao resultado;

      if (arvoreSelecionada!.id != 0) {
        resultado = await api.atualizar(arvoreSelecionada!);
      } else {
        resultado = await api.adicionar(arvoreSelecionada!);
      }

      if (resultado == ResultadoOperacao.sucesso) {
        _atualizarArvoresMarcadas();

        if (!detalhes.classificacoes.arvores.contains(arvoreSelecionada)) {
          detalhes.classificacoes.arvores.add(arvoreSelecionada!);
        }

        if (exibirMapa) {
          setState(() {
            estado = Estado.marcandoArvore;
            opcaoSelecionada = MAPA;
          });
        }

        Fluttertoast.showToast(msg: "árvore gravada com sucesso");
      } else {
        Fluttertoast.showToast(msg: "não foi possível gravar árvore");
      }
    }
  }

  Future<void> _atualizarImagens(VoidCallback aposAtualizar) async {
    final atualizada = await api.getArvore(arvoreSelecionada!.id);
    if (atualizada != null) {
      arvoreSelecionada!.imagens = atualizada.imagens;

      aposAtualizar();
    }
  }

  void _adicionarImagem(XFile imagem) {
    api.adicionarImagem(arvoreSelecionada!.id, imagem.path).then((resultado) {
      if (resultado == ResultadoOperacao.sucesso) {
        Fluttertoast.showToast(msg: "imagem gravada com sucesso");
      } else {
        Fluttertoast.showToast(msg: "não foi possível gravar a imagem");
      }

      _atualizarImagens(() {
        if (arvoreSelecionada!.imagens.isNotEmpty) {
          _indiceImagemSelecionada = arvoreSelecionada!.imagens.length - 1;
        }

        setState(() {
          desativarCamera();
        });
      });
    });
  }

  void _removerImagem() {
    final imagem =
        arvoreSelecionada!.imagens.elementAt(_indiceImagemSelecionada);

    api.removerImagem(imagem.id).then((resultado) {
      if (resultado == ResultadoOperacao.sucesso) {
        Fluttertoast.showToast(msg: "imagem removida com sucesso");
      } else {
        Fluttertoast.showToast(msg: "não foi possível remover a imagem");
      }

      _atualizarImagens(() => setState(() {}));
    });
  }

  void _marcarUmaArvore() {
    arvoreSelecionada = Arvore();
    arvoreSelecionada!.posicao = mapa.posicao;
    arvoreSelecionada!.quemMarcou = temUsuarioLogado() ? usuario! : usuario!;

    _atualizarPosicao(
        true,
        () => setState(() {
              estado = Estado.detalhandoArvore;
              opcaoSelecionada = DETALHES;
            }));
  }

  Widget _getBotoesMapa() {
    final botoes = Column(children: [
      Container(
          margin: const EdgeInsets.all(MARGEM_DEFAULT),
          child: FloatingActionButton(
              enableFeedback: true,
              onPressed: () {
                _atualizarPosicao(true, () => {});
              },
              child: const Icon(Icons.gps_fixed_sharp))),
      temUsuarioLogado()
          ? Container(
              margin: const EdgeInsets.all(MARGEM_DEFAULT),
              child: FloatingActionButton(
                  enableFeedback: true,
                  onPressed: () {
                    _marcarUmaArvore();
                  },
                  child: const Icon(Icons.add_location_alt_sharp)))
          : const SizedBox.shrink(),
    ]);

    return botoes;
  }

  Widget _getBotoesArvore() {
    final botoes = Column(children: [
      temUsuarioLogado()
          ? Container(
              margin: const EdgeInsets.all(MARGEM_DEFAULT),
              child: FloatingActionButton(
                  enableFeedback: true,
                  onPressed: () {
                    alertarExecutar(context, "desejar remover a árvore?", () {
                      api.remover(arvoreSelecionada!.id).then((resultado) {
                        _removerDestaque();

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
                    arvoreSelecionada!.comProblema =
                        !arvoreSelecionada!.comProblema;

                    _gravarArvore();
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
                _removerDestaque();
              },
              child: const Icon(Icons.check)))
    ]);

    return botoes;
  }

  Widget _getBotoesCamera() {
    final botoes = Column(children: [
      Container(
          margin: const EdgeInsets.all(MARGEM_DEFAULT),
          child: FloatingActionButton(
              enableFeedback: true,
              onPressed: () =>
                  capturarFoto().then((imagem) => {_adicionarImagem(imagem)}),
              child: const Icon(Icons.check))),
      Container(
          margin: const EdgeInsets.all(MARGEM_DEFAULT),
          child: FloatingActionButton(
              enableFeedback: true,
              backgroundColor: Colors.blue,
              onPressed: () {
                setState(() {
                  estadoCamera = EstadoCamera.desativada;
                });
              },
              child: const Icon(Icons.arrow_back)))
    ]);

    return botoes;
  }

  Widget _getBotoesImagens() {
    final botoes = Column(children: [
      temUsuarioLogado() &&
              (arvoreSelecionada!.imagens.length < MAXIMO_DE_IMAGENS)
          ? Container(
              margin: const EdgeInsets.all(MARGEM_DEFAULT),
              child: FloatingActionButton(
                  enableFeedback: true,
                  onPressed: () {
                    disponibilizarCamera().then((estado) => {
                          if (estado == EstadoCamera.disponivel)
                            setState(() {
                              ativarCamera();
                            })
                        });
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
                    final imgPicker = ImagePicker();
                    imgPicker
                        .pickImage(source: ImageSource.gallery)
                        .then((imagem) {
                      if (imagem != null) {
                        _adicionarImagem(imagem);
                      }
                    });
                  },
                  child: const Icon(Icons.folder)))
          : const SizedBox.shrink(),
      temUsuarioLogado() && arvoreSelecionada!.imagens.isNotEmpty
          ? Container(
              margin: const EdgeInsets.all(MARGEM_DEFAULT),
              child: FloatingActionButton(
                  enableFeedback: true,
                  onPressed: () {
                    alertarExecutar(context, "deseja remover a imagem?", () {
                      _removerImagem();
                    });
                  },
                  child: const Icon(Icons.delete)))
          : const SizedBox.shrink()
    ]);

    return botoes;
  }

  Widget _avisoSelecionarArvorePrimeiro() {
    return Stack(children: [
      SizedBox.expand(
          child: Container(
        color: const Color(0xfffdf69e),
        child: const SizedBox.shrink(),
      )),
      Center(
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
      ]))
    ]);
  }

  Widget _avisoDeErro() {
    return Stack(children: [
      SizedBox.expand(
          child: Container(
        color: const Color(0xfffdf69e),
        child: const SizedBox.shrink(),
      )),
      Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Image(
          image: AssetImage('lib/recursos/icones/icon.png'),
          width: 160,
          height: 160,
        ),
        const Padding(
            padding: EdgeInsets.all(4),
            child: Material(
                color: Colors.transparent,
                child: Text("ocorreu um erro inesperado :(",
                    style: TextStyle(color: Colors.black)))),
        const Padding(
            padding: EdgeInsets.all(4),
            child: Material(
                color: Colors.transparent,
                child: Text("tente novamente mais tarde",
                    style: TextStyle(color: Colors.black)))),
        const Padding(
            padding: EdgeInsets.all(4),
            child: Material(
                color: Colors.transparent,
                child: Text("ou agora pressionando o botão abaixo",
                    style: TextStyle(color: Colors.black)))),
        Padding(
            padding: const EdgeInsets.all(4),
            child: FloatingActionButton(
                enableFeedback: true,
                onPressed: () => _iniciar(),
                child: const Icon(Icons.refresh)))
      ]))
    ]);
  }

  Widget _telaDaOpcaoSelecionada() {
    Widget tela = const SizedBox.shrink();

    bool temArvoreSelecionada = (arvoreSelecionada != null);
    bool arvoreSelecionadaGravada =
        temArvoreSelecionada && arvoreSelecionada!.id != 0;

    if (estado == Estado.visualizandoArvore) {
      tela = Stack(children: [
        SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: imagemSelecionada),
        Container(
            margin: const EdgeInsets.all(MARGEM_DEFAULT),
            alignment: Alignment.topRight,
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
                child: arvoreSelecionadaGravada
                    ? _getBotoesArvore()
                    : _getBotoesMapa())
      ]);
    } else if (_opcaoSelecionada == DETALHES) {
      if (temArvoreSelecionada) {
        tela = detalhes.visualizar(arvoreSelecionada!);
      } else {
        tela = _avisoSelecionarArvorePrimeiro();
      }
    } else if (_opcaoSelecionada == IMAGENS) {
      if (arvoreSelecionadaGravada) {
        tela = Stack(children: [
          estadoCamera == EstadoCamera.ativada
              ? iniciarCapturaDeFoto()
              : imagens.visualizar(arvoreSelecionada!,
                  indiceImagemSelecionada: _indiceImagemSelecionada),
          Container(
              alignment: Alignment.topRight,
              child: estadoCamera == EstadoCamera.ativada
                  ? _getBotoesCamera()
                  : _getBotoesImagens())
        ]);
      } else {
        tela = _avisoSelecionarArvorePrimeiro();
      }
    }

    return tela;
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
    } else if (estado == Estado.comErro) {
      tela = _avisoDeErro();
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
                        logout(() => Fluttertoast.showToast(
                            msg: "você foi desconectado com sucesso!"));
                      } else {
                        login(
                            (usuario) => Fluttertoast.showToast(
                                msg: "seja bem-vindo, ${usuario.nome}"),
                            (erro) => Fluttertoast.showToast(
                                msg: "ocorreu um erro durante o login"));
                      }
                    },
                    child: temUsuarioLogado()
                        ? const Icon(Icons.logout)
                        : const Icon(Icons.login))
              ])),
          body: _telaDaOpcaoSelecionada(),
          bottomNavigationBar: estadoCamera == EstadoCamera.ativada
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
                  onTap: (opcao) => setState(() {
                        opcaoSelecionada = opcao;
                      })));
    }

    return tela;
  }
}
