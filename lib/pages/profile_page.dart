import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/auth_state.dart';
import '../core/providers/cart_state.dart';
import '../components/atoms/gold_button.dart';
import 'vip_card_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = Provider.of<AuthState>(context);
    final profile = authState.profile ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Perfil"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Header Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppTheme.primaryGold,
                        child: Text(
                          (profile['nombre'] ?? 'U').toString().substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile['nombre'] ?? 'Cliente',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profile['email'] ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildVipSectionCard(context, profile),
              const SizedBox(height: 25),

              const Text(
                "Datos de Contacto y Envío",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGold,
                ),
              ),
              const SizedBox(height: 15),

              // Telefono
              _buildInfoRow(
                icon: Icons.phone,
                title: "Teléfono",
                value: profile['telefono'] ?? 'No especificado',
              ),
              const Divider(color: Color(0xFF333333)),

              // Direccion
              _buildInfoRow(
                icon: Icons.home,
                title: "Dirección Guardada",
                value: profile['direccion'] ?? 'No especificada',
              ),
              const Divider(color: Color(0xFF333333)),

              // Coordinates GPS
              _buildInfoRow(
                icon: Icons.my_location,
                title: "Coordenadas GPS",
                value: (profile['latitud'] != null && profile['longitud'] != null)
                    ? "Lat: ${profile['latitud']}, Lng: ${profile['longitud']}"
                    : "No geolocalizado",
              ),
              const Divider(color: Color(0xFF333333)),

              // Notas
              _buildInfoRow(
                icon: Icons.description,
                title: "Puntos de Referencia / Notas",
                value: profile['notas'] ?? 'Sin notas',
              ),
              const SizedBox(height: 40),

              // Logout Button
              GoldButton(
                label: "Cerrar Sesión",
                icon: Icons.logout,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("¿Desea cerrar sesión?"),
                        content: const Text("Se cerrará su cuenta de delivery en este dispositivo."),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancelar"),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context); // close dialog
                              Navigator.pop(context); // close profile page
                              await authState.logout();
                              if (context.mounted) {
                                Provider.of<CartState>(context, listen: false).clearCart();
                              }
                              await SystemNavigator.pop();
                            },
                            child: const Text("Cerrar Sesión", style: TextStyle(color: AppTheme.alertRed)),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryGold, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildVipSectionCard(BuildContext context, Map<String, dynamic> profile) {
    final vipCard = profile['tarjeta_vip'];
    final bool hasPending = profile['tiene_vip_pendiente'] == true;
    final bool hasVip = vipCard != null;

    IconData cardIcon = Icons.card_membership;
    String cardTitle = "Obtener Tarjeta VIP";
    String cardSubtitle = "Únete al club de fidelidad y acumula saldo";
    Color borderColor = const Color(0xFF333333);

    if (hasVip) {
      cardIcon = Icons.credit_card;
      final double cardBalance = double.tryParse(vipCard['saldo']?.toString() ?? '0') ?? 0.00;
      cardTitle = "Tarjeta VIP Activa";
      cardSubtitle = "Saldo: \$${cardBalance.toStringAsFixed(2)} • Código: ${vipCard['codigo']}";
      borderColor = AppTheme.primaryGold;
    } else if (hasPending) {
      cardIcon = Icons.hourglass_empty;
      cardTitle = "Tarjeta VIP (En Conciliación)";
      cardSubtitle = "Verificando su reporte de pago...";
      borderColor = AppTheme.primaryGold.withValues(alpha: 0.5);
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: hasVip || hasPending ? 1.5 : 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: (hasVip || hasPending)
              ? AppTheme.primaryGold.withValues(alpha: 0.15)
              : const Color(0xFF262626),
          child: Icon(cardIcon, color: (hasVip || hasPending) ? AppTheme.primaryGold : Colors.grey),
        ),
        title: Text(
          cardTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            cardSubtitle,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.primaryGold),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const VipCardPage()),
          );
        },
      ),
    );
  }
}
