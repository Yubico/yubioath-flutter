use std::io::{BufRead, BufReader, Write};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex, mpsc};

use serde_json::{Value, json};

pub use ykman::rpc::node::{NodeHost, RpcNode, SignalFn};

type SendFn = Arc<dyn Fn(Value) + Send + Sync>;

/// Run the RPC server loop on stdin/stdout.
pub fn run(root: Box<dyn RpcNode>) {
    log::debug!("Starting RPC server on stdio");
    let stdout = Arc::new(Mutex::new(std::io::stdout()));

    let send: SendFn = {
        let stdout = stdout.clone();
        Arc::new(move |data: Value| {
            let mut out = stdout.lock().unwrap();
            serde_json::to_writer(&mut *out, &data).unwrap();
            out.write_all(b"\n").unwrap();
            out.flush().unwrap();
        })
    };

    let recv: Box<dyn FnMut() -> Option<String> + Send> = Box::new(|| {
        let stdin = std::io::stdin();
        let mut line = String::new();
        match stdin.lock().read_line(&mut line) {
            Ok(0) | Err(_) => None,
            Ok(_) => {
                let trimmed = line.trim().to_string();
                if trimmed.is_empty() {
                    None
                } else {
                    Some(trimmed)
                }
            }
        }
    });

    run_rpc_loop(root, send, recv);
}

/// Run the RPC server loop over a TCP connection.
/// Sends the nonce first, then processes commands.
pub fn run_tcp(root: Box<dyn RpcNode>, port: u16, nonce: &str) {
    use std::net::TcpListener;

    log::debug!("Starting RPC server on TCP port {port}");
    let listener = TcpListener::bind(("127.0.0.1", port)).expect("Failed to bind TCP port");
    let (stream, _) = listener.accept().expect("Failed to accept TCP connection");
    let writer = Arc::new(Mutex::new(
        stream.try_clone().expect("Failed to clone TCP stream"),
    ));

    // Send nonce as first message
    {
        let mut w = writer.lock().unwrap();
        writeln!(w, "{nonce}").expect("Failed to send nonce");
        w.flush().expect("Failed to flush nonce");
    }

    let send: SendFn = {
        let writer = writer.clone();
        Arc::new(move |data: Value| {
            let mut w = writer.lock().unwrap();
            serde_json::to_writer(&mut *w, &data).unwrap();
            w.write_all(b"\n").unwrap();
            w.flush().unwrap();
        })
    };

    let mut reader = BufReader::new(stream);
    let recv: Box<dyn FnMut() -> Option<String> + Send> = Box::new(move || {
        let mut line = String::new();
        match reader.read_line(&mut line) {
            Ok(0) | Err(_) => None,
            Ok(_) => {
                let trimmed = line.trim().to_string();
                if trimmed.is_empty() {
                    None
                } else {
                    Some(trimmed)
                }
            }
        }
    });

    run_rpc_loop(root, send, recv);
}

/// Core RPC loop: reads commands, dispatches to NodeHost, sends responses.
fn run_rpc_loop(
    root: Box<dyn RpcNode>,
    send: SendFn,
    mut recv: Box<dyn FnMut() -> Option<String> + Send>,
) {
    let mut host = NodeHost::new(root);
    let cancel = Arc::new(AtomicBool::new(false));

    // Spawn a reader thread that feeds lines into a channel.
    let (tx, rx) = mpsc::channel::<String>();
    std::thread::spawn(move || {
        while let Some(line) = recv() {
            if tx.send(line).is_err() {
                break;
            }
        }
    });

    while let Ok(line) = rx.recv() {
        let request: Value = match serde_json::from_str(&line) {
            Ok(v) => v,
            Err(_) => {
                send(
                    json!({"kind": "error", "status": "invalid-command", "message": "Invalid JSON", "body": {}}),
                );
                continue;
            }
        };

        match request.get("kind").and_then(|v| v.as_str()) {
            Some("signal") => {
                if request.get("status").and_then(|v| v.as_str()) == Some("cancel") {
                    cancel.store(true, Ordering::Relaxed);
                }
                continue;
            }
            Some("command") => {}
            _ => continue,
        }

        cancel.store(false, Ordering::Relaxed);

        let action = request
            .get("action")
            .and_then(|v| v.as_str())
            .unwrap_or("")
            .to_string();
        let target: Vec<String> = request
            .get("target")
            .and_then(|v| v.as_array())
            .map(|arr| {
                arr.iter()
                    .filter_map(|v| v.as_str().map(String::from))
                    .collect()
            })
            .unwrap_or_default();
        let params = request.get("body").cloned().unwrap_or_else(|| json!({}));

        let signal_fn = {
            let send = send.clone();
            move |status: &str, body: Value| {
                send(json!({"kind": "signal", "status": status, "body": body}));
            }
        };

        let response_json = match host.call(&action, &target, params, &signal_fn, &cancel) {
            Ok(response) => {
                json!({"kind": "success", "body": response.body, "flags": response.flags})
            }
            Err(e) => {
                json!({"kind": "error", "status": e.status, "message": e.message, "body": e.body})
            }
        };

        send(response_json);
    }
}
