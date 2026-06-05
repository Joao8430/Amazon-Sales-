# 📊 Amazon Sales Dashboard 2025

<div align="center">

![Python](https://img.shields.io/badge/Python-3.11-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Pandas](https://img.shields.io/badge/Pandas-2.0-150458?style=for-the-badge&logo=pandas&logoColor=white)
![Matplotlib](https://img.shields.io/badge/Matplotlib-3.8-11557C?style=for-the-badge)
![Seaborn](https://img.shields.io/badge/Seaborn-0.13-4C72B0?style=for-the-badge)
![Power BI](https://img.shields.io/badge/Power_BI-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![SQL](https://img.shields.io/badge/SQL-Analytics-CC2927?style=for-the-badge&logo=microsoftsqlserver&logoColor=white)
![Excel](https://img.shields.io/badge/Excel-Dashboard-217346?style=for-the-badge&logo=microsoftexcel&logoColor=white)

**End-to-end sales analytics pipeline — from raw data to executive-grade insights.**

</div>

---

## 🎯 Visão Geral do Projeto

Este projeto simula um pipeline completo de análise de dados de vendas da Amazon, cobrindo desde a ingestão e limpeza de dados até a entrega de dashboards executivos prontos para tomada de decisão. Desenvolvido como projeto de portfólio para demonstrar domínio em SQL, Python e ferramentas de BI.

**Dataset:** 250 pedidos | 5 categorias | 10 cidades | Receita total: **$243.845**

---

## 🗂️ Estrutura do Projeto

```
amazon-sales-dashboard-2025/
│
├── 📄 amazon_sales_analysis.sql       # Queries SQL para análise exploratória
├── 🐍 amazon_sales_analysis.py        # Pipeline Python completo (EDA + visualizações)
├── 📊 Amazon_Sales_Dashboard_2025.xlsx # Dashboard interativo no Excel
├── 📈 Dashboard_Executivo_Amazon.pbix  # Relatório Power BI
│
├── outputs/
│   ├── amazon_dashboard_python.png     # Executive Dashboard (Matplotlib + Seaborn)
│   └── amazon_analise_avancada_python.png  # Análise Avançada (Correlações, Box Plot, Violin)
│
└── README.md
```

---

## 🧱 Stack Tecnológica

| Camada | Tecnologia | Finalidade |
|---|---|---|
| **Dados** | Excel / CSV | Fonte de dados estruturada |
| **SQL** | SQL Analytics | Queries de agregação e segmentação |
| **Python** | Pandas + Matplotlib + Seaborn | EDA, KPIs e visualizações |
| **BI** | Power BI | Dashboard executivo interativo |
| **Office** | Excel | Dashboard acessível sem ferramentas extras |

---

## 📐 Metodologia

### 1. SQL — Fundação Analítica
Queries para responder as perguntas de negócio:
- Receita por categoria, cidade e forma de pagamento
- Taxa de conversão por status de pedido
- Ranking de produtos por receita
- Análise de sazonalidade mensal

### 2. Python — EDA + Visualizações Avançadas
**Executive Dashboard (`amazon_dashboard_python.png`):**
- KPIs consolidados (receita total, conversão, ticket médio)
- Receita por categoria e top produtos
- Distribuição de pedidos por status
- Análise geográfica por cidade
- Receita por forma de pagamento

**Análise Avançada (`amazon_analise_avancada_python.png`):**
- Receita acumulada por semana (curva de crescimento)
- Mapa de correlação (Price × Quantity × Total Sales)
- Distribuição dos pedidos com curva KDE
- Box Plot por categoria
- Violin Plot por status do pedido
- Scatter Plot: Quantidade × Receita por categoria

### 3. Power BI — Dashboard Executivo Interativo
- Filtros dinâmicos por período, categoria e cidade
- Drill-down por produto e região
- Metas e indicadores de performance

---

## 📊 Principais Insights

> **"Eletrônicos e Eletrodomésticos representam 96% da receita — mas a taxa de cancelamento de 30,8% aponta para uma oportunidade de otimização no funil de vendas."**

| Métrica | Valor |
|---|---|
| 💰 Receita Total | $243.845 |
| ✅ Vendas Concluídas | $88.530 (35,2%) |
| ❌ Receita Cancelada | $65.030 (30,8%) |
| 🎯 Ticket Médio | $975 |
| 🏆 Categoria #1 | Electronics — $129.950 |
| 🏙️ Cidade #1 | Miami — $31.700 |
| 💳 Pagamento #1 | PayPal — $69.645 |

---

## 🚀 Como Executar

### Pré-requisitos
```bash
pip install pandas matplotlib seaborn numpy openpyxl
```

### Rodando a análise Python
```bash
python amazon_sales_analysis.py
```

Os dashboards serão gerados automaticamente na pasta `outputs/`.

### SQL
Execute as queries em `amazon_sales_analysis.sql` em qualquer ambiente compatível (PostgreSQL, MySQL, SQLite, BigQuery).

---

## 🖼️ Previews

### Executive Dashboard
![Executive Dashboard](outputs/amazon_dashboard_python.png)

### Análise Avançada
![Análise Avançada](outputs/amazon_analise_avancada_python.png)

---

## 💡 Habilidades Demonstradas

- ✅ **Análise Exploratória de Dados (EDA)** com Python
- ✅ **SQL** para consultas analíticas e agregações
- ✅ **Visualização de dados** com Matplotlib e Seaborn
- ✅ **Design de dashboards executivos** (dark theme, layout profissional)
- ✅ **Storytelling com dados** — transformar números em decisões
- ✅ **Power BI** — construção de relatórios interativos
- ✅ **Excel** — dashboards acessíveis para stakeholders

---

## 👤 Autor

Desenvolvido como projeto de portfólio em análise de dados.

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0A66C2?style=for-the-badge&logo=linkedin)](https://linkedin.com)
[![GitHub](https://img.shields.io/badge/GitHub-Follow-181717?style=for-the-badge&logo=github)](https://github.com)

---

<div align="center">
  <sub>Amazon Sales Analysis 2025 · Python · SQL · Power BI · Portfolio Project</sub>
</div>
