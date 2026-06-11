import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/api/api_service.dart';
import '../components/atoms/loader.dart';
import '../components/atoms/gold_button.dart';

class OrderStatusPage extends StatefulWidget {
  const OrderStatusPage({super.key});

  @override
  State<OrderStatusPage> createState() => _OrderStatusPageState();
}

class _OrderStatusPageState extends State<OrderStatusPage> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  /**
   * Fetch customer order history
   */
  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final data = await ApiService.getClientOrders();
    if (data != null) {
      setState(() {
        _orders = data;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = "No se pudieron obtener sus pedidos.";
        _isLoading = false;
      });
    }
  }

  Color _getItemStatusColor(int status) {
    switch (status) {
      case 0: return AppTheme.alertRed;
      case 2: return AppTheme.infoBlue;
      case 3: return AppTheme.successGreen;
      case 4: return AppTheme.textMuted;
      default: return AppTheme.primaryGold;
    }
  }

  Color _getOrderStatusColor(int status) {
    switch (status) {
      case 0: return AppTheme.alertRed;
      case 4: return AppTheme.infoBlue; // Verificando pago
      case 1: return AppTheme.primaryGold; // Confirmado
      case 2: return AppTheme.primaryGold; // En preparación
      case 3: return AppTheme.successGreen; // Entregado
      default: return AppTheme.primaryGold;
    }
  }

  String _getOrderStatusText(int status, String defaultText) {
    switch (status) {
      case 0: return "Cancelado";
      case 4: return "Verificando Pago";
      case 1: return "Confirmado";
      case 2: return "En Preparación";
      case 3: return "Entregado";
      default: return defaultText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Pedidos"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryGold),
            onPressed: _fetchOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Loader(message: "Consultando estado de pedidos...")
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: AppTheme.alertRed),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        GoldButton(
                          label: "Reintentar",
                          width: 150,
                          onPressed: _fetchOrders,
                        ),
                      ],
                    ),
                  ),
                )
              : _orders.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(30),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.restaurant_menu,
                              size: 80,
                              color: AppTheme.textMuted,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "No tiene pedidos registrados",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Cuando realice pedidos a domicilio, aparecerán aquí para que pueda seguir su entrega.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                            ),
                            const SizedBox(height: 25),
                            GoldButton(
                              label: "Volver a la carta",
                              width: 200,
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchOrders,
                      color: AppTheme.primaryGold,
                      backgroundColor: AppTheme.darkCard,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(15),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final o = _orders[index];
                          final int orderStatus = o['estatus'] ?? 1;
                          final String rawStatusText = o['estatus_texto'] ?? "Abierto";
                          final String orderStatusText = _getOrderStatusText(orderStatus, rawStatusText);
                          final List<dynamic> items = o['items'] ?? [];
                          final double costoDelivery = double.tryParse(o['costo_delivery']?.toString() ?? '0') ?? 0.00;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                initiallyExpanded: index == 0,
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Pedido #${o['id']}",
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getOrderStatusColor(orderStatus).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: _getOrderStatusColor(orderStatus)),
                                      ),
                                      child: Text(
                                        orderStatusText,
                                        style: TextStyle(
                                          color: _getOrderStatusColor(orderStatus),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Fecha: ${o['fecha']}",
                                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                      ),
                                      Text(
                                        "Total: \$${o['total']}",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryGold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                children: [
                                  const Divider(color: Color(0xFF333333), height: 1),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (o['nota'] != null && o['nota'].toString().isNotEmpty) ...[
                                          Text(
                                            "Detalles de Pago y Entrega:\n${o['nota']}",
                                            style: const TextStyle(
                                              fontSize: 12,
                                              height: 1.4,
                                              color: AppTheme.textLight,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                        ],
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              "Costo de Delivery:",
                                              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                            ),
                                            Text(
                                              costoDelivery > 0 ? "\$${costoDelivery.toStringAsFixed(2)}" : "Gratis / Retiro",
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          "Artículos:",
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        
                                        ...items.map((item) {
                                          final int itemStatus = item['estatus'] ?? 1;
                                          final String itemStatusText = item['estatus_texto'] ?? "Pendiente";

                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 6),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        "${item['nombre_plato']} (x${item['cantidad']})",
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                      if (item['nota'] != null && item['nota'].toString().isNotEmpty)
                                                        Text(
                                                          "Nota: ${item['nota']}",
                                                          style: const TextStyle(
                                                            fontSize: 11,
                                                            color: AppTheme.alertRed,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: _getItemStatusColor(itemStatus).withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        itemStatus == 3
                                                            ? Icons.check_circle_outline
                                                            : itemStatus == 2
                                                                ? Icons.timer_outlined
                                                                : itemStatus == 4
                                                                    ? Icons.done_all
                                                                    : Icons.pending_actions_outlined,
                                                        size: 13,
                                                        color: _getItemStatusColor(itemStatus),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        itemStatusText,
                                                        style: TextStyle(
                                                          color: _getItemStatusColor(itemStatus),
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
