import 'package:google_sign_in/google_sign_in.dart';

import '../modelo/usuario.dart';

GoogleSignIn loginGoogle = GoogleSignIn(
  scopes: ['email'],
);

Usuario? usuario;

typedef OnLogin = void Function(Usuario usuario);
typedef OnLoginErro = void Function(dynamic erro);
typedef OnLogout = void Function();

void login(OnLogin onLogin, OnLoginErro onLoginErro) {
  loginGoogle.signIn().then((usuarioGoogle) {
    usuario = Usuario(
        conta: usuarioGoogle!.email,
        nome: usuarioGoogle.displayName.toString());
    onLogin(usuario!);
  }).catchError((erro) {
    onLoginErro(erro);
  });
}

void logout(OnLogout onLogout) {
  loginGoogle.disconnect().then((_) {
    usuario = null;

    onLogout();
  });
}

void recuperarUsuarioLogado(OnLogin onLogin) {
  loginGoogle.isSignedIn().then((logado) => {
        if (logado)
          {
            loginGoogle.signInSilently().then((usuarioGoogle) {
              usuario = Usuario(
                  conta: usuarioGoogle!.email,
                  nome: usuarioGoogle.displayName.toString());

              onLogin(usuario!);
            })
          }
      });
}

bool temUsuarioLogado() {
  return usuario != null;
}
