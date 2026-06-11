import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/auth_state.dart';
import '../components/atoms/gold_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final TextEditingController _notasController = TextEditingController();

  bool _isFetchingGPS = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _direccionController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  /**
   * Requests location permissions and fetches current GPS coordinates
   */
  Future<void> _fetchGPSLocation() async {
    setState(() {
      _isFetchingGPS = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Los servicios de ubicación están desactivados en su dispositivo.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Permiso de ubicación denegado.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Los permisos de ubicación están denegados permanentemente.';
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latController.text = position.latitude.toString();
        _lngController.text = position.longitude.toString();
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ubicación GPS obtenida con éxito."),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error de GPS: $e"),
          backgroundColor: AppTheme.alertRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingGPS = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registrarse"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Crea tu Cuenta",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Completa el formulario para registrarte como cliente.",
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 25),

                // Name
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: "Nombre Completo *",
                    prefixIcon: Icon(Icons.person, color: AppTheme.primaryGold),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "El nombre es obligatorio.";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                // Phone
                TextFormField(
                  controller: _telefonoController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Teléfono Móvil *",
                    prefixIcon: Icon(Icons.phone, color: AppTheme.primaryGold),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "El teléfono es obligatorio.";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Correo Electrónico *",
                    prefixIcon: Icon(Icons.email, color: AppTheme.primaryGold),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "El correo electrónico es obligatorio.";
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                      return "Ingrese un correo válido.";
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
                    labelText: "Contraseña *",
                    prefixIcon: Icon(Icons.lock, color: AppTheme.primaryGold),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "La contraseña es obligatoria.";
                    }
                    if (value.length < 6) {
                      return "La contraseña debe tener al menos 6 caracteres.";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                const Divider(color: Color(0xFF333333)),
                const SizedBox(height: 10),
                const Text(
                  "Detalles de Entrega (Delivery)",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGold,
                  ),
                ),
                const SizedBox(height: 15),

                // Address
                TextFormField(
                  controller: _direccionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: "Dirección de Residencia",
                    prefixIcon: Icon(Icons.home, color: AppTheme.primaryGold),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 15),

                // Geolocation coordinates fields with GPS Fetch Button
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: "Latitud",
                          prefixIcon: Icon(Icons.location_on, color: AppTheme.primaryGold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _lngController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: "Longitud",
                          prefixIcon: Icon(Icons.location_on, color: AppTheme.primaryGold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // GPS Fetch Button
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _isFetchingGPS ? null : _fetchGPSLocation,
                    icon: _isFetchingGPS
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Icon(Icons.my_location, size: 18),
                    label: Text(_isFetchingGPS ? "Obteniendo GPS..." : "Obtener Ubicación GPS"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      backgroundColor: AppTheme.primaryGold,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Notes
                TextFormField(
                  controller: _notasController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: "Instrucciones de entrega / Referencias",
                    prefixIcon: Icon(Icons.description, color: AppTheme.primaryGold),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 30),

                // Register Action
                Consumer<AuthState>(
                  builder: (context, auth, child) {
                    return GoldButton(
                      label: "Registrarse",
                      isLoading: auth.isLoading,
                      icon: Icons.app_registration,
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final result = await auth.register(
                            nombre: _nombreController.text.trim(),
                            telefono: _telefonoController.text.trim(),
                            email: _emailController.text.trim(),
                            password: _passwordController.text.trim(),
                            direccion: _direccionController.text.trim(),
                            latitud: _latController.text.trim(),
                            longitud: _lngController.text.trim(),
                            notas: _notasController.text.trim(),
                          );

                          if (result['success']) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text("¡Registro exitoso! Por favor, inicie sesión."),
                                backgroundColor: AppTheme.successGreen,
                              ),
                            );
                            Navigator.pop(context); // Go back to LoginPage
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
                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
