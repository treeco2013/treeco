// ignore_for_file: depend_on_referenced_packages, avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../constantes.dart';

const camadaDeVisualizacao =
    "https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png";
const chaveDaAPI = "b3f77681-91fd-412a-bbd5-dd4f2f6dd565";

enum EstadoPosicionamento {
  indeterminado,
  desabilitado,
  permitido,
  naoPermitido,
  atualizado
}

class Mapa {
  Position? _posicao;
  Position get posicao => _posicao!;
  set posicao(Position value) {
    _posicao = value;
  }

  late double _zoom;
  set zoom(double value) {
    _zoom = value;
  }

  late double _tamanhoMarcador;
  set tamanhoMarcador(double value) {
    _tamanhoMarcador = value;
  }

  List<Marker>? _marcadores;
  set marcadores(List<Marker> value) {
    _marcadores = value;
  }

  late MapController _controlador;
  MapController get controlador => _controlador;

  Mapa(
      {double zoom = 14, double tamanhoMarcador = TAMANHO_MARCADOR_DE_ARVORE}) {
    this.zoom = zoom;
    this.tamanhoMarcador = tamanhoMarcador;

    _controlador = MapController();
  }

  Widget _getMarcadorPosicao() {
    return const Icon(Icons.person_pin, color: Colors.amber, size: 38);
  }

  Future<EstadoPosicionamento> _posicionamentoHabilitado() async {
    EstadoPosicionamento estado = EstadoPosicionamento.indeterminado;

    bool localizacaoHabilitada = await Geolocator.isLocationServiceEnabled();
    if (!localizacaoHabilitada) {
      estado = EstadoPosicionamento.desabilitado;
    } else {
      LocationPermission permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
        if ([LocationPermission.denied, LocationPermission.deniedForever]
            .contains(permissao)) {
          estado = EstadoPosicionamento.naoPermitido;
        } else {
          estado = EstadoPosicionamento.permitido;
        }
      } else {
        estado = EstadoPosicionamento.permitido;
      }
    }

    return estado;
  }

  Future<EstadoPosicionamento> atualizarPosicao() async {
    EstadoPosicionamento estado = await _posicionamentoHabilitado();

    if (estado == EstadoPosicionamento.permitido) {
      posicao = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      estado = EstadoPosicionamento.atualizado;
    }

    return estado;
  }

  void centralizar() {
    controlador.move(LatLng(_posicao!.latitude, _posicao!.longitude), _zoom);
  }

  List<Marker> _getMarcadores() {
    final List<Marker> marcadores = [];

    if (_posicao != null) {
      marcadores.add(Marker(
          point: LatLng(_posicao!.latitude, _posicao!.longitude),
          width: _tamanhoMarcador,
          height: _tamanhoMarcador,
          builder: (context) => _getMarcadorPosicao()));
    }
    if (_marcadores != null) {
      marcadores.addAll(_marcadores!);
    }

    return marcadores;
  }

  Widget visualizar(bool mostrarMarcadores) {
    late Widget widget;

    if (_posicao == null) {
      widget = const SizedBox.shrink();
    } else {
      final latlang = LatLng(_posicao!.latitude, _posicao!.longitude);

      widget = FlutterMap(
          mapController: controlador,
          options: MapOptions(center: latlang, zoom: _zoom, keepAlive: true),
          children: [
            TileLayer(
                urlTemplate: "$camadaDeVisualizacao?api_key={api_key}",
                additionalOptions: const {"api_key": chaveDaAPI},
                maxZoom: 20,
                maxNativeZoom: 20),
            mostrarMarcadores
                ? MarkerLayer(markers: _getMarcadores())
                : const SizedBox.shrink()
          ]);
    }

    return widget;
  }
}
