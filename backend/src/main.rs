use actix_web::{post, web, App, HttpServer, HttpResponse};
use actix_cors::Cors;
use serde::Deserialize;
use firestore::*;

mod hash;
mod url;
mod extensao;
mod yara_scanner;
mod monitor;

#[actix_web::get("/monitor/info")]
async fn monitor_info() -> HttpResponse {
    let info = monitor::coletar_info();
    HttpResponse::Ok().json(info)
}



#[derive(Deserialize)]
struct YaraRequest {
    bytes: Vec<u8>,
    nome: String,
}

// Rota Hash Scanner
#[post("/hash/scan")]
async fn hash_scan(body: web::Json<hash::HashRequest>) -> HttpResponse {
    println!("📝 Gerando hash para o arquivo: {}", body.nome); // Agora o Rust fica feliz!
    let hash = hash::gerar_hash(&body.bytes);
    let resultado = hash::verificar(&hash);
    HttpResponse::Ok().json(resultado)
}

// Rota Verificador de URL
#[post("/url/verificar")]
async fn url_verificar(body: web::Json<url::UrlRequest>) -> HttpResponse {
    println!("📝 Verificando URL: {}", body.url);
    let resultado = url::verificar(&body.url);
    HttpResponse::Ok().json(resultado)
}

pub async fn salvar_deteccao(hash: String, ameaca: bool) -> Result<(), Box<dyn std::error::Error>> {
    // Inicializa o cliente usando a variável de ambiente com o caminho do JSON
    let db = FirestoreDb::new("id-do-seu-projeto").await?;

    let log = serde_json::json!({
        "hash": hash,
        "ameaca": ameaca,
        "timestamp": chrono::Utc::now().to_rfc3339(),
    });

    // Salva na coleção "logs_seguranca"
    db.fluent()
        .select_all()
        .from("logs_seguranca")
        .add(log)
        .await?;

    Ok(())
}

// Rota Verificador de Extensões
#[post("/extensao/verificar")]
async fn extensao_verificar(body: web::Json<extensao::ExtensaoRequest>) -> HttpResponse {
    let resultado = extensao::verificar(body.arquivos.clone());
    HttpResponse::Ok().json(resultado)
}

// Rota YARA Scanner
#[post("/yara/scan")]
async fn yara_scan(body: web::Json<YaraRequest>) -> HttpResponse {
    println!("🔍 YARA scan: {}", body.nome);
    let resultado = yara_scanner::escanear(&body.bytes);
    HttpResponse::Ok().json(resultado)
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    println!("🦀 Backend Rust rodando em http://127.0.0.1:8080");
    println!("📋 Rotas disponíveis:");
    println!("   POST /hash/scan");
    println!("   POST /url/verificar");
    println!("   POST /extensao/verificar");
    println!("   POST /yara/scan");

    HttpServer::new(|| {
        let cors = Cors::default()
            .allow_any_origin()
            .allow_any_method()
            .allow_any_header();

        App::new()
            .wrap(cors)
            .service(hash_scan)
            .service(url_verificar)
            .service(extensao_verificar)
            .service(yara_scan)
            .service(monitor_info)
    })
    .bind("127.0.0.1:8080")?
    .run()
    .await
}