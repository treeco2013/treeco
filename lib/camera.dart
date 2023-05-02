// ignore_for_file: unnecessary_getters_setters
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

enum EstadoCamera { disponivel, indisponivel, ativada, desativada }

class Camera {
  EstadoCamera _estadoCamera = EstadoCamera.indisponivel;
  EstadoCamera get estadoCamera => _estadoCamera;
  set estadoCamera(EstadoCamera value) {
    _estadoCamera = value;
  }

  late List<CameraDescription> _cameras;
  late CameraController _controlador;
  late Future<void> _inicializarControlador;
  late int indiceCameraTraseira;

  Camera() {
    WidgetsFlutterBinding.ensureInitialized();
    availableCameras().then((List<CameraDescription> descricoesCameras) {
      _cameras = descricoesCameras;
      encontrarCameraTraseira();
    });
  }

  void encontrarCameraTraseira() {
    for (int i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == CameraLensDirection.back) {
        indiceCameraTraseira = i;

        break;
      }
    }
  }

  Future<EstadoCamera> iniciar() async {
    EstadoCamera estado = EstadoCamera.indisponivel;

    try {
      if (_cameras.isNotEmpty) {
        _controlador = CameraController(
            _cameras[indiceCameraTraseira], ResolutionPreset.max,
            enableAudio: false);
        _inicializarControlador = _controlador.initialize();

        estado = EstadoCamera.disponivel;
      }
    } catch (e) {
      debugPrint('error initializing the camera: $e');
    }

    return estado;
  }

  Widget iniciarCapturaDeFoto() {
    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: FutureBuilder<void>(
            future: _inicializarControlador,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return CameraPreview(_controlador);
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            }));
  }

  void selecionarCameraTraseira() {
    //
  }

  void selecionarCameraDeSelfie() {
    //
  }

  Future<XFile> capturar() {
    return _controlador.takePicture();
  }

  void ativarCamera() {
    estadoCamera = EstadoCamera.ativada;
  }
}
