import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/auth_state.dart';
import '../core/providers/cart_state.dart';
import '../core/api/api_service.dart';
import '../components/atoms/gold_button.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSettingsDialog() async {
    final currentUrl = await ApiService.getBaseUrl();
    if (!mounted) return;
    final customUrlController = TextEditingController(text: currentUrl);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.darkCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: AppTheme.primaryGold, width: 1.5),
          ),
          title: const Text(
            "Configurar Servidor API",
            style: TextStyle(color: Colors.white, fontFamily: 'Cinzel', fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Selecciona una opción o escribe una URL personalizada:",
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.darkBackground,
                    foregroundColor: Colors.white,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.grey, width: 0.5),
                    ),
                  ),
                  onPressed: () async {
                    await ApiService.setBaseUrl("https://www.villaeventos.com/api/index.php");
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Servidor configurado a Producción (villaeventos.com)"),
                        backgroundColor: AppTheme.successGreen,
                      ),
                    );
                  },
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Producción (Defecto)", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
                      SizedBox(height: 2),
                      Text("https://www.villaeventos.com/api/index.php", style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.darkBackground,
                    foregroundColor: Colors.white,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.grey, width: 0.5),
                    ),
                  ),
                  onPressed: () async {
                    await ApiService.setBaseUrl("http://10.0.2.2:8081/villaeventos_master/api/index.php");
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Servidor configurado a Emulador Local (10.0.2.2)"),
                        backgroundColor: AppTheme.successGreen,
                      ),
                    );
                  },
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Local (Emulador Android)", style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text("http://10.0.2.2:8081/villaeventos_master/api/index.php", style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.darkBackground,
                    foregroundColor: Colors.white,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.grey, width: 0.5),
                    ),
                  ),
                  onPressed: () async {
                    await ApiService.setBaseUrl("http://localhost:8081/villaeventos_master/api/index.php");
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Servidor configurado a Localhost (PC)"),
                        backgroundColor: AppTheme.successGreen,
                      ),
                    );
                  },
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Local (localhost)", style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text("http://localhost:8081/villaeventos_master/api/index.php", style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "URL Personalizada:",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: customUrlController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "http://tu-ip:puerto/.../index.php",
                    hintStyle: const TextStyle(color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.primaryGold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar", style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                final input = customUrlController.text.trim();
                if (input.isNotEmpty) {
                  await ApiService.setBaseUrl(input);
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Servidor cambiado a: $input"),
                      backgroundColor: AppTheme.successGreen,
                    ),
                  );
                }
              },
              child: const Text("Guardar", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        width: 110,
                        height: 110,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.darkCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.primaryGold, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGold.withOpacity(0.15),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.restaurant,
                              color: AppTheme.primaryGold,
                              size: 55,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Brand name
                      const Text(
                        "Villa Eventos",
                        style: TextStyle(
                          fontFamily: 'Cinzel',
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const Text(
                        "DELIVERY & DOMICILIOS",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGold,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 35),

                      // Login title
                      const Text(
                        "Iniciar Sesión",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Ingresa tus credenciales para ordenar tu comida favorita.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Email
                      TextFormField(
                        controller: _emailController,
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
                      const SizedBox(height: 15),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Contraseña",
                          prefixIcon: Icon(Icons.lock, color: AppTheme.primaryGold),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Por favor ingresa tu contraseña.";
                          }
                          if (value.length < 6) {
                            return "La contraseña debe tener al menos 6 caracteres.";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 25),

                      // Submit button
                      Consumer<AuthState>(
                        builder: (context, auth, child) {
                          return GoldButton(
                            label: "Ingresar",
                            isLoading: auth.isLoading,
                            icon: Icons.login,
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                final email = _emailController.text.trim();
                                final pass = _passwordController.text.trim();
                                final result = await auth.login(email, pass);

                                if (result['success']) {
                                  // Sync client saved delivery coordinates with the CartState provider
                                  Provider.of<CartState>(context, listen: false).setClientDetails(result['data']);
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("¡Bienvenido, ${result['data']['nombre']}!"),
                                      backgroundColor: AppTheme.successGreen,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(result['message']),
                                      backgroundColor: AppTheme.alertRed,
                                    ),
                                  );
                                }
                              }
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Navigation to Register
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "¿No tienes cuenta?",
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const RegisterPage()),
                              );
                            },
                            child: const Text("Regístrate aquí"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 15,
              right: 15,
              child: IconButton(
                icon: const Icon(Icons.settings, color: AppTheme.primaryGold, size: 28),
                onPressed: _showSettingsDialog,
                tooltip: "Configurar Servidor API",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
