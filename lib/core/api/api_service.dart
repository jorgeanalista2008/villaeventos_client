import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // 🔑 Configuration Keys
  static const String _tokenKey = "jwt_token";
  static const String _mesaIdKey = "auth_mesa_id";
  static const String _apiBaseUrlKey = "api_base_url";

  // Default Base URL fallback (Production)
  static String get defaultBaseUrl => "https://www.villaeventos.com/api/index.php";

  /// Returns current configured Base URL
  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiBaseUrlKey) ?? defaultBaseUrl;
  }

  /// Set custom Base URL (useful for physical device testing in different LAN networks)
  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiBaseUrlKey, url);
  }

  /// Save auth token and table ID locally
  static Future<void> saveSession(String token, int mesaId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setInt(_mesaIdKey, mesaId);
  }

  /// Clear local session (logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_mesaIdKey);
  }

  /// Retrieve current stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Retrieve current stored table ID
  static Future<int?> getMesaId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_mesaIdKey);
  }

  /// 1. Authentication (POST /api/index.php?route=auth-mesa)
  static Future<Map<String, dynamic>> authenticateTable(int mesaId) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse("$baseUrl?route=auth-mesa");
    
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id_mesa": mesaId}),
      );
      
      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['status'] == 'success') {
        final token = result['token'];
        await saveSession(token, mesaId);
        return {"success": true, "message": result['message'], "data": result['data']};
      }
      return {"success": false, "message": result['message'] ?? "Error de autenticación."};
    } catch (e) {
      return _handleError(e);
    }
  }

  /// 2. Get Menu (GET /api/index.php?route=menu) - Public
  static Future<List<dynamic>?> getMenu() async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse("$baseUrl?route=menu");
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          return result['data'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 3. Verify Table (GET /api/index.php?route=mesa-verificar) - Secured
  static Future<Map<String, dynamic>?> verificarMesa() async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse("$baseUrl?route=mesa-verificar");
    final token = await getToken();
    
    if (token == null) return null;
    
    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          return result['data'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 4. Submit Order (POST /api/index.php?route=pedido) - Secured
  static Future<Map<String, dynamic>> submitOrder({
    required List<Map<String, dynamic>> items,
    String comentario = "",
  }) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse("$baseUrl?route=pedido");
    final token = await getToken();
    
    if (token == null) {
      return {"success": false, "message": "Sesión no iniciada. Autentíquese."};
    }
    
    final payload = {
      "comentario": comentario,
      "platos": items // Expected: [{ "id_plato": X, "cantidad": Y, "nota": Z }]
    };
    
    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode(payload),
      );
      
      final result = jsonDecode(response.body);
      if (response.statusCode == 201 && result['status'] == 'success') {
        return {
          "success": true, 
          "message": result['message'], 
          "id_pedido": result['data']['id_pedido'],
          "total": result['data']['total']
        };
      }
      return {"success": false, "message": result['message'] ?? "Error al enviar el pedido."};
    } catch (e) {
      return _handleError(e);
    }
  }

  /// 5. Get Order Status (GET /api/index.php?route=pedido-estado) - Secured
  static Future<List<dynamic>?> getActiveOrders() async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse("$baseUrl?route=pedido-estado");
    final token = await getToken();
    
    if (token == null) return null;
    
    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          return result['data']; // Returns a list of active orders for the table
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Save auth token locally (for customers, no table ID needed)
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Customer Registration (POST /api/index.php?route=cliente-registro)
  static Future<Map<String, dynamic>> registerClient({
    required String nombre,
    required String telefono,
    required String email,
    required String password,
    required String direccion,
    required String latitud,
    required String longitud,
    required String notas,
  }) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse("$baseUrl?route=cliente-registro");
    
    final body = {
      "nombre": nombre,
      "telefono": telefono,
      "email": email,
      "password": password,
      "direccion": direccion,
      "latitud": latitud,
      "longitud": longitud,
      "notas": notas,
    };
    
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      
      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['status'] == 'success') {
        return {"success": true, "message": result['message'], "id": result['id']};
      }
      return {"success": false, "message": result['message'] ?? "Error de registro."};
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Customer Authentication (POST /api/index.php?route=cliente-login)
  static Future<Map<String, dynamic>> loginClient(String email, String password) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse("$baseUrl?route=cliente-login");
    
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );
      
      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['status'] == 'success') {
        final token = result['token'];
        await saveToken(token);
        return {"success": true, "message": result['message'], "data": result['data']};
      }
      return {"success": false, "message": result['message'] ?? "Error de inicio de sesión."};
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Customer Profile (GET /api/index.php?route=cliente-perfil)
  static Future<Map<String, dynamic>> getClientProfile() async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse("$baseUrl?route=cliente-perfil");
    final token = await getToken();
    
    if (token == null) {
      return {"success": false, "message": "No hay token local."};
    }
    
    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );
      
      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['status'] == 'success') {
        return {"success": true, "data": result['data']};
      }
      return {"success": false, "message": result['message'] ?? "Error al obtener perfil."};
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Delete Customer Account (POST /api/index.php?route=cliente-eliminar)
  static Future<Map<String, dynamic>> eliminarCuentaCliente() async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse("$baseUrl?route=cliente-eliminar");
    final token = await getToken();

    if (token == null) {
      return {"success": false, "message": "No hay token local."};
    }

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['status'] == 'success') {
        return {"success": true, "message": result['message']};
      }
      return {"success": false, "message": result['message'] ?? "Error al eliminar la cuenta."};
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Submit Customer Delivery Order (POST /api/index.php?route=cliente-pedido)
  static Future<Map<String, dynamic>> submitClientOrder({
    required String metodo,
    required String telefono,
    required String direccion,
    required String latitud,
    required String longitud,
    required String nota,
    required List<Map<String, dynamic>> items,
    required String pagoMetodo,
    required String pagoBanco,
    required String pagoReferencia,
    required String pagoMonto,
  }) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse("$baseUrl?route=cliente-pedido");
    final token = await getToken();
    
    if (token == null) {
      return {"success": false, "message": "Sesión expirada. Inicie sesión."};
    }
    
    final payload = {
      "metodo": metodo,
      "telefono": telefono,
      "direccion": direccion,
      "latitud": latitud,
      "longitud": longitud,
      "nota": nota,
      "platos": items,
      "pago_metodo": pagoMetodo,
      "pago_banco": pagoBanco,
      "pago_referencia": pagoReferencia,
      "pago_monto": pagoMonto
    };
    
    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode(payload),
      );
      
      final result = jsonDecode(response.body);
      if (response.statusCode == 201 && result['status'] == 'success') {
        return {
          "success": true,
          "message": result['message'],
          "id_pedido": result['data']['id_pedido'],
          "costo_comida": result['data']['costo_comida'],
          "costo_delivery": result['data']['costo_delivery'],
          "total": result['data']['total']
        };
      }
      return {"success": false, "message": result['message'] ?? "Error al crear pedido."};
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Get Customer Orders History (GET /api/index.php?route=cliente-pedidos)
  static Future<List<dynamic>?> getClientOrders() async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse("$baseUrl?route=cliente-pedidos");
    final token = await getToken();
    
    if (token == null) return null;
    
    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          return result['data'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Request a New VIP Card (POST /api/index.php?route=cliente-solicitar-vip)
  static Future<Map<String, dynamic>> solicitarTarjetaVip({
    required String pagoMetodo,
    required String pagoBanco,
    required String pagoReferencia,
    required double pagoMonto,
    String nota = "",
  }) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse("$baseUrl?route=cliente-solicitar-vip");
    final token = await getToken();

    if (token == null) {
      return {"success": false, "message": "Sesión expirada. Inicie sesión."};
    }

    final payload = {
      "pago_metodo": pagoMetodo,
      "pago_banco": pagoBanco,
      "pago_referencia": pagoReferencia,
      "pago_monto": pagoMonto,
      "nota": nota
    };

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode(payload),
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['status'] == 'success') {
        return {
          "success": true,
          "message": result['message'],
          "id_pedido": result['data']['id_pedido'],
          "total": result['data']['total']
        };
      }
      return {"success": false, "message": result['message'] ?? "Error al solicitar tarjeta VIP."};
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Get VIP Card Transactions History (GET /api/index.php?route=cliente-vip-movimientos)
  static Future<List<dynamic>?> getMovimientosVip() async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse("$baseUrl?route=cliente-vip-movimientos");
    final token = await getToken();

    if (token == null) return null;

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          return result['data'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Report Payment to Recharge VIP Card (POST /api/index.php?route=cliente-vip-recargar)
  static Future<Map<String, dynamic>> recargarTarjetaVip({
    required String pagoMetodo,
    required String pagoBanco,
    required String pagoReferencia,
    required double pagoMonto,
    String nota = "",
  }) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse("$baseUrl?route=cliente-vip-recargar");
    final token = await getToken();

    if (token == null) {
      return {"success": false, "message": "Sesión expirada. Inicie sesión."};
    }

    final payload = {
      "pago_metodo": pagoMetodo,
      "pago_banco": pagoBanco,
      "pago_referencia": pagoReferencia,
      "pago_monto": pagoMonto,
      "nota": nota
    };

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode(payload),
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['status'] == 'success') {
        return {
          "success": true,
          "message": result['message'],
          "id_pedido": result['data']['id_pedido'],
          "total": result['data']['total']
        };
      }
      return {"success": false, "message": result['message'] ?? "Error al recargar tarjeta VIP."};
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Request Password Recovery Code (POST /api/index.php?route=cliente-recuperar-solicitar)
  static Future<Map<String, dynamic>> solicitarCodigoRecuperacion(String email) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse("$baseUrl?route=cliente-recuperar-solicitar");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['status'] == 'success') {
        return {"success": true, "message": result['message']};
      }
      return {"success": false, "message": result['message'] ?? "Error al solicitar código."};
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Verify Password Recovery Code (POST /api/index.php?route=cliente-recuperar-verificar)
  static Future<Map<String, dynamic>> verificarCodigoRecuperacion(String email, String code) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse("$baseUrl?route=cliente-recuperar-verificar");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "code": code}),
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['status'] == 'success') {
        return {"success": true, "message": result['message']};
      }
      return {"success": false, "message": result['message'] ?? "Código de verificación incorrecto."};
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Reset Password (POST /api/index.php?route=cliente-recuperar-restablecer)
  static Future<Map<String, dynamic>> restablecerContrasena(String email, String code, String password) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse("$baseUrl?route=cliente-recuperar-restablecer");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "code": code, "password": password}),
      );

      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['status'] == 'success') {
        return {"success": true, "message": result['message']};
      }
      return {"success": false, "message": result['message'] ?? "Error al restablecer la contraseña."};
    } catch (e) {
      return _handleError(e);
    }
  }

  static Map<String, dynamic> _handleError(dynamic e) {
    return {
      "success": false,
      "message": "No se pudo establecer conexión con el servidor. Por favor, verifique su conexión a Internet."
    };
  }
}
