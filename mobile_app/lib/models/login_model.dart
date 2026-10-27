enum LoginStep { email, verify, signedIn }

class LoginModel {
  const LoginModel({this.step = LoginStep.email, this.email = ''});

  final LoginStep step;
  final String email;

  LoginModel copyWith({LoginStep? step, String? email}) =>
      LoginModel(step: step ?? this.step, email: email ?? this.email);
}
