class DemoLoginService {
  static const demoEmail = 'admin@megascreen.com.my';
  static const demoCode = '888888';

  bool isSupportedEmail(String email) =>
      email.trim().toLowerCase() == demoEmail;

  bool isValidCode(String code) => code == demoCode;
}
