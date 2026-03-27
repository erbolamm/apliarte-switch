import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DeviceScanScreen extends StatefulWidget {
  const DeviceScanScreen({super.key});

  @override
  State<DeviceScanScreen> createState() => _DeviceScanScreenState();
}

class _DeviceScanScreenState extends State<DeviceScanScreen> {
  final Map<String, ScanResult> _resultsById = {};
  StreamSubscription<List<ScanResult>>? _scanSub;

  bool _isScanning = false;
  String _status = 'Listo. Pulsa “Buscar” para escanear.';

  // "Radio corto" aproximado => priorizamos señales fuertes (RSSI alto).
  // Nota: en Bluetooth LE el RSSI es aproximado y depende del entorno.
  int _minRssi = -90;

  final TextEditingController _filterController = TextEditingController();

  @override
  void dispose() {
    _scanSub?.cancel();
    _filterController.dispose();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Conseguimos resultados anteriores si el sistema los dejó disponibles.
    // (No siempre aplica en desktop, pero no hace daño).
    _refreshPoweredState();
  }

  Future<void> _refreshPoweredState() async {
    final state = await FlutterBluePlus.adapterState.first;
    if (state == BluetoothAdapterState.on) {
      setState(() {
        _status = 'Bluetooth encendido. Pulsa “Buscar”.';
      });
    } else if (state == BluetoothAdapterState.off) {
      setState(() {
        _status = 'Bluetooth está apagado. Enciéndelo para buscar dispositivos.';
      });
    } else {
      setState(() {
        _status = 'Bluetooth: estado ${state.name}.';
      });
    }
  }

  String _inferType(String name) {
    final n = name.toLowerCase();
    if (n.contains('mouse') || n.contains('rat')) return 'Ratón';
    if (n.contains('keyboard') || n.contains('tecl') || n.contains('keyb')) return 'Teclado';
    if (n.contains('head') || n.contains('cask') || n.contains('casc') || n.contains('audio')) return 'Cascos';
    if (n.contains('game') || n.contains('pad') || n.contains('controller') || n.contains('mando')) return 'Mando';
    return 'Dispositivo';
  }

  bool _matchesFilter(ScanResult r) {
    final query = _filterController.text.trim().toLowerCase();
    if (query.isEmpty) return true;

    final name = r.device.platformName.toLowerCase();
    final id = r.device.remoteId.str.toLowerCase();
    final type = _inferType(name).toLowerCase();
    return name.contains(query) || id.contains(query) || type.contains(query);
  }

  Future<void> _startScan() async {
    _resultsById.clear();
    setState(() {
      _isScanning = true;
      _status = 'Buscando dispositivos cercanos…';
    });

    await FlutterBluePlus.stopScan();

    // Inicia escaneo por BLE.
    FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 12),
      // En BLE para empezar: sin filtrar por servicios.
    );

    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final id = r.device.remoteId.str;

        // Filtrado "radio corto" => señales fuertes.
        final rssi = r.rssi;
                    if (rssi < _minRssi) continue;

        if (!_matchesFilter(r)) continue;

        // Nos quedamos el mejor último resultado por dispositivo.
        _resultsById[id] = r;
      }

      if (mounted) {
        setState(() {});
      }
    }, onError: (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Error en el escaneo: $e';
        _isScanning = false;
      });
    });

    // Cuando el timeout termina, dejamos de mostrar scanning.
    Future.delayed(const Duration(seconds: 13), () {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        if (_resultsById.isEmpty) {
          _status = 'No encontré dispositivos con esos filtros (RSSI >= $_minRssi).';
        } else {
          _status = 'Escaneo terminado. Dispositivos encontrados: ${_resultsById.length}.';
        }
      });
    });
  }

  Future<void> _stopScan() async {
    await FlutterBluePlus.stopScan();
    if (!mounted) return;
    setState(() {
      _isScanning = false;
      _status = 'Escaneo detenido.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = _resultsById.values.toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar conexiones cercanas'),
        actions: [
          if (_isScanning)
            IconButton(
              tooltip: 'Detener',
              icon: const Icon(Icons.stop_circle_outlined),
              onPressed: _stopScan,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _status,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _filterController,
                    decoration: const InputDecoration(
                      labelText: 'Filtro (nombre o tipo)',
                      hintText: 'ej: mouse, teclado, cascos, mando',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_isScanning,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 240,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Radio corto (RSSI >= $_minRssi)',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Slider(
                        value: _minRssi.toDouble(),
                        min: -95,
                        max: -35,
                        divisions: 12,
                        label: '$_minRssi',
                        onChanged: _isScanning
                            ? null
                            : (v) => setState(() => _minRssi = v.round()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isScanning ? null : _startScan,
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _resultsById.clear();
                      _status = 'Resultados borrados.';
                    });
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Limpiar'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Text('Aún no hay resultados.'),
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final r = items[i];
                        final id = r.device.remoteId.str;
                        final name = r.device.platformName;
                        final type = _inferType(name);

                        return ListTile(
                          leading: const Icon(Icons.bluetooth_searching),
                          title: Text(name.isEmpty ? id : name),
                          subtitle: Text('$type · RSSI: ${r.rssi}'),
                          trailing: Text(
                            id.length > 8 ? id.substring(0, 8) : id,
                            style: const TextStyle(color: Colors.white54),
                          ),
                          onTap: () {
                            showDialog<void>(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text(name.isEmpty ? id : name),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Tipo: $type'),
                                      Text('RSSI aproximado: ${r.rssi}'),
                                      const SizedBox(height: 10),
                                      const Text('ID (remoteId)'),
                                      Text(id),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('Cerrar'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

