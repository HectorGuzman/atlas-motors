import 'package:flutter/material.dart';

import '../store.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _hide = true;
  String? _error;

  void _submit() {
    final email = _email.text.trim();
    if (!email.contains('@') || _pass.text.length < 4) {
      setState(() => _error = 'Ingresa tu correo y una clave de al menos 4 caracteres.');
      return;
    }
    Store.I.login(email);
  }

  @override
  Widget build(BuildContext context) {
    final field = InputDecoration(
      filled: true,
      fillColor: Colors.white.withValues(alpha: .06),
      labelStyle: const TextStyle(color: Color(0xFFB9C2BB)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: C.gold.withValues(alpha: .3))),
      focusedBorder:
          OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.gold, width: 2)),
    );
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.black, C.green900],
            stops: [0, .42, 1],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Image.asset('assets/logo-wordmark.jpg', height: 120),
                const SizedBox(height: 6),
                Text('INSPECCIONES',
                    textAlign: TextAlign.center,
                    style: display(15, color: C.gold300).copyWith(letterSpacing: 6)),
                const SizedBox(height: 44),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(color: Colors.white),
                  decoration: field.copyWith(
                      labelText: 'Correo', prefixIcon: const Icon(Icons.mail_outline, color: C.gold300)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _pass,
                  obscureText: _hide,
                  onSubmitted: (_) => _submit(),
                  style: const TextStyle(color: Colors.white),
                  decoration: field.copyWith(
                    labelText: 'Clave',
                    prefixIcon: const Icon(Icons.lock_outline, color: C.gold300),
                    suffixIcon: IconButton(
                      icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: const Color(0xFFB9C2BB)),
                      onPressed: () => setState(() => _hide = !_hide),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Color(0xFFFF8A80), fontSize: 13.5)),
                ],
                const SizedBox(height: 26),
                GoldButton('Ingresar', icon: Icons.login, onPressed: _submit),
                const SizedBox(height: 28),
                const Text(
                  'Versión de prueba: todavía no valida la clave\ny los datos se guardan solo en este teléfono.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF8E9A92), fontSize: 12.5, height: 1.5),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
