//! Backend helper for the ScreenConfiger Plasma widget.
//!
//! Usage:
//!   screenconfiger list              JSON list of connected outputs
//!   screenconfiger status <output>   prints "on" or "off"
//!   screenconfiger toggle <output>   switches the output
//!   screenconfiger on|off <output>   enables / disables the output
//!   screenconfiger settings          opens System Settings > Display Configuration

use std::process::{Command, ExitCode};

use serde_json::{Value, json};

struct Output {
    name: String,
    enabled: bool,
}

/// Decodes the 3-letter PNP manufacturer ID from the EDID header and resolves it
/// to a readable name via hwdata's pnp.ids (falls back to the raw ID).
fn manufacturer(edid: &[u8]) -> Option<String> {
    let v = u16::from_be_bytes([edid[8], edid[9]]);
    let id: String = [(v >> 10) & 0x1F, (v >> 5) & 0x1F, v & 0x1F]
        .iter()
        .map(|&c| (b'A' + c as u8 - 1) as char)
        .collect();
    if !id.chars().all(|c| c.is_ascii_uppercase()) {
        return None;
    }
    let names = ["/usr/share/hwdata/pnp.ids", "/usr/share/misc/pnp.ids"]
        .iter()
        .find_map(|p| std::fs::read_to_string(p).ok());
    let full = names.and_then(|t| {
        t.lines()
            .find_map(|l| l.strip_prefix(id.as_str())?.strip_prefix('\t'))
            .map(|n| n.trim().to_owned())
    });
    let name = full.unwrap_or(id);
    let mut name = name;
    for suffix in [" inc.", " inc", " corporation", " co., ltd.", " ltd.", " computer"] {
        if name.to_lowercase().ends_with(suffix) {
            name.truncate(name.len() - suffix.len());
        }
    }
    Some(name)
}

/// Reads the monitor model name (EDID descriptor 0xFC) of a connector from sysfs.
fn friendly_name(connector: &str) -> Option<String> {
    let dir = std::fs::read_dir("/sys/class/drm").ok()?;
    let suffix = format!("-{connector}");
    for entry in dir.flatten() {
        if !entry.file_name().to_string_lossy().ends_with(&suffix) {
            continue;
        }
        let Ok(edid) = std::fs::read(entry.path().join("edid")) else {
            continue;
        };
        if edid.len() < 128 {
            continue;
        }
        for block in edid[54..126].chunks(18) {
            if block[..3] == [0, 0, 0] && block[3] == 0xFC {
                let text: String = block[5..]
                    .iter()
                    .take_while(|&&b| b != 0x0A)
                    .map(|&b| b as char)
                    .collect();
                let text = text.trim().to_owned();
                if !text.is_empty() {
                    return Some(match manufacturer(&edid) {
                        Some(m) if !text.starts_with(&m) => format!("{m} {text}"),
                        _ => text,
                    });
                }
            }
        }
    }
    None
}

fn run(program: &str, args: &[&str]) -> Result<String, String> {
    let out = Command::new(program)
        .args(args)
        .output()
        .map_err(|e| format!("cannot run {program}: {e}"))?;
    if !out.status.success() {
        let err = String::from_utf8_lossy(&out.stderr);
        return Err(format!("{program} failed: {}", err.trim()));
    }
    Ok(String::from_utf8_lossy(&out.stdout).into_owned())
}

fn outputs() -> Result<Vec<Output>, String> {
    let raw = run("kscreen-doctor", &["-j"])?;
    let json: Value = serde_json::from_str(&raw).map_err(|e| format!("invalid JSON: {e}"))?;
    let list = json["outputs"].as_array().ok_or("no outputs in kscreen JSON")?;
    Ok(list
        .iter()
        .filter(|o| o["connected"].as_bool().unwrap_or(false))
        .filter_map(|o| {
            Some(Output {
                name: o["name"].as_str()?.to_owned(),
                enabled: o["enabled"].as_bool().unwrap_or(false),
            })
        })
        .collect())
}

fn find(name: &str) -> Result<Output, String> {
    outputs()?
        .into_iter()
        .find(|o| o.name == name)
        .ok_or_else(|| format!("output '{name}' not found or not connected"))
}

fn set_output(name: &str, enable: bool) -> Result<(), String> {
    let all = outputs()?;
    if !all.iter().any(|o| o.name == name) {
        return Err(format!("output '{name}' not found or not connected"));
    }
    // Never switch off the last active screen.
    if !enable && all.iter().filter(|o| o.enabled).all(|o| o.name == name) {
        return Err("refusing to disable the last active output".into());
    }
    let arg = format!("output.{name}.{}", if enable { "enable" } else { "disable" });
    run("kscreen-doctor", &[&arg]).map(|_| ())
}

fn execute(args: &[String]) -> Result<String, String> {
    let cmd = args.first().map(String::as_str).unwrap_or("");
    let target = args.get(1).map(String::as_str).unwrap_or("");
    let need_target = || {
        if target.is_empty() {
            Err("missing output name".to_string())
        } else {
            Ok(())
        }
    };
    match cmd {
        "list" => {
            let list: Vec<Value> = outputs()?
                .iter()
                .map(|o| {
                    let label = match friendly_name(&o.name) {
                        Some(model) => format!("{model} ({})", o.name),
                        None => o.name.clone(),
                    };
                    json!({ "name": o.name, "label": label, "enabled": o.enabled })
                })
                .collect();
            Ok(Value::Array(list).to_string())
        }
        "status" => {
            need_target()?;
            Ok(if find(target)?.enabled { "on" } else { "off" }.into())
        }
        "toggle" => {
            need_target()?;
            let enable = !find(target)?.enabled;
            set_output(target, enable)?;
            Ok(if enable { "on" } else { "off" }.into())
        }
        "on" | "off" => {
            need_target()?;
            set_output(target, cmd == "on")?;
            Ok(cmd.into())
        }
        "settings" => {
            Command::new("kcmshell6")
                .arg("kcm_kscreen")
                .spawn()
                .map_err(|e| format!("cannot run kcmshell6: {e}"))?;
            Ok(String::new())
        }
        _ => Err("usage: screenconfiger <list|status|toggle|on|off|settings> [output]".into()),
    }
}

fn main() -> ExitCode {
    let args: Vec<String> = std::env::args().skip(1).collect();
    match execute(&args) {
        Ok(msg) => {
            if !msg.is_empty() {
                println!("{msg}");
            }
            ExitCode::SUCCESS
        }
        Err(e) => {
            eprintln!("{e}");
            ExitCode::FAILURE
        }
    }
}
