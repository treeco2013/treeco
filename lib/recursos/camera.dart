// ignore_for_file: unnecessary_getters_setters
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

enum EstadoCamera { disponivel, indisponivel, ativada, desativada }

EstadoCamera estadoCamera = EstadoCamera.indisponivel;

late List<CameraDescription> cameras;
late CameraController controlador;
late Future<void> inicializarControlador;
late int indiceCameraTraseira;

void iniciarCamera() {
  WidgetsFlutterBinding.ensureInitialized();
  availableCameras().then((List<CameraDescription> descricoesCameras) {
    cameras = descricoesCameras;
    encontrarCameraTraseira();
  });
}

void encontrarCameraTraseira() {
  for (int i = 0; i < cameras.length; i++) {
    if (cameras[i].lensDirection == CameraLensDirection.back) {
      indiceCameraTraseira = i;

      break;
    }
  }
}

Future<EstadoCamera> disponibilizarCamera() async {
  EstadoCamera estado = EstadoCamera.indisponivel;

  try {
    if (cameras.isNotEmpty) {
      controlador = CameraController(
          cameras[indiceCameraTraseira], ResolutionPreset.max,
          enableAudio: false);
      inicializarControlador = controlador.initialize();

      estado = EstadoCamera.disponivel;
    }
  } catch (erro) {
    debugPrint('erro inicializando a câmera: $erro');
  }

  return estado;
}

Widget iniciarCapturaDeFoto() {
  return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: FutureBuilder<void>(
          future: inicializarControlador,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return CameraPreview(controlador);
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          }));
}

Future<XFile> capturarFoto() {
  return controlador.takePicture();
}

void ativarCamera() {
  estadoCamera = EstadoCamera.ativada;
}

void desativarCamera() {
  estadoCamera = EstadoCamera.desativada;
}
