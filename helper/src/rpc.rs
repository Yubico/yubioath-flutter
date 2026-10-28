use std::io::{BufRead, Write};
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

/// Core RPC loop: reads commands, dispatches to NodeHost, sends responses.
fn run_rpc_loop(
    root: Box<dyn RpcNode>,
    send: SendFn,
    mut recv: Box<dyn FnMut() -> Option<String> + Send>,
) {
    let mut host = NodeHost::new(root);
    let (tx, rx) = mpsc::channel();
    std::thread::spawn(move || {
        let mut cancel = Arc::new(AtomicBool::new(false));
        while let Some(line) = recv() {
            if let Ok(request) = serde_json::from_str::<Value>(&line) {
                if request["kind"] == "signal" {
                    // Interrupt commands here, rather than queuing behind their completion.
                    if request["status"] == "cancel" {
                        cancel.store(true, Ordering::Relaxed);
                    }
                    continue;
                }
                if request["kind"] == "command" {
                    cancel = Arc::new(AtomicBool::new(false));
                }
            }
            if tx.send((line, cancel.clone())).is_err() {
                break;
            }
        }
        cancel.store(true, Ordering::Relaxed);
    });

    while let Ok((line, cancel)) = rx.recv() {
        let request: Value = match serde_json::from_str(&line) {
            Ok(v) => v,
            Err(_) => {
                send(
                    json!({"kind": "error", "status": "invalid-command", "message": "Invalid JSON", "body": {}}),
                );
                continue;
            }
        };

        if request.get("kind").and_then(|v| v.as_str()) != Some("command") {
            continue;
        }

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

        let response_json = match host.call(&action, &target, &params, &signal_fn, &cancel) {
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

#[cfg(test)]
mod tests {
    use super::*;
    use std::time::{Duration, Instant};

    struct WaitingNode;

    impl RpcNode for WaitingNode {
        fn list_actions(&self) -> Vec<&'static str> {
            vec!["wait"]
        }

        fn call_action(
            &mut self,
            _action: &str,
            _params: &Value,
            signal: SignalFn,
            cancel: &AtomicBool,
        ) -> Result<crate::error::RpcResponse, crate::error::RpcError> {
            signal("ready", json!({}));
            let deadline = Instant::now() + Duration::from_secs(2);
            while !cancel.load(Ordering::Relaxed) {
                if Instant::now() > deadline {
                    return Err(crate::error::RpcError::timeout());
                }
                std::thread::sleep(Duration::from_millis(1));
            }
            Err(crate::error::RpcError::new(
                "cancelled",
                "Operation cancelled",
            ))
        }
    }

    #[test]
    fn signals_interrupt_active_commands_without_cancelling_following_commands() {
        let (requests, incoming) = mpsc::channel();
        let (responses, outgoing) = mpsc::channel();
        let server = std::thread::spawn(move || {
            run_rpc_loop(
                Box::new(WaitingNode),
                Arc::new(move |response| responses.send(response).unwrap()),
                Box::new(move || incoming.recv().ok()),
            );
        });
        for _ in 0..2 {
            requests
                .send(json!({"kind": "command", "action": "wait"}).to_string())
                .unwrap();
            assert_eq!(
                outgoing.recv_timeout(Duration::from_secs(3)).unwrap()["status"],
                "ready"
            );
            requests
                .send(json!({"kind": "signal", "status": "cancel"}).to_string())
                .unwrap();
            assert_eq!(
                outgoing.recv_timeout(Duration::from_secs(3)).unwrap()["status"],
                "cancelled"
            );
            requests
                .send(json!({"kind": "command", "action": "get"}).to_string())
                .unwrap();
            assert_eq!(
                outgoing.recv_timeout(Duration::from_secs(3)).unwrap()["kind"],
                "success"
            );
        }
        drop(requests);
        server.join().unwrap();
    }
}
