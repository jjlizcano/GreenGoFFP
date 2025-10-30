import 'package:flutter/material.dart';
import 'dart:math' as math;

// ============================================================================
// MODELOS DE DATOS
// ============================================================================

class Pedido {
  final int id;
  final String cliente;
  final String direccion;
  final double distanciaKm;
  final int prioridad; // 1=urgente, 2=normal, 3=baja
  final DateTime horaEstimada;
  bool isDelivered;
  DateTime? horaEntrega;

  Pedido({
    required this.id,
    required this.cliente,
    required this.direccion,
    required this.distanciaKm,
    required this.prioridad,
    required this.horaEstimada,
    this.isDelivered = false,
    this.horaEntrega,
  });

  double get co2Ahorrado => distanciaKm * 0.21; // kg CO2 vs vehículo motor
  
  Color get prioridadColor {
    switch (prioridad) {
      case 1: return Colors.red[600]!;
      case 2: return Colors.orange[600]!;
      default: return Colors.blue[600]!;
    }
  }
}

// Datos simulados mejorados
final List<Pedido> pedidosSimulados = [
  Pedido(
    id: 101, 
    cliente: 'Tienda "El Roble"', 
    direccion: 'Av. Siempre Viva 742',
    distanciaKm: 2.3,
    prioridad: 1, // Urgente
    horaEstimada: DateTime.now().add(Duration(minutes: 15)),
  ),
  Pedido(
    id: 102, 
    cliente: 'Café "La Cosecha"', 
    direccion: 'Calle 50 #12-34',
    distanciaKm: 1.8,
    prioridad: 2, // Normal
    horaEstimada: DateTime.now().add(Duration(minutes: 30)),
  ),
  Pedido(
    id: 103, 
    cliente: 'Librería "El Lector"', 
    direccion: 'Carrera 23 #8-01',
    distanciaKm: 3.5,
    prioridad: 2, // Normal
    horaEstimada: DateTime.now().add(Duration(minutes: 45)),
  ),
  Pedido(
    id: 104, 
    cliente: 'Floristería "Margarita"', 
    direccion: 'Cl. 34A #45-67',
    distanciaKm: 1.2,
    prioridad: 3, // Baja
    horaEstimada: DateTime.now().add(Duration(hours: 1)),
  ),
  Pedido(
    id: 105, 
    cliente: 'Panadería "La Espiga"', 
    direccion: 'Cra. 15 #22-10',
    distanciaKm: 2.7,
    prioridad: 1, // Urgente
    horaEstimada: DateTime.now().add(Duration(minutes: 20)),
  ),
];

void main() {
  runApp(const GreenGoApp());
}

class GreenGoApp extends StatelessWidget {
  const GreenGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GreenGo Logistics Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
      ),
      home: const DriverScreen(),
    );
  }
}

// ============================================================================
// PANTALLA PRINCIPAL
// ============================================================================

// Enum para manejar los modos de ordenamiento
enum SortMode { byPriority, byId }

