import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/auth_state.dart';
import '../core/providers/cart_state.dart';
import '../core/api/api_service.dart';
import '../components/atoms/loader.dart';
import '../components/atoms/gold_button.dart';
import '../components/molecules/dish_card.dart';
import 'order_status_page.dart';
import 'profile_page.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<dynamic> _menuCategories = [];
  bool _isLoadingMenu = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMenuData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  /// Fetch menu catalog from REST API
  Future<void> _loadMenuData() async {
    setState(() {
      _isLoadingMenu = true;
      _errorMessage = null;
    });

    final data = await ApiService.getMenu();
    if (data != null) {
      setState(() {
        _menuCategories = data;
        _tabController = TabController(length: _menuCategories.length, vsync: this);
        _isLoadingMenu = false;
      });
    } else {
      setState(() {
        _errorMessage = "No se pudo cargar el menú. Compruebe la conexión.";
        _isLoadingMenu = false;
      });
    }
  }

  /// Opens checkout delivery cart bottom sheet
  void _openCartBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return _CartBottomSheetContent(scrollController: scrollController);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = Provider.of<AuthState>(context);
    final profileName = authState.profile?['nombre'] ?? 'Cliente';

    return Consumer<CartState>(
      builder: (context, cart, child) {
        return Scaffold(
          appBar: AppBar(
            title: Column(
              children: [
                const Text("Villa Eventos"),
                Text(
                  "Hola, $profileName",
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'Inter',
                    color: AppTheme.primaryGold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            leading: IconButton(
              icon: const Icon(Icons.person_outline, color: AppTheme.primaryGold),
              tooltip: "Mi Perfil",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.receipt_long, color: AppTheme.primaryGold),
                tooltip: "Mis Pedidos",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OrderStatusPage()),
                  );
                },
              ),
            ],
          ),
          
          body: _isLoadingMenu
              ? const Loader(message: "Cargando carta de platos...")
              : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 60, color: AppTheme.alertRed),
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 15),
                            ),
                            const SizedBox(height: 20),
                            GoldButton(
                              label: "Reintentar",
                              width: 150,
                              onPressed: _loadMenuData,
                            ),
                          ],
                        ),
                      ),
                    )
                  : _menuCategories.isEmpty
                      ? const Center(
                          child: Text("No hay categorías ni platos disponibles."),
                        )
                      : Column(
                          children: [
                            Container(
                              color: const Color(0xFF1E1E1E),
                              child: TabBar(
                                controller: _tabController,
                                isScrollable: true,
                                indicatorColor: AppTheme.primaryGold,
                                labelColor: AppTheme.primaryGold,
                                unselectedLabelColor: AppTheme.textMuted,
                                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                                tabs: _menuCategories.map((cat) {
                                  return Tab(text: cat['nombre']);
                                }).toList(),
                              ),
                            ),
                            
                            Expanded(
                              child: TabBarView(
                                controller: _tabController,
                                children: _menuCategories.map((cat) {
                                  final List<dynamic> items = cat['items'] ?? [];
                                  if (items.isEmpty) {
                                    return const Center(child: Text("No hay platos en esta categoría."));
                                  }
                                  
                                  return ListView.builder(
                                    padding: const EdgeInsets.all(15),
                                    itemCount: items.length,
                                    itemBuilder: (context, index) {
                                      final p = items[index];
                                      return DishCard(
                                        id: p['id'],
                                        nombre: p['nombre'],
                                        descripcion: p['descripcion'],
                                        precio: double.tryParse(p['precio']?.toString() ?? '0') ?? 0.00,
                                        imagen: p['imagen'],
                                        disponibles: p['disponibles'],
                                      );
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
          
          floatingActionButton: cart.totalItems > 0
              ? FloatingActionButton.extended(
                  onPressed: () => _openCartBottomSheet(context),
                  backgroundColor: AppTheme.primaryGold,
                  foregroundColor: Colors.black,
                  icon: const Icon(Icons.shopping_cart),
                  label: Text(
                    "Ver Pedido (${cart.totalItems}) • \$${cart.totalPrice.toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _CartBottomSheetContent extends StatefulWidget {
  final ScrollController scrollController;

  const _CartBottomSheetContent({required this.scrollController});

  @override
  State<_CartBottomSheetContent> createState() => _CartBottomSheetContentState();
}

class _CartBottomSheetContentState extends State<_CartBottomSheetContent> {
  final _formKey = GlobalKey<FormState>();
  bool _isLocating = false;

  late TextEditingController _telefonoCtrl;
  late TextEditingController _direccionCtrl;
  late TextEditingController _notaCtrl;

  late TextEditingController _bancoCtrl;
  late TextEditingController _referenciaCtrl;
  late TextEditingController _montoCtrl;

  @override
  void initState() {
    super.initState();
    final cart = Provider.of<CartState>(context, listen: false);
    _telefonoCtrl = TextEditingController(text: cart.telefono);
    _direccionCtrl = TextEditingController(text: cart.direccion);
    _notaCtrl = TextEditingController(text: cart.nota);

    _bancoCtrl = TextEditingController(text: cart.pagoBanco);
    _referenciaCtrl = TextEditingController(text: cart.pagoReferencia);
    _montoCtrl = TextEditingController(text: cart.pagoMonto);
  }

  @override
  void dispose() {
    _telefonoCtrl.dispose();
    _direccionCtrl.dispose();
    _notaCtrl.dispose();
    _bancoCtrl.dispose();
    _referenciaCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  Future<void> _getCurrentGPS() async {
    setState(() {
      _isLocating = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Servicio de ubicación desactivado.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Permiso denegado.';
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (!mounted) return;
      final cart = Provider.of<CartState>(context, listen: false);
      cart.setCoordinates(position.latitude.toString(), position.longitude.toString());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ubicación GPS obtenida. Envío calculado: \$${cart.costoDelivery}"),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error GPS: $e"),
          backgroundColor: AppTheme.alertRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppTheme.primaryGold, width: 2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Consumer<CartState>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_cart_outlined, size: 80, color: AppTheme.textMuted),
                const SizedBox(height: 16),
                const Text(
                  "Su carrito está vacío",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                GoldButton(
                  label: "Volver a la carta",
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            );
          }

          return Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Su Pedido (${cart.totalItems})",
                      style: const TextStyle(
                        fontFamily: 'Cinzel',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFF333333)),
                
                Expanded(
                  child: ListView(
                    controller: widget.scrollController,
                    children: [
                      // items list
                      ...cart.items.map((item) {
                        final noteController = TextEditingController(text: item.nota);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.nombre,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ),
                                    Text(
                                      "\$${(item.precio * item.cantidad).toStringAsFixed(2)}",
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 35,
                                        child: TextField(
                                          controller: noteController,
                                          style: const TextStyle(fontSize: 12),
                                          decoration: const InputDecoration(
                                            hintText: "Nota: sin picante, etc.",
                                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                          ),
                                          onChanged: (text) => cart.setItemNote(item.id, text),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, color: AppTheme.primaryGold, size: 22),
                                          onPressed: () => cart.decrementQuantity(item.id),
                                        ),
                                        Text("${item.cantidad}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryGold, size: 22),
                                          onPressed: () => cart.incrementQuantity(item.id),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 15),
                      const Text(
                        "Método de Entrega",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryGold),
                      ),
                      const SizedBox(height: 8),

                      // Delivery type segment
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => cart.setMetodo('delivery'),
                              icon: const Icon(Icons.delivery_dining),
                              label: const Text("Delivery"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: cart.metodo == 'delivery' ? AppTheme.primaryGold : const Color(0xFF262626),
                                foregroundColor: cart.metodo == 'delivery' ? Colors.black : AppTheme.textLight,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => cart.setMetodo('retirar'),
                              icon: const Icon(Icons.storefront),
                              label: const Text("Retirar local"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: cart.metodo == 'retirar' ? AppTheme.primaryGold : const Color(0xFF262626),
                                foregroundColor: cart.metodo == 'retirar' ? Colors.black : AppTheme.textLight,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      // Geolocation delivery coordinates fields
                      if (cart.metodo == 'delivery') ...[
                        const Text(
                          "Datos del Domicilio",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryGold),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _telefonoCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: "Teléfono de Contacto *"),
                          onChanged: (val) => cart.setTelefono(val),
                          validator: (value) {
                            if (cart.metodo == 'delivery' && (value == null || value.trim().isEmpty)) {
                              return "Ingrese su teléfono.";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _direccionCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(labelText: "Dirección de Entrega *"),
                          onChanged: (val) => cart.setDireccion(val),
                          validator: (value) {
                            if (cart.metodo == 'delivery' && (value == null || value.trim().isEmpty)) {
                              return "Ingrese su dirección.";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                (cart.latitud.isNotEmpty && cart.longitud.isNotEmpty)
                                    ? "GPS: ${cart.latitud.substring(0, 7)}, ${cart.longitud.substring(0, 7)}"
                                    : "Sin ubicación GPS",
                                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _isLocating ? null : _getCurrentGPS,
                              icon: _isLocating
                                  ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                  : const Icon(Icons.gps_fixed, size: 14),
                              label: const Text("GPS", style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                minimumSize: Size.zero,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                      ],

                      const Text(
                        "Información del Pago",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryGold),
                      ),
                      const SizedBox(height: 8),

                      // Dropdown payment method
                      DropdownButtonFormField<String>(
                        initialValue: cart.pagoMetodo,
                        dropdownColor: AppTheme.darkCard,
                        decoration: const InputDecoration(labelText: "Método de Pago"),
                        items: const [
                          DropdownMenuItem(value: "pago_movil", child: Text("Pago Móvil")),
                          DropdownMenuItem(value: "transferencia", child: Text("Transferencia Bancaria")),
                          DropdownMenuItem(value: "efectivo", child: Text("Efectivo en entrega")),
                        ],
                        onChanged: (val) {
                          if (val != null) cart.setPagoMetodo(val);
                        },
                      ),
                      const SizedBox(height: 10),

                      if (cart.pagoMetodo != 'efectivo') ...[
                        TextFormField(
                          controller: _bancoCtrl,
                          decoration: const InputDecoration(labelText: "Banco emisor / origen *"),
                          onChanged: (val) => cart.setPagoBanco(val),
                          validator: (value) {
                            if (cart.pagoMetodo != 'efectivo' && (value == null || value.trim().isEmpty)) {
                              return "Ingrese el banco.";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _referenciaCtrl,
                          decoration: const InputDecoration(labelText: "Referencia de pago / Captura *"),
                          onChanged: (val) => cart.setPagoReferencia(val),
                          validator: (value) {
                            if (cart.pagoMetodo != 'efectivo' && (value == null || value.trim().isEmpty)) {
                              return "Ingrese la referencia de transacción.";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _montoCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Monto pagado (\$)",
                            hintText: cart.totalPrice.toStringAsFixed(2),
                          ),
                          onChanged: (val) => cart.setPagoMonto(val),
                        ),
                        const SizedBox(height: 15),
                      ],

                      const Text(
                        "Comentario General:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _notaCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: "Instrucciones de entrega, comentarios, etc.",
                          contentPadding: EdgeInsets.all(12),
                        ),
                        onChanged: (val) => cart.setNota(val),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                
                const Divider(color: Color(0xFF333333)),
                
                // Summary price breakdown
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Subtotal platos:", style: TextStyle(color: AppTheme.textMuted)),
                          Text("\$${cart.totalComida.toStringAsFixed(2)}"),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Costo Envío:", style: TextStyle(color: AppTheme.textMuted)),
                          Text(cart.metodo == 'retirar' ? "Gratis" : "\$${cart.costoDelivery.toStringAsFixed(2)}"),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total General:",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "\$${cart.totalPrice.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 10),
                
                GoldButton(
                  label: "Confirmar y Enviar Pedido",
                  icon: Icons.send,
                  isLoading: cart.isLoading,
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final result = await cart.submitOrder();
                      if (!context.mounted) return;
                      Navigator.pop(context); // close sheet
                      
                      if (result['success']) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("¡Pedido #${result['id_pedido']} recibido con éxito! En verificación."),
                            backgroundColor: AppTheme.successGreen,
                          ),
                        );
                        
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const OrderStatusPage()),
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
