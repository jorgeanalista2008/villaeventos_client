import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String? _pendingRechargeMsg;

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
    _initData();
  }

  Future<void> _loadPendingRechargeMsg() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _pendingRechargeMsg = prefs.getString('pending_vip_recharge_msg');
      });
    }
  }

  Future<void> _savePendingRechargeMsg(String msg) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_vip_recharge_msg', msg);
    if (mounted) {
      setState(() {
        _pendingRechargeMsg = msg;
      });
    }
  }

  Future<void> _clearPendingRechargeMsg() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_vip_recharge_msg');
    if (mounted) {
      setState(() {
        _pendingRechargeMsg = null;
      });
    }
  }

  Future<void> _initData() async {
    // 1. Load any locally stored pending recharge messages first
    await _loadPendingRechargeMsg();
    if (!mounted) return;

    // 2. If we already have cached VIP card data, load movements immediately
    final authState = Provider.of<AuthState>(context, listen: false);
    final hasVipCached = authState.profile?['tarjeta_vip'] != null;
    if (hasVipCached) {
      _loadMovements();
    }

    // 3. Fetch the latest user profile/VIP state from the backend to ensure data is fresh
    try {
      await _refreshProfile();
      if (mounted) {
        final hasVipLatest = Provider.of<AuthState>(context, listen: false).profile?['tarjeta_vip'] != null;
        if (hasVipLatest) {
          _loadMovements();
        }
      }
    } catch (_) {
      // Ignore background refresh errors on startup to not disrupt UX
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
    final double oldBalance = auth.profile?['tarjeta_vip'] != null
        ? (double.tryParse(auth.profile?['tarjeta_vip']?['saldo']?.toString() ?? '0') ?? 0.00)
        : 0.00;

    await auth.checkSession();

    final double newBalance = auth.profile?['tarjeta_vip'] != null
        ? (double.tryParse(auth.profile?['tarjeta_vip']?['saldo']?.toString() ?? '0') ?? 0.00)
        : 0.00;

    // If balance changed, clear any pending recharge message automatically
    if (newBalance != oldBalance) {
      await _clearPendingRechargeMsg();
    }
  }

  /// Opens dialog to submit VIP application or Balance Recharge
  void _openPaymentDialog({required bool isRecharge}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _PaymentReportDialog(
          isRecharge: isRecharge,
          bancosVenezuela: _bancosVenezuela,
          onSuccess: (isRech, amount) async {
            if (isRech) {
              await _savePendingRechargeMsg("Hemos recibido su reporte de recarga por \$${amount.toStringAsFixed(2)}. Su saldo se actualizará una vez conciliado el pago.");
            }
            await _refreshProfile();
            if (!mounted) return;
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
                profile: profile,
                vipCard: vipCard,
                hasPending: hasPending,
                hasVip: hasVip,
                clientName: profile['nombre'] ?? 'Cliente VIP',
              ),
              const SizedBox(height: 25),

              // Pending Recharge Message Banner
              if (_pendingRechargeMsg != null && hasVip) ...[
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.successGreen, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppTheme.successGreen, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Procesando Recarga",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.successGreen,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _pendingRechargeMsg!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                        onPressed: _clearPendingRechargeMsg,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

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
    required Map<String, dynamic> profile,
    required dynamic vipCard,
    required bool hasPending,
    required bool hasVip,
    required String clientName,
  }) {
    // Format card code to match the mockup's "FID-XXXX-XXXX" format
    String cardCode = "FID-XXXX-XXXX";
    if (hasVip && vipCard['codigo'] != null) {
      final String rawCode = vipCard['codigo'].toString();
      if (rawCode.startsWith("VIP-")) {
        cardCode = "FID-${rawCode.substring(4)}";
      } else {
        cardCode = "FID-$rawCode";
      }
    } else if (hasPending) {
      cardCode = "EN CONCILIACIÓN";
    }

    final double cardBalance = hasVip ? (double.tryParse(vipCard['saldo']?.toString() ?? '0') ?? 0.00) : 0.00;

    // Retrieve card/client serial number (e.g. 00001)
    final int rawId = int.tryParse(vipCard?['id']?.toString() ?? '') ?? 
                      int.tryParse(profile['id']?.toString() ?? '') ?? 1;
    final String cardSerial = rawId.toString().padLeft(5, '0');

    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Dark diamond grid background
            Container(
              color: const Color(0xFF1E2125),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: DiamondGridPainter(),
              ),
            ),

            // 1. Top Left: VIP Brand and Status badge
            Positioned(
              top: 20,
              left: 20,
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "★ VIP ★",
                        style: GoogleFonts.cinzel(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFD4AF37),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 1.5,
                        width: 65,
                        color: const Color(0xFFD4AF37),
                      ),
                    ],
                  ),
                  const SizedBox(width: 15),
                  if (hasVip) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: vipCard['estatus'] == 1
                            ? AppTheme.successGreen.withValues(alpha: 0.15)
                            : AppTheme.alertRed.withValues(alpha: 0.15),
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
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 2. Top Right: Gold serial capsule (00001)
            Positioned(
              top: 18,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFFF3E5AB), Color(0xFFAA7C11)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.black45, width: 0.5),
                ),
                child: Text(
                  cardSerial,
                  style: GoogleFonts.robotoMono(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),

            // 3. Middle Left: Chip and Contactless indicator
            Positioned(
              top: 78,
              left: 20,
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE5C060), Color(0xFFC59E3F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: Colors.black38, width: 0.5),
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
                  const SizedBox(width: 8),
                  const Icon(Icons.sensors, color: Colors.white70, size: 18),
                ],
              ),
            ),

            // 4. Middle Right: Logo VE VILLA EVENTOS
            Positioned(
              top: 72,
              right: 20,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gold Box VE
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD4AF37), Color(0xFFF3E5AB), Color(0xFFAA7C11)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        "VE",
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // VILLA EVENTOS Text
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "VILLA",
                        style: GoogleFonts.cinzel(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFD4AF37),
                          height: 0.9,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        "EVENTOS",
                        style: GoogleFonts.cinzel(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFD4AF37),
                          height: 0.9,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 5. Bottom Section: Card Number and SALDO VIP (Separated to prevent overlapping the QR code)
            Positioned(
              top: 138,
              left: 20,
              child: Text(
                cardCode,
                style: GoogleFonts.robotoMono(
                  fontSize: 16,
                  color: Colors.white70,
                  letterSpacing: 1.5,
                ),
              ),
            ),

            Positioned(
              top: 132,
              right: 90, // Placed safely to the left of the overlapping QR code
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "SALDO VIP",
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    "\$${cardBalance.toStringAsFixed(2)}",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // 6. Gold Footer Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 52,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFFF3E5AB), Color(0xFFAA7C11)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        clientName.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 80), // Space for QR Code overlap
                  ],
                ),
              ),
            ),

            // 7. QR Code Overlapping both footer and body
            Positioned(
              bottom: 8,
              right: 20,
              width: 58,
              height: 58,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(3),
                child: const Icon(
                  Icons.qr_code_2,
                  color: Colors.black,
                  size: 52,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog Form to submit payments for requesting VIP Card or Recharging
class _PaymentReportDialog extends StatefulWidget {
  final bool isRecharge;
  final Map<String, String> bancosVenezuela;
  final Function(bool isRecharge, double amount) onSuccess;

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
  double _montoIngresado = 0.0;

  @override
  void initState() {
    super.initState();
    // Requesting VIP requires exactly 15.00. Recharge has no default limit.
    _montoCtrl = TextEditingController(text: widget.isRecharge ? "" : "15.00");
    _montoIngresado = double.tryParse(_montoCtrl.text) ?? 0.0;
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
      widget.onSuccess(widget.isRecharge, amount);
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
      scrollable: true,
      backgroundColor: AppTheme.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: AppTheme.primaryGold, width: 1.5),
      ),
      title: Text(
        widget.isRecharge ? "Reportar Recarga VIP" : "Solicitud Tarjeta VIP",
        style: GoogleFonts.cinzel(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: Form(
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
              isExpanded: true,
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
                isExpanded: true,
                dropdownColor: AppTheme.darkCard,
                decoration: const InputDecoration(labelText: "Banco origen *"),
                items: widget.bancosVenezuela.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(
                      entry.value,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
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
              onChanged: (value) {
                setState(() {
                  _montoIngresado = double.tryParse(value) ?? 0.0;
                });
              },
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

            // $50 rule real-time preview
            if (_montoIngresado >= 50.0) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.successGreen, width: 0.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: AppTheme.primaryGold, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "¡Bono VIP del +20% aplicado! Recibirás \$${(_montoIngresado * 1.2).toStringAsFixed(2)} de saldo de crédito.",
                        style: const TextStyle(
                          color: AppTheme.successGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Comment / Note
            TextFormField(
              controller: _notaCtrl,
              decoration: const InputDecoration(labelText: "Comentario / Nota (Opcional)"),
              maxLines: 1,
            ),
          ],
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

class DiamondGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double diamondSize = 35.0;

    // Draw diagonal lines from top-left to bottom-right
    for (double x = -size.height; x < size.width; x += diamondSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }

    // Draw diagonal lines from top-right to bottom-left
    for (double x = 0; x < size.width + size.height; x += diamondSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x - size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