class DriverScreen extends StatefulWidget {
  const DriverScreen({super.key});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  bool _showCelebration = false;
  String _viewMode = 'map'; // Comienza en mapa
  SortMode _sortMode = SortMode.byPriority; // Por defecto, ordenar por prioridad

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  void toggleDeliveryStatus(int id) {
    setState(() {
      final pedido = pedidosSimulados.firstWhere((p) => p.id == id);
      pedido.isDelivered = !pedido.isDelivered;
      // Esto es crucial para el ordenamiento de entregados
      pedido.horaEntrega = pedido.isDelivered ? DateTime.now() : null; 
      
      if (pedidosSimulados.every((p) => p.isDelivered)) {
        _showCelebration = true;
        _celebrationController.forward();
        Future.delayed(Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _showCelebration = false);
            _celebrationController.reset();
          }
        });
      }
    });
  }

  double get progressPercentage {
    if (pedidosSimulados.isEmpty) return 0.0;
    final completed = pedidosSimulados.where((p) => p.isDelivered).length;
    return completed / pedidosSimulados.length;
  }

  double get totalCO2Saved {
    return pedidosSimulados
        .where((p) => p.isDelivered)
        .fold(0.0, (sum, p) => sum + p.co2Ahorrado);
  }

  double get totalDistancia {
    return pedidosSimulados.fold(0.0, (sum, p) => sum + p.distanciaKm);
  }

  @override
  Widget build(BuildContext context) {
    // LÓGICA DE ORDENAMIENTO CORREGIDA PARA EL MAPA
    final sortedPedidos = [...pedidosSimulados];
    sortedPedidos.sort((a, b) {
      // Prioridad 1: Los pedidos PENDIENTES van primero.
      if (a.isDelivered != b.isDelivered) {
        return a.isDelivered ? 1 : -1; // Pendiente (-1) va antes que Entregado (1)
      }

      // Prioridad 2: Si AMBOS están completados, ordenarlos por hora de entrega (el más antiguo va primero).
      if (a.isDelivered && b.isDelivered) {
        // Usamos '!' ya que ambos están 'isDelivered' y 'horaEntrega' no será nulo
        return a.horaEntrega!.compareTo(b.horaEntrega!); 
      }

      // Prioridad 3: Si AMBOS están pendientes, usar el modo de ordenamiento seleccionado.
      if (_sortMode == SortMode.byPriority) {
        // Ordenar por prioridad (1=alta)
        return a.prioridad.compareTo(b.prioridad);
      } else {
        // Ordenar por ID de pedido (101)
        return a.id.compareTo(b.id);
      }
    });
    // FIN LÓGICA DE ORDENAMIENTO

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green[50]!,
                  Colors.white,
                  Colors.green[50]!,
                ],
              ),
            ),
          ),
          
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                floating: false,
                pinned: true,
                backgroundColor: Color(0xFF2E7D32),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.white,
                                  child: Icon(Icons.pedal_bike, 
                                    color: Color(0xFF2E7D32), size: 30),
                                ),
                                SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Juan D.',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Ciclista Eco-Líder 🌱',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                _buildMiniStat(
                                  Icons.route, 
                                  '${totalDistancia.toStringAsFixed(1)} km',
                                  'Distancia total'
                                ),
                                SizedBox(width: 16),
                                _buildMiniStat(
                                  Icons.eco, 
                                  '${totalCO2Saved.toStringAsFixed(1)} kg',
                                  'CO₂ ahorrado'
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: EnhancedProgressHeader(
                  percentage: progressPercentage,
                  total: pedidosSimulados.length,
                  co2Saved: totalCO2Saved,
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Vista:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(width: 12),
                          _buildViewButton(Icons.map, 'map'),
                          SizedBox(width: 8),
                          _buildViewButton(Icons.grid_view, 'grid'),
                          SizedBox(width: 8),
                          _buildViewButton(Icons.view_list, 'list'),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'Ordenar:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(width: 12),
                          _buildSortButton(Icons.flag, 'Urgencia', SortMode.byPriority),
                          SizedBox(width: 8),
                          _buildSortButton(Icons.sort_by_alpha, 'N° Pedido', SortMode.byId),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              if (_viewMode == 'grid')
                SliverPadding(
                  padding: EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.8,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final pedido = sortedPedidos[index];
                        return EnhancedPedidoCard(
                          key: ValueKey(pedido.id),
                          pedido: pedido,
                          onToggle: () => toggleDeliveryStatus(pedido.id),
                        );
                      },
                      childCount: sortedPedidos.length,
                    ),
                  ),
                )
              else if (_viewMode == 'list')
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final pedido = sortedPedidos[index];
                      return PedidoListItem(
                        key: ValueKey(pedido.id),
                        pedido: pedido,
                        onToggle: () => toggleDeliveryStatus(pedido.id),
                      );
                    },
                    childCount: sortedPedidos.length,
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: RouteMapView(
                    pedidos: sortedPedidos, 
                    onToggle: toggleDeliveryStatus,
                  ),
                ),
            ],
          ),

          if (_showCelebration)
            CelebrationOverlay(controller: _celebrationController),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewButton(IconData icon, String mode) {
    final isActive = _viewMode == mode;
    return InkWell(
      onTap: () => setState(() => _viewMode = mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? Color(0xFF2E7D32) : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.grey[600],
          size: 20,
        ),
      ),
    );
  }

  Widget _buildSortButton(IconData icon, String label, SortMode mode) {
    final isActive = _sortMode == mode;
    return ChoiceChip(
      label: Text(label),
      labelStyle: TextStyle(
        color: isActive ? Colors.white : Colors.black87,
        fontWeight: FontWeight.bold
      ),
      avatar: Icon(
        icon, 
        color: isActive ? Colors.white : Color(0xFF2E7D32),
        size: 16,
      ),
      selected: isActive,
      // CORRECCIÓN: Ocultar la marca de verificación
      showCheckmark: false, 
      onSelected: (selected) {
        if (selected) {
          setState(() => _sortMode = mode);
        }
      },
      selectedColor: Color(0xFF2E7D32),
      backgroundColor: Colors.grey[200],
      shape: StadiumBorder(side: BorderSide(color: Colors.transparent)),
    );
  }
}

