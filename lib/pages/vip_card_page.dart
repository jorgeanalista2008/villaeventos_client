import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/auth_state.dart';
import '../core/api/api_service.dart';
import '../components/atoms/gold_button.dart';
import '../components/atoms/loader.dart';

class VipCardPage extends StatefulWidget {
  const VipCardPage({super.key});

  @override
  State<VipCardPage> createState() => _VipCardPageState();
}

class _VipCardPageState extends State<VipCardPage> {
  bool _isLoadingHistory = false;
  List<dynamic> _movements = [];
  String? _errorMessage;

  static const Map<String, String> _bancosVenezuela = {
    "Banco de Venezuela": "Banco de Venezuela (BDV)",
    "Banesco": "Banesco",
    "Banco Mercantil": "Banco Mercantil",
    "BBVA Provincial": "BBVA Provincial",
    "Bancamiga": "Bancamiga",
    "Banco Nacional de Crédito": "Banco Nacional de Crédito (BNC)",
    "Banco Bicentenario": "Banco Bicentenario",
    "Banplus": "Banplus",
    "Banco del Tesoro": "Banco del Tesoro",
    "Banco Exterior": "Banco Exterior",
    "Banco Fondo Común": "Banco Fondo Común (BFC)",
    "Banco Caroní": "Banco Caroní",
    "Banco Plaza": "Banco Plaza",
    "100% Banco": "100% Banco",
    "Banco Venezolano de Crédito": "Banco Venezolano de Crédito",
    "Banco Activo": "Banco Activo",
    "Del Sur Banco Universal": "Del Sur Banco Universal",
    "Mi Banco": "Mi Banco",
    "Bancrecer": "Bancrecer",
    "Otro / Zelle / Internacional": "Otro / Zelle / Internacional",
  };

  @override
  void initState() {
    super.initState();
    final authState = Provider.of<AuthState>(context, listen: false);
    final hasVip = authState.profile?['tarjeta_vip'] != null;
    if (hasVip) {
      _loadMovements();
    }
  }

