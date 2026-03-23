// Javier: Este módulo gestiona la comunicación entre el servicio Rust y la app Flutter.
// Analogía Flutter: es como el servidor de un backend local.
//                   Flutter se conecta a él como si fuera una API REST,
//                   pero usando sockets locales (IPC) en vez de HTTP.
//
// ¿Por qué sockets locales y no HTTP?
//   - El servicio y Flutter están en el mismo PC
//   - Los sockets locales son mucho más rápidos que HTTP
//   - No abren puertos de red (más seguro)
//
// Protocolo IPC:
//   - Socket Unix en macOS/Linux: /tmp/apliarte-switch.sock
//   - Named Pipe en Windows: \\.\pipe\apliarte-switch
//   - Formato mensajes: JSON (un objeto por línea = JSON Lines)
//
// Comandos que recibe de Flutter:
//   - {"cmd": "status"}               → responde con el estado actual
//   - {"cmd": "add_peer", "ip": "..."}  → añade un PC a la lista
//   - {"cmd": "remove_peer", "ip": "..."}→ elimina un PC
//   - {"cmd": "update_config", ...}    → actualiza la configuración
//   - {"cmd": "shutdown"}              → apaga el servicio

use crate::config::AppConfig;
use crate::input::protocol::InputEvent;
use anyhow::Result;
use serde::{Deserialize, Serialize};
use tokio::sync::mpsc::Sender;

// Javier: Mensajes que Flutter puede enviar al servicio (Fase 2)
#[allow(dead_code)]
#[derive(Debug, Deserialize)]
#[serde(tag = "cmd", rename_all = "snake_case")]
pub enum UiCommand {
    Status,
    AddPeer { ip: String, name: Option<String> },
    RemovePeer { ip: String },
    UpdateConfig { config: serde_json::Value },
    Shutdown,
}

// Javier: Respuestas que el servicio envía a Flutter (Fase 2)
#[allow(dead_code)]
#[derive(Debug, Serialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum UiResponse {
    Status {
        running: bool,
        active_peer: Option<String>,
        peers: Vec<PeerInfo>,
    },
    Ok,
    Error { message: String },
}

// Javier: Información de un PC conectado — es como un modelo en Flutter (Fase 2)
#[allow(dead_code)]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PeerInfo {
    pub ip: String,
    pub name: String,
    pub connected: bool,
}

/// Arranca el servidor IPC.
/// Javier: Es como iniciar un servidor local — Flutter lo conectará
/// para recibir estado en tiempo real y enviar comandos.
pub async fn serve(_event_tx: Sender<InputEvent>, _cfg: AppConfig) -> Result<()> {
    tracing::info!("🔌 Servidor IPC arrancado — esperando conexión de la UI Flutter");

    // Javier: Usamos interprocess para crear el socket local de forma cross-platform
    // En macOS/Linux: /tmp/apliarte-switch.sock
    // En Windows: \\.\pipe\apliarte-switch
    //
    // TODO Fase 2: Implementar el listener completo con interprocess::LocalSocketListener
    // Por ahora el servidor IPC hace loop vacío para no bloquear el select! de main.rs

    loop {
        tokio::time::sleep(tokio::time::Duration::from_secs(60)).await;
    }
}