// ============================================================================
// VISTA DE MAPA CON PANEL LATERAL
// ============================================================================

class RouteMapView extends StatefulWidget {
  final List<Pedido> pedidos;
  final Function(int) onToggle;

  const RouteMapView({
    super.key,
    required this.pedidos,
    required this.onToggle,
  });

  @override
  State<RouteMapView> createState() => _RouteMapViewState();
}

class _RouteMapViewState extends State<RouteMapView> {
  int? _hoveredPedidoId;
  int? _selectedPedidoId;

  // Lógica de posición (usa la lista original para posiciones fijas)
  Offset _calculatePositionForPedido(Pedido pedido, int totalOriginal) {
    // Busca la posición del pedido por ID en la lista original (pedidosSimulados)
    final originalIndex = pedidosSimulados.indexWhere((p) => p.id == pedido.id);
    final positionIndex = originalIndex.isNegative ? 0 : originalIndex;

    // Fórmula para posicionar los nodos en un patrón espiral/circular
    final angle = (positionIndex / totalOriginal) * 2 * math.pi + (positionIndex * 0.5);
    final radius = 100.0 + (positionIndex * 40.0);
    final centerX = 200.0;
    final centerY = 300.0;
    
    return Offset(
      centerX + radius * math.cos(angle),
      centerY + radius * math.sin(angle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalOriginal = pedidosSimulados.length;
    
    return Stack(
      children: [
        Center(
          child: Container(
            height: 600,
            width: 600,
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Fondo de Mapa
                  Image.asset(
                    'assets/images/map.png', 
                    fit: BoxFit.contain,
                    width: 600,
                    height: 600,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[100],
                        child: Center(
                          child: Text(
                            'Placeholder de Mapa\n(Añade map.png a assets/images/)',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ),
                      );
                    },
                  ),
                  // Pintor de Rutas (usa la lista ORDENADA)
                  CustomPaint(
                    painter: RouteMapPainter(widget.pedidos), 
                    child: Stack(
                      children: [
                        // Nodos (usa la lista ORDENADA)
                        ...widget.pedidos.map((pedido) {
                          // Calcula la posición FIJA
                          final position = _calculatePositionForPedido(pedido, totalOriginal);
                          final isHovered = _hoveredPedidoId == pedido.id;
                          final isSelected = _selectedPedidoId == pedido.id;

                          return Positioned(
                            left: position.dx,
                            top: position.dy,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              onEnter: (_) => setState(() => _hoveredPedidoId = pedido.id),
                              onExit: (_) => setState(() => _hoveredPedidoId = null),
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _selectedPedidoId = isSelected ? null : pedido.id;
                                }),
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 200),
                                  transform: Matrix4.identity()
                                    ..scale(isHovered || isSelected ? 1.15 : 1.0),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: pedido.isDelivered
                                            ? Colors.green[100]
                                            : Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                              ? Colors.blue[700]!
                                              : (pedido.isDelivered
                                                ? Colors.green
                                                : pedido.prioridadColor),
                                            width: (isHovered || isSelected) ? 4 : 3,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: ((isHovered || isSelected)
                                                ? (isSelected ? Colors.blue : pedido.prioridadColor)
                                                : Colors.black).withOpacity((isHovered || isSelected) ? 0.4 : 0.2),
                                              blurRadius: (isHovered || isSelected) ? 16 : 8,
                                              spreadRadius: (isHovered || isSelected) ? 2 : 0,
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Icon(
                                            pedido.isDelivered
                                              ? Icons.check_circle
                                              : Icons.location_on,
                                            color: pedido.isDelivered
                                              ? Colors.green[700]
                                              : pedido.prioridadColor,
                                            size: 28,
                                          ),
                                        ),
                                      ),

                                      if (isHovered && !isSelected)
                                        Positioned(
                                          top: -60,
                                          left: -80,
                                          child: Container(
                                            width: 220,
                                            padding: EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.black87,
                                              borderRadius: BorderRadius.circular(8),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.3),
                                                  blurRadius: 8,
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  pedido.cliente,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  pedido.direccion,
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),

                        // Nodo de INICIO (estático)
                        Positioned(
                          left: 50,
                          top: 20,
                          child: Column(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Color(0xFF2E7D32),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'INICIO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(height: 4),
                              Container(
                                padding: EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Color(0xFF2E7D32),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.5),
                                      blurRadius: 15,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.pedal_bike,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Panel lateral animado
        if (_selectedPedidoId != null)
          Positioned(
            right: 32,
            top: 32,
            bottom: 32,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset((1 - value) * 300, 0),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: PedidoDetailPanel(
                pedido: pedidosSimulados.firstWhere((p) => p.id == _selectedPedidoId),
                onClose: () => setState(() => _selectedPedidoId = null),
                onToggleStatus: () {
                  widget.onToggle(_selectedPedidoId!);
                  // Forzar a cerrar el panel después de la acción.
                  setState(() => _selectedPedidoId = null); 
                },
              ),
            ),
          ),
      ],
    );
  }
}

class RouteMapPainter extends CustomPainter {
  final List<Pedido> pedidos; // Recibe la lista ORDENADA

  RouteMapPainter(this.pedidos);

  // Lógica de posición COPIADA de _RouteMapViewState para mantener los nodos fijos.
  Offset _calculatePositionForPedido(Pedido pedido, int totalOriginal) {
    final originalIndex = pedidosSimulados.indexWhere((p) => p.id == pedido.id);
    final positionIndex = originalIndex.isNegative ? 0 : originalIndex;

    final angle = (positionIndex / totalOriginal) * 2 * math.pi + (positionIndex * 0.5);
    final radius = 100.0 + (positionIndex * 40.0);
    final centerX = 200.0;
    final centerY = 300.0;
    
    return Offset(
      centerX + radius * math.cos(angle),
      centerY + radius * math.sin(angle),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final startPoint = Offset(80, 80); // Posición del ícono de INICIO
    final totalOriginal = pedidosSimulados.length;
    
    for (int i = 0; i < pedidos.length; i++) {
      final pedido = pedidos[i];
      // Calcula la posición FIJA del pedido actual
      final position = _calculatePositionForPedido(pedido, totalOriginal);
      
      // ESTE ES EL COLOR Y OPACIDAD DE LAS ARISTAS
      paint.color = pedido.isDelivered 
        ? Colors.green.withOpacity(0.5) 
        : Colors.grey.withOpacity(0.4);
      
      if (i == 0) {
        // Conecta INICIO con el primer pedido de la lista ORDENADA
        canvas.drawLine(startPoint, position + Offset(30, 30), paint);
      } else {
        // Conecta el pedido anterior (de la lista ordenada) con el actual
        final prevPedido = pedidos[i - 1];
        // Calcula la posición FIJA del pedido anterior
        final prevPosition = _calculatePositionForPedido(prevPedido, totalOriginal);
        canvas.drawLine(
          prevPosition + Offset(30, 30), 
          position + Offset(30, 30), 
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(RouteMapPainter oldDelegate) => true;
}

// ============================================================================
// WIDGETS DE COMPONENTES (CÓDIGO COMPLETADO)
// ============================================================================

// Panel de detalles del pedido
class PedidoDetailPanel extends StatelessWidget {
  final Pedido pedido;
  final VoidCallback onClose;
  final VoidCallback onToggleStatus;

  const PedidoDetailPanel({
    super.key,
    required this.pedido,
    required this.onClose,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [pedido.prioridadColor, pedido.prioridadColor.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    pedido.isDelivered ? Icons.check_circle : Icons.location_on,
                    color: pedido.prioridadColor,
                    size: 28,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pedido #${pedido.id}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        pedido.isDelivered ? 'ENTREGADO' : 'PENDIENTE',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection(
                    icon: Icons.person,
                    title: 'Cliente',
                    content: pedido.cliente,
                    iconColor: Colors.blue,
                  ),
                  SizedBox(height: 20),
                  _buildInfoSection(
                    icon: Icons.location_on,
                    title: 'Dirección',
                    content: pedido.direccion,
                    iconColor: Colors.red,
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.route,
                          label: 'Distancia',
                          value: '${pedido.distanciaKm} km',
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.eco,
                          label: 'CO₂ Ahorrado',
                          value: '${pedido.co2Ahorrado.toStringAsFixed(2)} kg',
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  _buildInfoSection(
                    icon: Icons.flag,
                    title: 'Prioridad',
                    content: pedido.prioridad == 1 
                      ? 'Alta (Urgente)' 
                      : (pedido.prioridad == 2 ? 'Media (Normal)' : 'Baja'),
                    iconColor: pedido.prioridadColor,
                  ),
                  SizedBox(height: 20),
                  _buildInfoSection(
                    icon: Icons.access_time,
                    title: 'Hora Estimada',
                    content: '${pedido.horaEstimada.hour.toString().padLeft(2, '0')}:${pedido.horaEstimada.minute.toString().padLeft(2, '0')}',
                    iconColor: Colors.purple,
                  ),
                  if (pedido.isDelivered && pedido.horaEntrega != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20),
                        _buildInfoSection(
                          icon: Icons.timer_off,
                          title: 'Hora de Entrega',
                          content: 
                            '${pedido.horaEntrega!.hour.toString().padLeft(2, '0')}:${pedido.horaEntrega!.minute.toString().padLeft(2, '0')}',
                          iconColor: Colors.teal,
                        ),
                      ],
                    ),
                  SizedBox(height: 30),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: onToggleStatus,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pedido.isDelivered ? Colors.red[600] : Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      icon: Icon(
                        pedido.isDelivered ? Icons.undo : Icons.check_circle,
                        size: 24,
                      ),
                      label: Text(
                        pedido.isDelivered 
                          ? 'MARCAR COMO PENDIENTE' 
                          : 'CONFIRMAR ENTREGA',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String content,
    required Color iconColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 28.0),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// COMPONENTES FALTANTES (AÑADIDOS)
// ============================================================================

class EnhancedProgressHeader extends StatelessWidget {
  final double percentage;
  final int total;
  final double co2Saved;

  const EnhancedProgressHeader({
    super.key,
    required this.percentage,
    required this.total,
    required this.co2Saved,
  });

  @override
  Widget build(BuildContext context) {
    final completed = (percentage * total).round();
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progreso de la Ruta',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completed de $total Entregas',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                '${(percentage * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey[200],
                color: Color(0xFF4CAF50),
                minHeight: 8,
              ),
            ),
          ),
          SizedBox(height: 10),
          AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Text(
              '¡Has ahorrado ${co2Saved.toStringAsFixed(1)} kg de CO₂!',
              key: ValueKey(co2Saved), 
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EnhancedPedidoCard extends StatelessWidget {
  final Pedido pedido;
  final VoidCallback onToggle;

  const EnhancedPedidoCard({super.key, required this.pedido, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: pedido.isDelivered ? Colors.green.withOpacity(0.2) : pedido.prioridadColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: pedido.isDelivered ? Colors.green.shade300 : pedido.prioridadColor.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ID: ${pedido.id}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: pedido.prioridadColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      pedido.prioridad == 1 ? 'URGENTE' : (pedido.prioridad == 2 ? 'NORMAL' : 'BAJA'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: pedido.prioridadColor,
                      ),
                    ),
                  ),
                ],
              ),
              Divider(height: 12),
              Text(
                pedido.cliente,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      pedido.direccion,
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.route, size: 14, color: Colors.orange[600]),
                  SizedBox(width: 4),
                  Text(
                    '${pedido.distanciaKm} km',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  Spacer(),
                  Icon(Icons.access_time, size: 14, color: Colors.blue[600]),
                  SizedBox(width: 4),
                  Text(
                    '${pedido.horaEstimada.hour.toString().padLeft(2, '0')}:${pedido.horaEstimada.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
              Spacer(),
              Center(
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: pedido.isDelivered ? Colors.green[600] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        pedido.isDelivered ? Icons.check : Icons.delivery_dining,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        pedido.isDelivered ? 'COMPLETADO' : 'PENDIENTE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PedidoListItem extends StatelessWidget {
  final Pedido pedido;
  final VoidCallback onToggle;

  const PedidoListItem({super.key, required this.pedido, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: pedido.isDelivered ? Colors.green[50] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: pedido.isDelivered ? Colors.green.shade200 : Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          if (!pedido.isDelivered)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
        ],
      ),
      child: ListTile(
        onTap: onToggle,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: pedido.isDelivered ? Colors.green[100] : pedido.prioridadColor.withOpacity(0.1),
          child: Icon(
            pedido.isDelivered ? Icons.check_circle_outline : Icons.pin_drop,
            color: pedido.isDelivered ? Colors.green[700] : pedido.prioridadColor,
          ),
        ),
        title: Text(
          pedido.cliente,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: pedido.isDelivered ? TextDecoration.lineThrough : TextDecoration.none,
            color: pedido.isDelivered ? Colors.grey[600] : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pedido.direccion, 
              style: TextStyle(
                fontSize: 12,
                color: pedido.isDelivered ? Colors.grey[500] : Colors.grey[700],
              )
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.route, size: 12, color: Colors.orange),
                SizedBox(width: 4),
                Text('${pedido.distanciaKm} km', style: TextStyle(fontSize: 11)),
                SizedBox(width: 12),
                Icon(Icons.access_time, size: 12, color: Colors.blue),
                SizedBox(width: 4),
                Text(
                  'Est. ${pedido.horaEstimada.hour.toString().padLeft(2, '0')}:${pedido.horaEstimada.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 11)
                ),
              ],
            ),
          ],
        ),
        trailing: pedido.isDelivered
            ? Icon(Icons.check, color: Colors.green, size: 30)
            : Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}

class CelebrationOverlay extends StatelessWidget {
  final AnimationController controller;

  const CelebrationOverlay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: FadeTransition(
        opacity: controller.drive(CurveTween(curve: Curves.easeIn)),
        child: Container(
          // Color de fondo animado
          color: Colors.green.withOpacity(0.3 * controller.value),
          child: Center(
            child: ScaleTransition(
              // Animación de escala para el conjunto
              scale: controller.drive(
                Tween<double>(begin: 0.5, end: 1.5).chain(
                  CurveTween(curve: Curves.elasticOut),
                ),
              ),
              // NO aplicamos RotationTransition aquí
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Aplicamos RotationTransition SÓLO al Icono de estrella
                  RotationTransition(
                    turns: controller.drive(
                      Tween<double>(begin: 0, end: 0.5).chain(
                        CurveTween(curve: Curves.easeInOut),
                      ),
                    ),
                    child: Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 150,
                    ),
                  ),
                  SizedBox(height: 10),
                  // El texto se mantiene estático y legible
                  Text(
                    '¡Ruta Completada!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 10,
                        )
                      ]
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}