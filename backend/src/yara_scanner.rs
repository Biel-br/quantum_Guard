use serde::Serialize;
use std::fs;
use yara_x::Compiler;

#[derive(Serialize, Clone)]
pub struct YaraMatch {
    pub regra: String,
    pub descricao: String,
    pub severidade: String,
}

#[derive(Serialize)]
pub struct YaraResponse {
    pub ameaca: bool,
    pub matches: Vec<YaraMatch>,
    pub status: String,
    pub total_matches: usize,
}

// Carrega e compila todas as regras .yar da pasta regras/
pub fn carregar_regras() -> Result<yara_x::Rules, String> {
    let mut compiler = Compiler::new();

    let regras_dir = "regras";
    let entradas = fs::read_dir(regras_dir)
        .map_err(|e| format!("Erro ao ler pasta de regras: {}", e))?;

    for entrada in entradas {
        let entrada = entrada.map_err(|e| e.to_string())?;
        let caminho = entrada.path();

        if caminho.extension().and_then(|e| e.to_str()) == Some("yar") {
            let conteudo = fs::read_to_string(&caminho)
                .map_err(|e| format!("Erro ao ler {:?}: {}", caminho, e))?;

            compiler
                .add_source(conteudo.as_str())
                .map_err(|e| format!("Erro ao compilar regra: {}", e))?;

            println!("✅ Regra carregada: {:?}", caminho);
        }
    }

    // CORREÇÃO 1: O build() do yara-x não retorna Result, ele retorna Rules diretamente.
    Ok(compiler.build())
}

// Escaneia bytes com as regras YARA
pub fn escanear(bytes: &[u8]) -> YaraResponse {
    let rules = match carregar_regras() {
        Ok(r) => r,
        Err(e) => {
            return YaraResponse {
                ameaca: false,
                matches: vec![],
                status: format!("Erro ao carregar regras: {}", e),
                total_matches: 0,
            }
        }
    };

    let mut scanner = yara_x::Scanner::new(&rules);
    let resultados = match scanner.scan(bytes) {
        Ok(r) => r,
        Err(e) => {
            return YaraResponse {
                ameaca: false,
                matches: vec![],
                status: format!("Erro ao escanear: {}", e),
                total_matches: 0,
            }
        }
    };

    let matches: Vec<YaraMatch> = resultados
        .matching_rules()
        .map(|regra| {
            // Em vez de tentar clonar, acessamos os metadados para cada campo
            
            // 1. Buscar Descrição
            let descricao = regra.metadata()
                .find(|(k, _)| *k == "description")
                .and_then(|(_, v)| {
                    if let yara_x::MetaValue::String(s) = v {
                        Some(s.to_string())
                    } else {
                        None
                    }
                })
                .unwrap_or_else(|| "Sem descrição".to_string());

            // 2. Buscar Severidade (chamamos regra.metadata() de novo, sem erro de ownership)
            let severidade = regra.metadata()
                .find(|(k, _)| *k == "severidade")
                .and_then(|(_, v)| {
                    if let yara_x::MetaValue::String(s) = v {
                        Some(s.to_string())
                    } else {
                        None
                    }
                })
                .unwrap_or_else(|| "desconhecida".to_string());

            YaraMatch {
                regra: regra.identifier().to_string(),
                descricao,
                severidade,
            }
        })
        .collect();

    let total = matches.len();
    let ameaca = total > 0;

    YaraResponse {
        ameaca,
        matches,
        status: if ameaca {
            "⚠️ Ameaças detectadas pelas regras YARA!".to_string()
        } else {
            "✅ Nenhuma ameaça detectada".to_string()
        },
        total_matches: total,
    }
}