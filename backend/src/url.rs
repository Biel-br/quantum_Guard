use serde::{Deserialize, Serialize};
use std::fs;

#[derive(Deserialize)]
pub struct UrlRequest {
    pub url: String,
}

#[derive(Serialize)]
pub struct UrlResponse {
    pub url: String,
    pub dominio: String,
    pub ameaca: bool,
    pub tipo_ameaca: Option<String>,
    pub status: String,
}

// Normaliza a URL extraindo só o domínio
pub fn normalizar_url(url: &str) -> String {
    url.to_lowercase()
        .replace("https://", "")
        .replace("http://", "")
        .replace("www.", "")
        .split('/')
        .next()
        .unwrap_or("")
        .trim()
        .to_string()
}

// Carrega URLs maliciosas do JSON
pub fn carregar_urls() -> Vec<String> {
    let conteudo = fs::read_to_string("assets/urls_maliciosas.json")
        .unwrap_or_else(|_| r#"{"urls":[]}"#.to_string());
    let data: serde_json::Value = serde_json::from_str(&conteudo)
        .unwrap_or_default();
    data["urls"]
        .as_array()
        .unwrap_or(&vec![])
        .iter()
        .filter_map(|u| u.as_str().map(String::from))
        .collect()
}

// Verifica se a URL é maliciosa
pub fn verificar(url: &str) -> UrlResponse {
    let lista = carregar_urls();
    let dominio = normalizar_url(url);

    let exata = lista.contains(&dominio);
    let parcial = lista.iter().any(|mal| dominio.contains(mal.as_str()));
    let ameaca = exata || parcial;

    let tipo_ameaca = if exata {
        Some("Domínio malicioso conhecido".to_string())
    } else if parcial {
        Some("Domínio suspeito detectado".to_string())
    } else {
        None
    };

    UrlResponse {
        url: url.to_string(),
        dominio,
        ameaca,
        tipo_ameaca,
        status: if ameaca {
            "⚠️ URL Perigosa!".to_string()
        } else {
            "✅ URL Segura".to_string()
        },
    }
}