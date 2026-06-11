import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/cart_state.dart';

class DishCard extends StatelessWidget {
  final int id;
  final String nombre;
  final String descripcion;
  final double precio;
  final String imagen;
  final int? disponibles;

  const DishCard({
    Key? key,
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.imagen,
    required this.disponibles,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CartState>(
      builder: (context, cart, child) {
        // Check if item is already in cart to show count and controls
        final cartIndex = cart.items.indexWhere((item) => item.id == id);
        final inCartCount = cartIndex >= 0 ? cart.items[cartIndex].cantidad : 0;
        final bool isOutOfStock = disponibles != null && disponibles! <= 0;
        final bool hasReachedLimit = disponibles != null && inCartCount >= disponibles!;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          clipBehavior: Clip.antiAlias,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Dish Image
              SizedBox(
                width: 110,
                height: 110,
                child: Image.network(
                  imagen,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFF262626),
                      child: const Icon(
                        Icons.fastfood,
                        color: AppTheme.primaryGold,
                        size: 30,
                      ),
                    );
                  },
                ),
              ),
              
              // 2. Dish Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              nombre,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppTheme.textLight,
                              ),
                            ),
                          ),
                          Text(
                            "\$${precio.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.primaryGold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        descripcion,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // 3. Stock Indicators & Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Stock status badge
                          if (isOutOfStock)
                            const Text(
                              "Agotado",
                              style: TextStyle(
                                color: AppTheme.alertRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            )
                          else if (disponibles != null)
                            Text(
                              "Disp: $disponibles",
                              style: TextStyle(
                                color: disponibles! <= 3 ? AppTheme.alertRed : AppTheme.successGreen,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            )
                          else
                            const SizedBox(),
                          
                          // Cart Controls
                          if (isOutOfStock)
                            const SizedBox()
                          else if (inCartCount > 0)
                            Row(
                              children: [
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.remove_circle_outline, color: AppTheme.primaryGold, size: 24),
                                  onPressed: () => cart.decrementQuantity(id),
                                ),
                                Text(
                                  "$inCartCount",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryGold, size: 24),
                                  onPressed: hasReachedLimit ? null : () => cart.incrementQuantity(id),
                                ),
                              ],
                            )
                          else
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                cart.addToCart(
                                  id: id,
                                  nombre: nombre,
                                  precio: precio,
                                  imagen: imagen,
                                );
                              },
                              child: const Text(
                                "Agregar",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
