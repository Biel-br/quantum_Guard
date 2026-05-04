import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../controller/monitor_controller.dart';

class MonitorView extends StatefulWidget {
  const MonitorView({super.key});

  @override
  State<MonitorView> createState() => _MonitorViewState();
}

class _MonitorViewState extends State<MonitorView> {
  final ctrl = GetIt.I.get<MonitorController>();

  @override
  void initState() {
    super.initState();
    ctrl.addListener(() => setState(() {}));
    ctrl.iniciar();
  }

  @override
  void dispose() {
    ctrl.parar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitor do Sistema', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Atualização manual
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Atualizar',
            onPressed: ctrl.buscarInfo,
          ),
        ],
      ),
      body: ctrl.carregando && ctrl.info == null
        ? const Center(child: CircularProgressIndicator())
        : ctrl.info == null
          ? _buildOffline()
          : _buildConteudo(),
    );
  }

  // Tela offline
  Widget _buildOffline() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'Backend offline',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Inicie o servidor Rust para\nvisualizar o monitor',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Conteúdo principal
  Widget _buildConteudo() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [

        // Info do sistema
        _buildSecao(
          titulo: '💻 Sistema',
          filho: _buildInfoSistema(),
        ),

        const SizedBox(height: 16),

        // Memória
        _buildSecao(
          titulo: '🧠 Memória',
          filho: _buildMemoria(),
        ),

        const SizedBox(height: 16),

        // CPUs
        _buildSecao(
          titulo: '⚙️ Processador',
          filho: _buildCpu(),
        ),

        const SizedBox(height: 16),

        // Processos
        _buildSecao(
          titulo: '📋 Top Processos (por memória)',
          filho: _buildProcessos(),
        ),

        const SizedBox(height: 16),

        // Discos
        if (ctrl.discos.isNotEmpty)
          _buildSecao(
            titulo: '💾 Discos',
            filho: _buildDiscos(),
          ),

        const SizedBox(height: 16),

        // Redes
        if (ctrl.redes.isNotEmpty)
          _buildSecao(
            titulo: '🌐 Interfaces de Rede',
            filho: _buildRedes(),
          ),
      ],
    );
  }

  // Card de seção
  Widget _buildSecao({required String titulo, required Widget filho}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 20),
            filho,
          ],
        ),
      ),
    );
  }

  // Info do sistema
  Widget _buildInfoSistema() {
    return Column(
      children: [
        _buildLinha('Sistema', ctrl.nomeOS),
        _buildLinha('Versão', ctrl.versaoOS),
        _buildLinha('Hostname', ctrl.hostname),
        _buildLinha('CPUs', '${ctrl.totalCpus} núcleos'),
        _buildLinha('Processos', '${ctrl.totalProcessos} rodando'),
        _buildLinha(
          'Suspeitos',
          '${ctrl.processosSuspeitos} encontrados',
          cor: ctrl.processosSuspeitos > 0 ? Colors.red : Colors.green,
        ),
      ],
    );
  }

  // Memória
  Widget _buildMemoria() {
    final uso = ctrl.usoMemoria;
    final cor = uso > 80 ? Colors.red : uso > 60 ? Colors.orange : Colors.blue;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${ctrl.memoriaUsada.toStringAsFixed(1)} GB usados',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'de ${ctrl.memoriaTotal.toStringAsFixed(1)} GB',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: uso / 100,
            minHeight: 16,
            backgroundColor: cor.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(cor),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${uso.toStringAsFixed(1)}% em uso',
            style: TextStyle(color: cor, fontSize: 12),
          ),
        ),
      ],
    );
  }

  // CPU
  Widget _buildCpu() {
    return _buildLinha('Total de núcleos', '${ctrl.totalCpus} CPUs');
  }

  // Processos
  Widget _buildProcessos() {
    if (ctrl.processos.isEmpty) {
      return const Text('Nenhum processo encontrado');
    }

    return Column(
      children: ctrl.processos.map<Widget>((p) {
        final suspeito = p['suspeito'] ?? false;
        final cor = suspeito ? Colors.red : Colors.black87;

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: suspeito ? Colors.red.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: suspeito ? Colors.red.shade200 : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                suspeito ? Icons.warning_amber : Icons.memory,
                size: 16,
                color: suspeito ? Colors.red : Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p['nome'] ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: cor,
                        fontSize: 13,
                      ),
                    ),
                    if (suspeito && p['motivo'] != null)
                      Text(
                        p['motivo'],
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(p['memoria_mb'] ?? 0.0).toStringAsFixed(0)} MB',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'PID: ${p['pid']}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Discos
  Widget _buildDiscos() {
    return Column(
      children: ctrl.discos.map<Widget>((d) {
        final uso = (d['uso_percent'] ?? 0.0).toDouble();
        final cor = uso > 90
          ? Colors.red
          : uso > 70
            ? Colors.orange
            : Colors.blue;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.storage, size: 16, color: cor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      d['nome'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    '${(d['disponivel_gb'] ?? 0.0).toStringAsFixed(1)} GB livre '
                    'de ${(d['total_gb'] ?? 0.0).toStringAsFixed(1)} GB',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: uso / 100,
                  minHeight: 10,
                  backgroundColor: cor.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation(cor),
                ),
              ),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${uso.toStringAsFixed(1)}% usado',
                  style: TextStyle(fontSize: 11, color: cor),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Redes
  Widget _buildRedes() {
    return Column(
      children: ctrl.redes.map<Widget>((r) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Row(
            children: [
              Icon(Icons.wifi, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  r['interface'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '⬇ ${(r['recebido_mb'] ?? 0.0).toStringAsFixed(1)} MB',
                    style: const TextStyle(fontSize: 12, color: Colors.green),
                  ),
                  Text(
                    '⬆ ${(r['transmitido_mb'] ?? 0.0).toStringAsFixed(1)} MB',
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Linha de informação
  Widget _buildLinha(String label, String valor, {Color? cor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: cor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}