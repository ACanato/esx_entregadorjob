# 🚚 Trabalho de Entregas (v1.0)

Este script introduz um sistema de trabalho de entregador totalmente funcional para servidores ESX. É exclusivo para jogadores que tenham o emprego de entregador

---

## 📌 Funcionalidades Principais

### 🔑 Gestão de Veículos de Entrega
- O jogador inicia o turno retirando um veículo de entregas.
- Ao completar as encomendas, deve devolver o veículo no ponto de partida para terminar o turno.

### 💰 Sistema de Recompensas Gratificante
- Os pagamentos são atribuídos com base no número de entregas bem-sucedidas.
- O jogador recebe o total no final do turno, ao devolver o veículo de trabalho.

### 📦 Interatividade Dinâmica nas Entregas
- Cada ponto de entrega exige que o jogador vá até à bagageira da carrinha.
- Uma animação é reproduzida ao retirar a caixa.
- Só depois o jogador poderá entregar a encomenda no local designado.

---

## 🛠️ Requisitos
- **ESX Framework**
- es_extended 1.1
- Base de dados MySQL

---

## 📂 Instalação

1. Coloca a pasta do script em `resources/`.
2. Adiciona ao `server.cfg`:
   ```bash
   ensure esx_entregadorjob
