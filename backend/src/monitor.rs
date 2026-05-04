use serde::Serialize;
use sysinfo::{Components, Disks, Networks, System};

#[derive(Serialize)]
pub struct ProcessoInfo {
    pub pid: u32,
    pub nome: String,
    pub memoria_mb: f64,
    pub cpu_percent: f32,
    pub suspeito: bool,
    pub motivo: Option<String>,
}

#[derive(Serialize)]
pub struct DiscoInfo {
    pub nome: String,
    pub total_gb: f64,
    pub disponivel_gb: f64,
    pub uso_percent: f64,
}

#[derive(Serialize)]
pub struct RedeInfo {
    pub interface: String,
    pub recebido_mb: f64,
    pub transmitido_mb: f64,
}

#[derive(Serialize)]
pub struct ComponenteInfo {
    pub nome: String,
    pub temperatura: f32,
}

#[derive(Serialize)]
pub struct SistemaInfo {
    pub nome: String,
    pub versao_os: String,
    pub versao_kernel: String,
    pub hostname: String,
    pub total_memoria_gb: f64,
    pub memoria_usada_gb: f64,
    pub uso_memoria_percent: f64,
    pub total_swap_gb: f64,
    pub swap_usado_gb: f64,
    pub total_cpus: usize,
    pub total_processos: usize,
    pub processos_suspeitos: usize,
    pub processos: Vec<ProcessoInfo>,
    pub discos: Vec<DiscoInfo>,
    pub redes: Vec<RedeInfo>,
    pub componentes: Vec<ComponenteInfo>,
}

// Lista de processos conhecidos como suspeitos
fn processos_suspeitos() -> Vec<&'static str> {
    vec![
        "miner", "xmrig", "cryptonight",
        "keylogger", "backdoor", "netcat",
        "wireshark", "nmap", "metasploit",
        "mimikatz", "hashcat", "john",
    ]
}

// Verifica se o processo é suspeito
fn verificar_processo(nome: &str) -> (bool, Option<String>) {
    let nome_lower = nome.to_lowercase();
    let suspeitos = processos_suspeitos();

    for suspeito in suspeitos {
        if nome_lower.contains(suspeito) {
            return (true, Some(format!("Processo suspeito: {}", suspeito)));
        }
    }
    (false, None)
}

pub fn coletar_info() -> SistemaInfo {
    let mut sys = System::new_all();
    sys.refresh_all();

    // Processos
    let mut processos: Vec<ProcessoInfo> = sys
        .processes()
        .iter()
        .map(|(pid, process)| {
            let nome = process.name().to_string_lossy().to_string();
            let (suspeito, motivo) = verificar_processo(&nome);
            ProcessoInfo {
                pid: pid.as_u32(),
                nome,
                memoria_mb: process.memory() as f64 / 1024.0 / 1024.0,
                cpu_percent: process.cpu_usage(),
                suspeito,
                motivo,
            }
        })
        .collect();

    // Ordena por uso de memória
    processos.sort_by(|a, b| b.memoria_mb.partial_cmp(&a.memoria_mb).unwrap());

    // Pega top 20 processos
    let processos: Vec<ProcessoInfo> = processos.into_iter().take(20).collect();
    let processos_suspeitos = processos.iter().filter(|p| p.suspeito).count();

    // Memória
    let total_mem = sys.total_memory() as f64 / 1024.0 / 1024.0 / 1024.0;
    let usada_mem = sys.used_memory() as f64 / 1024.0 / 1024.0 / 1024.0;
    let uso_mem = (usada_mem / total_mem) * 100.0;

    // Swap
    let total_swap = sys.total_swap() as f64 / 1024.0 / 1024.0 / 1024.0;
    let usado_swap = sys.used_swap() as f64 / 1024.0 / 1024.0 / 1024.0;

    // Discos
    let discos_info = Disks::new_with_refreshed_list();
    let discos: Vec<DiscoInfo> = discos_info
        .iter()
        .map(|disk| {
            let total = disk.total_space() as f64 / 1024.0 / 1024.0 / 1024.0;
            let disponivel = disk.available_space() as f64 / 1024.0 / 1024.0 / 1024.0;
            let uso = ((total - disponivel) / total) * 100.0;
            DiscoInfo {
                nome: disk.name().to_string_lossy().to_string(),
                total_gb: total,
                disponivel_gb: disponivel,
                uso_percent: uso,
            }
        })
        .collect();

    // Redes
    let redes_info = Networks::new_with_refreshed_list();
    let redes: Vec<RedeInfo> = redes_info
        .iter()
        .map(|(nome, data)| RedeInfo {
            interface: nome.clone(),
            recebido_mb: data.total_received() as f64 / 1024.0 / 1024.0,
            transmitido_mb: data.total_transmitted() as f64 / 1024.0 / 1024.0,
        })
        .collect();

    // Componentes (temperatura)
let componentes_info = Components::new_with_refreshed_list();


        let componentes: Vec<ComponenteInfo> = componentes_info
        .iter()
        .map(|c| ComponenteInfo {
            nome: c.label().to_string(),
          temperatura: c.temperature().unwrap_or(0.0),
        })
        .collect();

    SistemaInfo {
        nome: System::name().unwrap_or_default(),
        versao_os: System::os_version().unwrap_or_default(),
        versao_kernel: System::kernel_version().unwrap_or_default(),
        hostname: System::host_name().unwrap_or_default(),
        total_memoria_gb: total_mem,
        memoria_usada_gb: usada_mem,
        uso_memoria_percent: uso_mem,
        total_swap_gb: total_swap,
        swap_usado_gb: usado_swap,
        total_cpus: sys.cpus().len(),
        total_processos: sys.processes().len(),
        processos_suspeitos,
        processos,
        discos,
        redes,
        componentes,
    }
}