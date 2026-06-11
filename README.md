# Villa Eventos Delivery - Cliente Móvil 📱🍔

<p align="center">
  <img src="assets/logo.png" alt="Villa Eventos Logo" width="160" />
</p>

Aplicación móvil desarrollada en **Flutter** para clientes y comensales de **Villa Eventos**, diseñada para permitir el pedido de comida y bebidas tanto para entrega a domicilio (**Delivery**) como para consumo presencial a través de la asignación y validación rápida de **Mesas**.

Esta aplicación se conecta con la API REST del backend administrativo desarrollado en **Laravel**.

---

## ✨ Características Principales

* **Autenticación Dual:**
  - **Entrega a Domicilio (Delivery):** Registro e inicio de sesión de clientes habituales.
  - **Consumo en el Local (Mesas):** Autenticación rápida vinculada a un número de mesa mediante tokens JWT.
* **Carta de Platos en Tiempo Real:**
  - Visualización del catálogo de platos segmentado por categorías.
  - Manejo inteligente del stock y alertas de platos agotados.
* **Gestión de Carrito Inteligente:**
  - Suma automática de productos, cantidades y notas de preparación personalizadas por artículo.
* **Cálculo de Delivery por Geolocalización:**
  - Integración del sensor **GPS** para capturar las coordenadas de residencia del cliente.
  - Estimación en tiempo real del costo de envío comparando la distancia exacta entre el restaurante (coordenadas centrales) y la ubicación del cliente.
* **Pasarela de Pago Informativa:**
  - Soporte para métodos tradicionales de pago local: **Pago Móvil** (emisor, referencia, monto), **Transferencia Bancaria** y **Efectivo** al momento de la entrega.
* **Historial y Seguimiento de Pedidos:**
  - Vista integrada para monitorear el estado actual de las órdenes activas en la cocina (Pendiente, En Preparación, Entregado, Cancelado).

---

## 🛠️ Tecnologías Utilizadas

* **Framework:** [Flutter](https://flutter.dev/) (SDK ^3.10.4)
* **Lenguaje:** [Dart](https://dart.dev/)
* **Gestión de Estado:** `provider` (MultiProvider)
* **Geolocalización:** `geolocator`
* **Almacenamiento Local (Sesión):** `shared_preferences`
* **Peticiones HTTP:** `http`
* **Estilos y Diseño:** Tema oscuro premium personalizado (Dorado `#DAB203` y Carbón `#121212`) con tipografías `Cinzel` e `Inter`.

---

## 📁 Estructura del Proyecto (`lib/`)

El diseño de código sigue patrones limpios y modulares aplicando conceptos de diseño atómico en la interfaz de usuario:

```text
lib/
├── components/         # Widgets de interfaz reutilizables
│   ├── atoms/          # Componentes básicos (GoldButton, Loader, etc.)
│   └── molecules/      # Componentes combinados (DishCard, etc.)
├── core/               # Lógica central del sistema
│   ├── api/            # Servicio de conexión REST API (ApiService)
│   ├── providers/      # Manejo de estados de la aplicación (AuthState, CartState)
│   └── theme/          # Paleta de colores oficiales y configuración de estilos (AppTheme)
├── pages/              # Pantallas principales del flujo de usuario
│   ├── login_page.dart
│   ├── menu_page.dart
│   ├── order_status_page.dart
│   ├── profile_page.dart
│   ├── register_page.dart
│   └── splash_page.dart
└── main.dart           # Punto de inicio (Inicializa proveedores y carga el Splash)
```

---

## 🚀 Instalación y Puesta en Marcha

Sigue estos pasos para compilar y ejecutar el proyecto en tu entorno local:

### 1. Clonar el repositorio
```bash
git clone https://github.com/tu-usuario/villaeventos_client.git
cd villaeventos_client
```

### 2. Descargar las dependencias
Asegúrate de tener instalado el SDK de Flutter y ejecuta:
```bash
flutter pub get
```

### 3. Configurar el Servidor API
Al arrancar la aplicación móvil en modo de desarrollo, puedes configurar la dirección URL del servidor REST API haciendo clic en el **icono de engranaje (Configuración)** en la esquina superior derecha de la pantalla de inicio de sesión:
* **Producción:** `https://www.villaeventos.com/api/index.php`
* **Emulador Android Local:** `http://10.0.2.2:8081/villaeventos_master/api/index.php`
* **PC Local (Web/Debug):** `http://localhost:8081/villaeventos_master/api/index.php`

### 4. Ejecutar la aplicación
* **Modo Debug:**
  ```bash
  flutter run
  ```
* **Generar paquete de distribución (Release - Android App Bundle):**
  ```bash
  flutter build appbundle --release
  ```

---

## 🎨 Personalización de Marca

### Regenerar Icono de Inicio (Launcher Icons)
Si deseas cambiar el logo de la aplicación, sustituye el archivo `assets/logo.png` por tu nueva imagen y ejecuta:
```bash
flutter pub run flutter_launcher_icons
```
Este comando reconstruirá automáticamente los iconos de Android e iOS en todas las resoluciones requeridas.
