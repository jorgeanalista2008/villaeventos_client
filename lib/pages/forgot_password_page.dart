import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../core/api/api_service.dart';
import '../components/atoms/gold_button.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  int _currentStep = 1; // 1: Request, 2: Verify, 3: Reset
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final result = await ApiService.solicitarCodigoRecuperacion(_emailCtrl.text.trim());
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: AppTheme.successGreen,
        ),
      );
      setState(() {
        _currentStep = 2;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: AppTheme.alertRed,
        ),
      );
    }
  }

  Future<void> _submitVerify() async {
    if (_codeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor ingrese el código de 6 dígitos."),
          backgroundColor: AppTheme.alertRed,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await ApiService.verificarCodigoRecuperacion(
      _emailCtrl.text.trim(),
      _codeCtrl.text.trim(),
    );
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: AppTheme.successGreen,
        ),
      );
      setState(() {
        _currentStep = 3;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: AppTheme.alertRed,
        ),
      );
    }
  }

  Future<void> _submitReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final result = await ApiService.restablecerContrasena(
      _emailCtrl.text.trim(),
      _codeCtrl.text.trim(),
      _passwordCtrl.text.trim(),
    );
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: AppTheme.successGreen,
        ),
      );
      Navigator.pop(context); // Return to LoginPage
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: AppTheme.alertRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recuperar Cuenta"),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Step indicator icon
                  Icon(
                    _currentStep == 1
                        ? Icons.mail_outline
                        : _currentStep == 2
                            ? Icons.pin_outlined
                            : Icons.lock_reset_outlined,
                    size: 80,
                    color: AppTheme.primaryGold,
                  ),
                  const SizedBox(height: 25),

                  // Cinzel title
                  Center(
                    child: Text(
                      "Paso $_currentStep de 3",
                      style: GoogleFonts.cinzel(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle descriptive text
                  Text(
                    _currentStep == 1
                        ? "Ingresa tu correo electrónico registrado para enviarte un código de recuperación."
                        : _currentStep == 2
                            ? "Ingresa el código de 6 dígitos que enviamos a tu correo electrónico."
                            : "Establece tu nueva contraseña de acceso para ingresar a la plataforma.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
                  ),
                  const SizedBox(height: 35),

                  // STEP CONDITIONAL UI
                  if (_currentStep == 1) ...[
                    // Step 1: Email Form
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "Correo Electrónico",
                        prefixIcon: Icon(Icons.email, color: AppTheme.primaryGold),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Por favor ingresa tu correo.";
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                          return "Ingresa un correo electrónico válido.";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    GoldButton(
                      label: "Enviar Código",
                      icon: Icons.send_rounded,
                      isLoading: _isLoading,
                      onPressed: _submitRequest,
                    ),
                  ] else if (_currentStep == 2) ...[
                    // Step 2: Verification Code Input
                    TextFormField(
                      controller: _codeCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.shareTechMono(
                        fontSize: 24,
                        letterSpacing: 8,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGold,
                      ),
                      decoration: const InputDecoration(
                        labelText: "Código de 6 dígitos",
                        prefixIcon: Icon(Icons.password, color: AppTheme.primaryGold),
                        counterText: "",
                      ),
                    ),
                    const SizedBox(height: 30),
                    GoldButton(
                      label: "Verificar Código",
                      icon: Icons.verified_user_outlined,
                      isLoading: _isLoading,
                      onPressed: _submitVerify,
                    ),
                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _currentStep = 1;
                        });
                      },
                      child: const Text("Volver a ingresar correo"),
                    ),
                  ] else ...[
                    // Step 3: Password Restructuring
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Nueva Contraseña",
                        prefixIcon: Icon(Icons.lock_outline, color: AppTheme.primaryGold),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Por favor ingresa tu nueva contraseña.";
                        }
                        if (value.length < 6) {
                          return "La contraseña debe tener al menos 6 caracteres.";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _confirmPasswordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Confirmar Contraseña",
                        prefixIcon: Icon(Icons.lock_outline, color: AppTheme.primaryGold),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Por favor confirma la contraseña.";
                        }
                        if (value != _passwordCtrl.text) {
                          return "Las contraseñas no coinciden.";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    GoldButton(
                      label: "Restablecer Contraseña",
                      icon: Icons.save_alt_rounded,
                      isLoading: _isLoading,
                      onPressed: _submitReset,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
