use sha2::{Sha256, Digest};
use serde::{Deserialize, Serialize}; 
use std::fs;

#[derive(Deserialize)] 
#[allow(dead_code)]
pub struct HashRequest {
    pub bytes: Vec<u8>,
    pub nome: String,
}

#[derive(Serialize)]
pub struct HashResponse {
    pub hash: String,
    pub ameaca: bool,
    pub status: String,
}

// Gera SHA256 dos bytes
pub fn gerar_hash(bytes: &[u8]) -> String {
    let mut hasher = Sha256::new();
    hasher.update(bytes);
    hex::encode(hasher.finalize())
}

// Carrega hashes maliciosos do JSON
pub fn carregar_hashes() -> Vec<String> {
    let conteudo = fs::read_to_string("assets/hashes_maliciosos.json")
        .unwrap_or_else(|_| r#"{"hashes":[]}"#.to_string());
    let data: serde_json::Value = serde_json::from_str(&conteudo)
        .unwrap_or_default();
    data["hashes"]
        .as_array()
        .unwrap_or(&vec![])
        .iter()
        .filter_map(|h| h.as_str().map(String::from))
        .collect()
}

// Verifica se o hash é malicioso
pub fn verificar(hash: &str) -> HashResponse {
    let lista = carregar_hashes();
    let ameaca = lista.contains(&hash.to_string());
    HashResponse {
        hash: hash.to_string(),
        ameaca,
        status: if ameaca {
            "⚠️ Ameaça detectada!".to_string()
        } else {
            "✅ Arquivo limpo".to_string()
        },
    }
}