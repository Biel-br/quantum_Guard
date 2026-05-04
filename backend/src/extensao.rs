use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Deserialize)]
pub struct ExtensaoRequest {
    pub arquivos: Vec<String>,
}

#[derive(Serialize)]
pub struct ResultadoArquivo {
    pub nome: String,
    pub extensao: String,
    pub perigosa: bool,
    pub descricao: String,
}

#[derive(Serialize)]
pub struct ExtensaoResponse {
    pub resultados: Vec<ResultadoArquivo>,
    pub total: usize,
    pub perigosos: usize,
    pub seguros: usize,
}

// Lista de extensões perigosas
pub fn extensoes_perigosas() -> HashMap<&'static str, &'static str> {
    let mut map = HashMap::new();
    map.insert(".exe", "Executável Windows");
    map.insert(".bat", "Script de lote Windows");
    map.insert(".cmd", "Script de comando Windows");
    map.insert(".vbs", "Script Visual Basic");
    map.insert(".ps1", "Script PowerShell");
    map.insert(".msi", "Instalador Windows");
    map.insert(".dll", "Biblioteca de sistema");
    map.insert(".scr", "Protetor de tela / Malware comum");
    map.insert(".jar", "Executável Java");
    map.insert(".sh",  "Script Shell Linux");
    map.insert(".py",  "Script Python");
    map.insert(".js",  "Script JavaScript");
    map.insert(".hta", "Aplicação HTML executável");
    map.insert(".com", "Executável DOS");
    map.insert(".pif", "Arquivo de informação de programa");
    map
}

// Pega a extensão do arquivo
pub fn pegar_extensao(nome: &str) -> String {
    let partes: Vec<&str> = nome.split('.').collect();
    if partes.len() < 2 {
        return String::new();
    }
    format!(".{}", partes.last().unwrap().to_lowercase())
}

// Verifica lista de arquivos
pub fn verificar(arquivos: Vec<String>) -> ExtensaoResponse {
    let extensoes = extensoes_perigosas();
    let resultados: Vec<ResultadoArquivo> = arquivos
        .iter()
        .map(|nome| {
            let extensao = pegar_extensao(nome);
            let perigosa = extensoes.contains_key(extensao.as_str());
            ResultadoArquivo {
                nome: nome.clone(),
                extensao: extensao.clone(),
                perigosa,
                descricao: if perigosa {
                    extensoes[extensao.as_str()].to_string()
                } else {
                    "Extensão segura".to_string()
                },
            }
        })
        .collect();

    let perigosos = resultados.iter().filter(|r| r.perigosa).count();
    let seguros = resultados.iter().filter(|r| !r.perigosa).count();
    let total = resultados.len();

    ExtensaoResponse { resultados, total, perigosos, seguros }
}