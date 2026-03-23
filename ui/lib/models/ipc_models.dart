// Javier: Modelos de datos compartidos entre Rust y Flutter.
// Es como la "traducción" de los JSONs que viajan por el cable IPC.

class PeerInfo {
  final String ip;
  final String name;
  final bool connected;

  PeerInfo({required this.ip, required this.name, required this.connected});

  factory PeerInfo.fromJson(Map<String, dynamic> json) {
    return PeerInfo(
      ip: json['ip'] ?? '',
      name: json['name'] ?? '',
      connected: json['connected'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'ip': ip,
        'name': name,
        'connected': connected,
      };
}

class UiResponse {
  final String type;
  final bool? running;
  final String? activePeer;
  final List<PeerInfo>? peers;
  final String? message;

  UiResponse({
    required this.type,
    this.running,
    this.activePeer,
    this.peers,
    this.message,
  });

  factory UiResponse.fromJson(Map<String, dynamic> json) {
    return UiResponse(
      type: json['type'] ?? 'error',
      running: json['running'],
      activePeer: json['active_peer'],
      peers: json['peers'] != null
          ? (json['peers'] as List).map((p) => PeerInfo.fromJson(p)).toList()
          : null,
      message: json['message'],
    );
  }
}