  Future<void> _loadMovements() async {
    setState(() {
      _isLoadingHistory = true;
      _errorMessage = null;
    });

    final data = await ApiService.getMovimientosVip();
    if (!mounted) return;

    if (data != null) {
      setState(() {
        _movements = data;
        _isLoadingHistory = false;
      });
    } else {
      setState(() {
        _errorMessage = "No se pudieron obtener los movimientos de su tarjeta.";
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _refreshProfile() async {
    final auth = Provider.of<AuthState>(context, listen: false);
    await auth.checkSession();
  }

  /// Opens dialog to submit VIP application or Balance Recharge
  void _openPaymentDialog({required bool isRecharge}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _PaymentReportDialog(
          isRecharge: isRecharge,
          bancosVenezuela: _bancosVenezuela,
          onSuccess: () async {
            await _refreshProfile();
            if (!context.mounted) return;
            final hasVip = Provider.of<AuthState>(context, listen: false).profile?['tarjeta_vip'] != null;
            if (hasVip) {
              _loadMovements();
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = Provider.of<AuthState>(context);
    final profile = authState.profile ?? {};
    final vipCard = profile['tarjeta_vip'];
    final bool hasPending = profile['tiene_vip_pendiente'] == true;
    final bool hasVip = vipCard != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tarjeta VIP"),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryGold,
          backgroundColor: AppTheme.darkCard,
          onRefresh: () async {
            await _refreshProfile();
            if (vipCard != null) {
              await _loadMovements();
            }
          },
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              // 1. STUNNING VIRTUAL GOLDEN VIP CARD
              _buildVirtualCard(
                vipCard: vipCard,
                hasPending: hasPending,
                hasVip: hasVip,
                clientName: profile['nombre'] ?? 'Cliente VIP',
              ),
              const SizedBox(height: 25),

              // 2. VIP CONDITIONAL ACTIONS
              if (!hasVip && !hasPending) ...[
                // User has no card and no pending request
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Únete al Club de Fidelidad VIP",
                          style: GoogleFonts.cinzel(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Obtén tu tarjeta VIP por solo \$15.00 de saldo inicial y disfruta de recargas directas, promociones exclusivas y pagos simplificados en todas tus compras.",
                          style: TextStyle(fontSize: 13, height: 1.4, color: AppTheme.textLight),
                        ),
                        const SizedBox(height: 20),
                        GoldButton(
                          label: "Solicitar Tarjeta VIP",
                          icon: Icons.card_membership,
                          onPressed: () => _openPaymentDialog(isRecharge: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (hasPending && !hasVip) ...[
                // User requested a card and is pending verification
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.hourglass_empty, color: AppTheme.primaryGold),
                            const SizedBox(width: 8),
                            Text(
                              "Solicitud en Verificación",
                              style: GoogleFonts.cinzel(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Hemos recibido su reporte de pago para la afiliación de la Tarjeta VIP. Actualmente se encuentra en proceso de conciliación por parte del equipo administrativo.",
                          style: TextStyle(fontSize: 13, height: 1.4, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Una vez aprobado, su saldo y tarjeta digital se activarán de inmediato en esta pantalla.",
                          style: TextStyle(fontSize: 13, height: 1.4, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // User has an active card
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => _openPaymentDialog(isRecharge: true),
                        icon: const Icon(Icons.add_card, color: Colors.black),
                        label: const Text("Recargar Saldo", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // 3. TRANSACTIONS/MOVEMENTS HISTORY
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Historial de Movimientos",
                      style: GoogleFonts.cinzel(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20, color: AppTheme.primaryGold),
                      onPressed: _loadMovements,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                _isLoadingHistory
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: Center(child: Loader(message: "Cargando movimientos...")),
                      )
                    : _errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 30.0),
                              child: Column(
                                children: [
                                  Text(_errorMessage!, style: const TextStyle(color: AppTheme.alertRed)),
                                  const SizedBox(height: 10),
                                  TextButton(onPressed: _loadMovements, child: const Text("Reintentar")),
                                ],
                              ),
                            ),
                          )
                        : _movements.isEmpty
                            ? Card(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 35.0, horizontal: 15.0),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(Icons.receipt_long_outlined, size: 50, color: Colors.grey.shade700),
                                        const SizedBox(height: 10),
                                        const Text(
                                          "No hay transacciones registradas aún.",
                                          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : Column(
                                children: _movements.map((move) {
                                  final double amount = double.tryParse(move['monto']?.toString() ?? '0') ?? 0.00;
                                  final String type = move['tipo'] ?? 'registro';
                                  final isAdd = type == 'recarga' || type == 'registro';

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: isAdd
                                            ? AppTheme.successGreen.withValues(alpha: 0.15)
                                            : AppTheme.alertRed.withValues(alpha: 0.15),
                                        child: Icon(
                                          isAdd ? Icons.arrow_downward : Icons.arrow_upward,
                                          color: isAdd ? AppTheme.successGreen : AppTheme.alertRed,
                                          size: 18,
                                        ),
                                      ),
                                      title: Text(
                                        move['descripcion'] ?? 'Transacción VIP',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          move['fecha'] ?? '',
                                          style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                        ),
                                      ),
                                      trailing: Text(
                                        "${isAdd ? '+' : '-'}\$${amount.toStringAsFixed(2)}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isAdd ? AppTheme.successGreen : AppTheme.alertRed,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the 3D-effect looking golden virtual membership card
  Widget _buildVirtualCard({
    required dynamic vipCard,
    required bool hasPending,
    required bool hasVip,
    required String clientName,
  }) {
    final String cardCode = hasVip ? (vipCard['codigo'] ?? '----') : (hasPending ? "CONCILIANDO PAGO" : "SIN AFILIACIÓN");
    final double cardBalance = hasVip ? (double.tryParse(vipCard['saldo']?.toString() ?? '0') ?? 0.00) : 0.00;

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AC0D).withValues(alpha: 0.25),
            blurRadius: 25,
            spreadRadius: 2,
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1C1A17), // Charcoal gold
            Color(0xFF2C271E),
            Color(0xFF9A7D0A), // Rich Gold
            Color(0xFFD4AC0D), // Bright Gold
            Color(0xFF2C271E),
          ],
          stops: [0.0, 0.2, 0.7, 0.9, 1.0],
        ),
      ),
      padding: const EdgeInsets.all(22.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header: Brand and NFC Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "VILLA EVENTOS VIP",
                style: GoogleFonts.cinzel(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
              const Icon(Icons.wifi, color: Colors.white70, size: 22),
            ],
          ),

          // Chip & Balance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Virtual Chip Graphic
              Container(
                width: 42,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5C158),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.black45, width: 0.5),
                ),
                child: GridView.count(
                  crossAxisCount: 3,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(2),
                  children: List.generate(
                    6,
                    (index) => Container(
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black26, width: 0.3),
                      ),
                    ),
                  ),
                ),
              ),

              // Card balance
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "SALDO DISPONIBLE",
                    style: TextStyle(fontSize: 9, color: Colors.white70, letterSpacing: 1),
                  ),
                  Text(
                    "\$${cardBalance.toStringAsFixed(2)}",
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Card Number and Client Name
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clientName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cardCode,
                    style: GoogleFonts.shareTechMono(
                      fontSize: 14,
                      color: const Color(0xFFF7DC6F),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              // Status Badge
              if (hasVip)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: vipCard['estatus'] == 1
                        ? AppTheme.successGreen.withValues(alpha: 0.2)
                        : AppTheme.alertRed.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: vipCard['estatus'] == 1 ? AppTheme.successGreen : AppTheme.alertRed,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    vipCard['estatus'] == 1 ? "ACTIVA" : "BLOQUEADA",
                    style: TextStyle(
                      color: vipCard['estatus'] == 1 ? AppTheme.successGreen : AppTheme.alertRed,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dialog Form to submit payments for requesting VIP Card or Recharging
class _PaymentReportDialog extends StatefulWidget {
  final bool isRecharge;
  final Map<String, String> bancosVenezuela;
  final VoidCallback onSuccess;

  const _PaymentReportDialog({
    required this.isRecharge,
    required this.bancosVenezuela,
    required this.onSuccess,
  });

  @override
  State<_PaymentReportDialog> createState() => _PaymentReportDialogState();
}

class _PaymentReportDialogState extends State<_PaymentReportDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoadingSubmit = false;

  String _pagoMetodo = "pago_movil";
  String _pagoBanco = "";
  final TextEditingController _referenciaCtrl = TextEditingController();
  late TextEditingController _montoCtrl;
  final TextEditingController _notaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Requesting VIP requires exactly 15.00. Recharge has no default limit.
    _montoCtrl = TextEditingController(text: widget.isRecharge ? "" : "15.00");
  }

  @override
  void dispose() {
    _referenciaCtrl.dispose();
    _montoCtrl.dispose();
    _notaCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoadingSubmit = true;
    });

    final double amount = double.tryParse(_montoCtrl.text) ?? 0.00;

    final result = widget.isRecharge
        ? await ApiService.recargarTarjetaVip(
            pagoMetodo: _pagoMetodo,
            pagoBanco: _pagoMetodo == 'efectivo' ? '' : _pagoBanco,
            pagoReferencia: _pagoMetodo == 'efectivo' ? '' : _referenciaCtrl.text.trim(),
            pagoMonto: amount,
            nota: _notaCtrl.text.trim(),
          )
        : await ApiService.solicitarTarjetaVip(
            pagoMetodo: _pagoMetodo,
            pagoBanco: _pagoMetodo == 'efectivo' ? '' : _pagoBanco,
            pagoReferencia: _pagoMetodo == 'efectivo' ? '' : _referenciaCtrl.text.trim(),
            pagoMonto: amount,
            nota: _notaCtrl.text.trim(),
          );

    if (!mounted) return;

    if (result['success']) {
      setState(() {
        _isLoadingSubmit = false;
      });
      Navigator.pop(context); // Close dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: AppTheme.successGreen,
        ),
      );
      widget.onSuccess();
    } else {
      setState(() {
        _isLoadingSubmit = false;
      });
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
    return AlertDialog(
      backgroundColor: AppTheme.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: AppTheme.primaryGold, width: 1.5),
      ),
      title: Text(
        widget.isRecharge ? "Reportar Recarga VIP" : "Solicitud Tarjeta VIP",
        style: GoogleFonts.cinzel(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Reporta tu transacción bancaria para acreditar el saldo.",
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 15),

              // Payment Method
              DropdownButtonFormField<String>(
                initialValue: _pagoMetodo,
                dropdownColor: AppTheme.darkCard,
                decoration: const InputDecoration(labelText: "Método de Pago"),
                items: const [
                  DropdownMenuItem(value: "pago_movil", child: Text("Pago Móvil")),
                  DropdownMenuItem(value: "transferencia", child: Text("Transferencia Bancaria")),
                  DropdownMenuItem(value: "efectivo", child: Text("Efectivo")),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _pagoMetodo = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 10),

              // Bank and Reference (if not cash)
              if (_pagoMetodo != 'efectivo') ...[
                DropdownButtonFormField<String>(
                  dropdownColor: AppTheme.darkCard,
                  decoration: const InputDecoration(labelText: "Banco origen *"),
                  items: widget.bancosVenezuela.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      _pagoBanco = val;
                    }
                  },
                  validator: (value) {
                    if (_pagoMetodo != 'efectivo' && (value == null || value.isEmpty)) {
                      return "Seleccione el banco.";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _referenciaCtrl,
                  decoration: const InputDecoration(labelText: "Referencia bancaria *"),
                  validator: (value) {
                    if (_pagoMetodo != 'efectivo' && (value == null || value.trim().isEmpty)) {
                      return "Ingrese el número de referencia.";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
              ],

              // Amount
              TextFormField(
                controller: _montoCtrl,
                keyboardType: TextInputType.number,
                readOnly: !widget.isRecharge, // Locked to 15.00 for card request
                decoration: const InputDecoration(labelText: "Monto a acreditar (\$) *"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Ingrese el monto.";
                  }
                  final double? numVal = double.tryParse(value);
                  if (numVal == null || numVal <= 0) {
                    return "Ingrese un monto válido mayor a 0.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Comment / Note
              TextFormField(
                controller: _notaCtrl,
                decoration: const InputDecoration(labelText: "Comentario / Nota (Opcional)"),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoadingSubmit ? null : () => Navigator.pop(context),
          child: const Text("Cancelar", style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGold,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _isLoadingSubmit ? null : _submitReport,
          child: _isLoadingSubmit
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                )
              : const Text("Enviar Reporte", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
