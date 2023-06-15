// ignore_for_file: unnecessary_getters_setters

class Usuario {
  String _conta = "";
  String get conta => _conta;
  set conta(String value) {
    _conta = value;
  }

  String _nome = "";
  String get nome => _nome;
  set nome(String value) {
    _nome = value;
  }

  Usuario({String conta = "", String nome = ""}) {
    this.conta = conta;
    this.nome = nome;
  }

  static Usuario fromJson(Map<String, dynamic> json) {
    return Usuario(conta: json['conta'], nome: json['nome']);
  }

  Map<String, dynamic> toJson() {
    return {'conta': conta, 'nome': nome};
  }
}
