import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/login_controller.dart';
import '../../models/login_model.dart';
import '../../services/demo_login_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LoginController _loginController = Get.find<LoginController>();
  final _emailForm = GlobalKey<FormState>();
  final _codeForm = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!(_emailForm.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    _code.clear();
    await _loginController.sendOtp(_email.text);
  }

  void _verifyOtp() {
    if (!(_codeForm.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    _loginController.verifyOtp(_code.text);
    TextInput.finishAutofillContext();
  }

  void _handleOtpChanged(String value) {
    if (value.length != 6 || !(_codeForm.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();
    _loginController.verifyOtp(value);
    TextInput.finishAutofillContext();
  }

  void _resendOtp() {
    _code.clear();
    _codeForm.currentState?.reset();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Demo code: 888888. No email is sent.')),
    );
  }

  void _backToEmail({bool signOut = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    _loginController.backToEmail();
    _code.clear();
    if (signOut) _email.clear();
  }

  @override
  Widget build(BuildContext context) => Obx(() {
    if (!_loginController.startupPermissionsGranted.value) {
      if (!_loginController.startupPermissionsChecked.value ||
          _loginController.isLoading.value) {
        return _buildLoadingScreen();
      }
      return _buildPermissionGate();
    }
    return _buildLoginPage();
  });

  Widget _buildLoginPage() => Scaffold(
    body: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight > 48
                    ? constraints.maxHeight - 48
                    : 0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...switch (_loginController.login.value.step) {
                        LoginStep.email => _emailFields(),
                        LoginStep.verify => _verificationFields(),
                        LoginStep.signedIn => const [],
                      },
                      const SizedBox(height: 24),
                      if (_loginController.errorMessage.value != null)
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _loginController.errorMessage.value!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      if (_loginController.showSettings.value)
                        TextButton(
                          onPressed: _loginController.isLoading.value
                              ? null
                              : _loginController.openSettings,
                          child: const Text('Open settings'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildLoadingScreen() => Scaffold(
    body: SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/working.png',
              height: 150,
              semanticLabel: 'IDS logo',
            ),
            const SizedBox(height: 28),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    ),
  );

  Widget _buildPermissionGate() => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(
                  'assets/images/ids_logo.jpg',
                  height: 150,
                  semanticLabel: 'IDS logo',
                ),
                const SizedBox(height: 24),
                Text(
                  'Allow access to continue',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                const Text(
                  'IDS needs camera access for docket photos and location '
                  'access for service visits. Location is used while the app '
                  'is open.',
                  textAlign: TextAlign.center,
                ),
                if (_loginController.isLoading.value) ...[
                  const SizedBox(height: 24),
                  const Center(child: CircularProgressIndicator()),
                ],
                if (_loginController.errorMessage.value != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _loginController.errorMessage.value!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (_loginController.startupPermissionsChecked.value &&
                    !_loginController.isLoading.value) ...[
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loginController.requestStartupPermissions,
                    child: const Text('Try again'),
                  ),
                  if (_loginController.showSettings.value)
                    TextButton(
                      onPressed: _loginController.openSettings,
                      child: const Text('Open settings'),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );

  List<Widget> _emailFields() => [
    Image.asset(
      'assets/images/ids_logo.jpg',
      height: 150,
      semanticLabel: 'IDS logo',
    ),
    const SizedBox(height: 16),
    const Text('Sign in with your email.'),
    const SizedBox(height: 24),
    AutofillGroup(
      child: Form(
        key: _emailForm,
        child: TextFormField(
          controller: _email,
          enabled: !_loginController.isLoading.value,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.send,
          autofillHints: const [AutofillHints.email],
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: DemoLoginService.demoEmail,
            helperText: 'Use an email registered by your admin.',
            helperMaxLines: 2,
            errorMaxLines: 2,
          ),
          validator: (value) {
            final email = value?.trim().toLowerCase() ?? '';
            if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
              return 'Enter a valid email address.';
            }
            return null;
          },
          onFieldSubmitted: (_) => _sendOtp(),
        ),
      ),
    ),
    const SizedBox(height: 16),
    FilledButton(
      onPressed: _loginController.isLoading.value ? null : _sendOtp,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: _loginController.isLoading.value
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Send OTP'),
      ),
    ),
  ];

  List<Widget> _verificationFields() => [
    Text('Verify your email', style: Theme.of(context).textTheme.headlineSmall),
    const SizedBox(height: 8),
    Text(
      'Enter the verification code for ${_loginController.login.value.email}.',
    ),
    const SizedBox(height: 16),
    const Text('Demo code: 888888. No email is sent.'),
    const SizedBox(height: 16),
    Form(
      key: _codeForm,
      child: TextFormField(
        controller: _code,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.oneTimeCode],
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        decoration: const InputDecoration(
          labelText: 'Verification code',
          errorMaxLines: 2,
        ),
        validator: (value) {
          if (value == null || value.length != 6) {
            return 'Enter the 6-digit code.';
          }
          if (!_loginController.isValidCode(value)) {
            return 'Incorrect code. Use 888888 for this demo.';
          }
          return null;
        },
        onChanged: _handleOtpChanged,
        onFieldSubmitted: (_) => _verifyOtp(),
      ),
    ),
    TextButton(onPressed: _resendOtp, child: const Text('Resend OTP')),
    TextButton(onPressed: _backToEmail, child: const Text('Change email')),
  ];
}
