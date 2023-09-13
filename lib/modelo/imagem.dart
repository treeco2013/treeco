// ignore_for_file: unnecessary_getters_setters

class Imagem {
  int _id = 0;
  int get id => _id;
  set id(int value) {
    _id = value;
  }

  String _arquivo = "";
  String get arquivo => _arquivo;
  set arquivo(String value) {
    _arquivo = value;
  }

  Imagem({String arquivo = ""}) {
    this.arquivo = arquivo;
  }

  static Imagem fromJson(Map<String, dynamic> registro) {
    Imagem imagem = Imagem(arquivo: registro["arquivo"]);
    imagem.id = registro["id"];

    return imagem;
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'arquivo': arquivo};
  }
}
