# ============================================================
# AMAZON SALES DASHBOARD 2025 — Análise Exploratória (EDA)
# Ferramentas: Python | Pandas | Matplotlib | Seaborn
# Autor: Portfolio Project
# ============================================================

# ── Importações ──────────────────────────────────────────────
import pandas as pd                   # Manipulação e análise de dados tabulares
import numpy as np                    # Operações numéricas e arrays
import matplotlib.pyplot as plt       # Biblioteca base de visualização
import matplotlib.patches as mpatches # Criação de patches (legendas personalizadas)
import matplotlib.gridspec as gridspec # Layout avançado de subplots
import matplotlib.ticker as mticker   # Formatação de eixos
import seaborn as sns                 # Visualizações estatísticas de alto nível
import warnings                       # Suprimir avisos desnecessários
warnings.filterwarnings('ignore')     # Ignora warnings para saída limpa

# ── Paleta de Cores (tema escuro Amazon) ─────────────────────
DARK_BG   = "#0D1117"   # Fundo principal (quase preto)
CARD_BG   = "#161B22"   # Fundo dos cartões / painéis
ORANGE    = "#F0883E"   # Laranja Amazon — cor de destaque principal
BLUE      = "#58A6FF"   # Azul — destaque secundário
GREEN     = "#3FB950"   # Verde — valores positivos / concluídos
RED       = "#FF7B72"   # Vermelho — cancelamentos / alertas
PURPLE    = "#D2A8FF"   # Roxo — pagamentos e extras
GRAY      = "#8B949E"   # Cinza — textos secundários
WHITE     = "#FFFFFF"   # Branco — textos principais
YELLOW    = "#E3B341"   # Amarelo — pendentes
ROW_ALT   = "#1C2128"   # Fundo alternado de tabelas

# Aplica tema escuro globalmente ao matplotlib
plt.rcParams.update({
    "figure.facecolor":  DARK_BG,     # Cor de fundo da figura inteira
    "axes.facecolor":    CARD_BG,     # Cor de fundo de cada gráfico
    "axes.edgecolor":    CARD_BG,     # Cor da borda dos eixos
    "axes.labelcolor":   GRAY,        # Cor dos rótulos dos eixos
    "axes.titlecolor":   WHITE,       # Cor dos títulos dos gráficos
    "axes.titlesize":    13,          # Tamanho dos títulos
    "axes.titleweight":  "bold",      # Peso da fonte dos títulos
    "xtick.color":       GRAY,        # Cor dos ticks do eixo X
    "ytick.color":       GRAY,        # Cor dos ticks do eixo Y
    "xtick.labelsize":   9,           # Tamanho da fonte dos ticks X
    "ytick.labelsize":   9,           # Tamanho da fonte dos ticks Y
    "text.color":        WHITE,       # Cor padrão de textos
    "grid.color":        "#21262D",   # Cor das linhas de grade
    "grid.linewidth":    0.6,         # Espessura das linhas de grade
    "font.family":       "DejaVu Sans",# Fonte padrão
    "legend.facecolor":  CARD_BG,     # Fundo da legenda
    "legend.edgecolor":  GRAY,        # Borda da legenda
    "legend.labelcolor": WHITE,       # Cor do texto da legenda
})

# ── 1. CARREGAMENTO E LIMPEZA DOS DADOS ──────────────────────
print("📦 Carregando dados...")
df = pd.read_csv('amazon_sales_data_2025.csv')

# Converte a coluna Date para datetime (formato dia-mês-ano abreviado)
df['Date'] = pd.to_datetime(df['Date'], format='%d-%m-%y')

# Extrai colunas temporais úteis para análise
df['Month']     = df['Date'].dt.strftime('%b')     # Nome abreviado do mês (Jan, Feb…)
df['MonthNum']  = df['Date'].dt.month              # Número do mês para ordenação
df['Week']      = df['Date'].dt.isocalendar().week # Semana do ano (ISO)
df['DayOfWeek'] = df['Date'].dt.day_name()         # Nome do dia da semana

# Cria coluna de faixa de valor do pedido para segmentação
df['OrderTier'] = pd.cut(
    df['Total Sales'],
    bins=[0, 100, 500, 1500, 10000],                          # Intervalos de corte
    labels=['Baixo (≤$100)', 'Médio ($100–$500)',             # Rótulos das faixas
            'Alto ($500–$1.5K)', 'Premium (>$1.5K)']
)

print(f"✅ {len(df)} pedidos carregados | {df['Date'].min().date()} → {df['Date'].max().date()}")

# ── 2. MÉTRICAS GERAIS (KPIs) ─────────────────────────────────
total_revenue  = df['Total Sales'].sum()              # Receita total bruta
completed_rev  = df[df['Status']=='Completed']['Total Sales'].sum()   # Receita de pedidos concluídos
cancelled_rev  = df[df['Status']=='Cancelled']['Total Sales'].sum()   # Receita perdida por cancelamentos
pending_rev    = df[df['Status']=='Pending']['Total Sales'].sum()     # Receita em aberto
avg_order      = df['Total Sales'].mean()             # Ticket médio por pedido
total_orders   = len(df)                              # Total de pedidos
conversion_rate = (df['Status']=='Completed').mean() * 100  # Taxa de conversão (% concluídos)
cancel_rate    = (df['Status']=='Cancelled').mean() * 100   # Taxa de cancelamento

print(f"\n📊 KPIs Principais:")
print(f"   Receita Total:       $ {total_revenue:,.0f}")
print(f"   Receita Concluída:   $ {completed_rev:,.0f} ({completed_rev/total_revenue*100:.1f}%)")
print(f"   Receita Cancelada:   $ {cancelled_rev:,.0f} ({cancelled_rev/total_revenue*100:.1f}%)")
print(f"   Ticket Médio:        $ {avg_order:,.0f}")
print(f"   Taxa de Conversão:   {conversion_rate:.1f}%")
print(f"   Taxa de Cancelamento:{cancel_rate:.1f}%")

# ── 3. AGREGAÇÕES PARA OS GRÁFICOS ────────────────────────────

# Receita por categoria (ordenada decrescente)
cat_revenue = (df.groupby('Category')['Total Sales']
               .sum()
               .sort_values(ascending=False)
               .reset_index())

# Receita mensal com meses ordenados cronologicamente
monthly = (df.groupby(['MonthNum','Month'])['Total Sales']
           .sum()
           .reset_index()
           .sort_values('MonthNum'))

# Distribuição de pedidos e receita por status
status_counts  = df['Status'].value_counts()                         # Contagem por status
status_revenue = df.groupby('Status')['Total Sales'].sum()           # Receita por status

# Top 10 produtos por receita total
top_products = (df.groupby('Product')['Total Sales']
                .sum()
                .sort_values(ascending=False)
                .head(10))

# Receita por forma de pagamento
payment = (df.groupby('Payment Method')['Total Sales']
           .sum()
           .sort_values(ascending=False))

# Receita por cidade (top 10)
city_rev = (df.groupby('Customer Location')['Total Sales']
            .sum()
            .sort_values(ascending=False)
            .head(10))

# Matriz de correlação — Preço, Quantidade, Total Sales
corr_matrix = df[['Price','Quantity','Total Sales']].corr()

# Tabela cruzada: Categoria × Status (pivot de receita)
pivot_cat_status = pd.pivot_table(
    df, values='Total Sales',
    index='Category', columns='Status',
    aggfunc='sum', fill_value=0
)

# Receita semanal acumulada para linha de tendência
weekly = (df.groupby('Week')['Total Sales']
          .sum()
          .reset_index()
          .sort_values('Week'))
weekly['Cumulative'] = weekly['Total Sales'].cumsum()  # Receita acumulada semana a semana

# ── 4. FIGURA PRINCIPAL — DASHBOARD COMPLETO ─────────────────
print("\n🎨 Gerando Dashboard Principal...")

fig = plt.figure(figsize=(22, 26))       # Tamanho total da figura (largura × altura polegadas)
fig.patch.set_facecolor(DARK_BG)         # Fundo escuro para toda a figura

# Define grid de subplots: 5 linhas × 4 colunas com espaçamentos personalizados
gs = gridspec.GridSpec(
    5, 4,
    figure=fig,
    hspace=0.55,    # Espaço vertical entre subplots
    wspace=0.35,    # Espaço horizontal entre subplots
    top=0.93,       # Margem superior
    bottom=0.04,    # Margem inferior
    left=0.06,      # Margem esquerda
    right=0.97      # Margem direita
)

# ── BANNER DO TÍTULO ─────────────────────────────────────────
ax_title = fig.add_subplot(gs[0, :])     # Ocupa toda a primeira linha (4 colunas)
ax_title.set_facecolor(ORANGE)           # Fundo laranja (cor Amazon)
ax_title.axis('off')                     # Remove eixos — é só decorativo

# Texto principal do banner
ax_title.text(0.5, 0.65, "🛒  AMAZON SALES EXECUTIVE DASHBOARD",
              ha='center', va='center', fontsize=22, fontweight='bold',
              color=WHITE, transform=ax_title.transAxes)
# Subtítulo com métricas resumidas
ax_title.text(0.5, 0.2,
              f"2025  |  250 Pedidos  |  5 Categorias  |  10 Cidades  |  Receita Total: ${total_revenue:,.0f}  |  Conversão: {conversion_rate:.1f}%",
              ha='center', va='center', fontsize=10, color="#FFE4CC",
              transform=ax_title.transAxes)

# ── KPI CARDS (linha 1, colunas 0-3) ─────────────────────────
kpis = [
    # (Valor, Rótulo, Sublabel, Cor de destaque)
    (f"${total_revenue:,.0f}",  "RECEITA TOTAL",         "Bruta 2025",                   ORANGE),
    (f"${completed_rev:,.0f}",  "VENDAS CONCLUÍDAS",     f"{conversion_rate:.1f}% dos pedidos", GREEN),
    (f"${cancelled_rev:,.0f}",  "RECEITA CANCELADA",     f"{cancel_rate:.1f}% dos pedidos",     RED),
    (f"${avg_order:,.0f}",      "TICKET MÉDIO",          f"{total_orders} pedidos totais",       BLUE),
]

for i, (val, label, sub, color) in enumerate(kpis):
    ax_kpi = fig.add_subplot(gs[1, i])   # Uma célula por KPI (linha 1)
    ax_kpi.set_facecolor(CARD_BG)
    ax_kpi.axis('off')

    # Barra de cor no topo do card
    ax_kpi.axhline(y=0.92, xmin=0.08, xmax=0.92, color=color, linewidth=3)

    # Valor principal do KPI (grande e colorido)
    ax_kpi.text(0.5, 0.58, val, ha='center', va='center',
                fontsize=18, fontweight='bold', color=color,
                transform=ax_kpi.transAxes)
    # Rótulo descritivo
    ax_kpi.text(0.5, 0.30, label, ha='center', va='center',
                fontsize=9, fontweight='bold', color=WHITE,
                transform=ax_kpi.transAxes)
    # Sub-rótulo com contexto
    ax_kpi.text(0.5, 0.10, sub, ha='center', va='center',
                fontsize=7.5, color=GRAY,
                transform=ax_kpi.transAxes)

# ── GRÁFICO 1: Barras Horizontais — Receita por Categoria ─────
ax1 = fig.add_subplot(gs[2, :2])        # Linha 2, primeiras 2 colunas
ax1.set_facecolor(CARD_BG)

bar_colors = [ORANGE, BLUE, GREEN, PURPLE, YELLOW]

bars = ax1.barh(
    cat_revenue['Category'],
    cat_revenue['Total Sales'],
    color=bar_colors[:len(cat_revenue)],  # Aplica uma cor por barra
    height=0.6,
    edgecolor='none'
)

for bar, val in zip(bars, cat_revenue['Total Sales']):
    ax1.text(bar.get_width() + 1500,
             bar.get_y() + bar.get_height()/2,
             f"${val:,.0f}",
             va='center', ha='left', fontsize=9, color=WHITE, fontweight='bold')

ax1.set_title("💰 Receita por Categoria", pad=12)
ax1.set_xlabel("Total Sales (USD)", labelpad=8)
ax1.grid(axis='x', alpha=0.3)
ax1.set_xlim(0, cat_revenue['Total Sales'].max() * 1.25)
ax1.tick_params(axis='y', labelsize=10)

# ── GRÁFICO 2: Pizza — Distribuição de Status ─────────────────
ax2 = fig.add_subplot(gs[2, 2])
ax2.set_facecolor(CARD_BG)

status_colors_map = {'Completed': GREEN, 'Cancelled': RED, 'Pending': BLUE}
pie_colors = [status_colors_map[s] for s in status_counts.index]
explode = [0.04] * len(status_counts)

wedges, texts, autotexts = ax2.pie(
    status_counts.values,
    labels=status_counts.index,
    colors=pie_colors,
    autopct='%1.1f%%',
    startangle=90,
    explode=explode,
    wedgeprops=dict(edgecolor=DARK_BG, linewidth=1.5),
    textprops=dict(color=WHITE, fontsize=9)
)

for at in autotexts:
    at.set_fontsize(8)
    at.set_fontweight('bold')
    at.set_color(WHITE)

ax2.set_title("📦 Pedidos por Status", pad=12)

# ── GRÁFICO 3: Linha — Receita Mensal com Pontos ──────────────
ax3 = fig.add_subplot(gs[2, 3])
ax3.set_facecolor(CARD_BG)

ax3.plot(monthly['Month'], monthly['Total Sales'],
         color=BLUE, linewidth=2.5, marker='o',
         markersize=8, markerfacecolor=ORANGE,
         markeredgecolor=WHITE, markeredgewidth=1.5)

ax3.fill_between(monthly['Month'], monthly['Total Sales'], alpha=0.15, color=BLUE)

for _, row in monthly.iterrows():
    ax3.text(row['Month'], row['Total Sales'] + 800,
             f"${row['Total Sales']:,.0f}",
             ha='center', fontsize=8, color=WHITE, fontweight='bold')

ax3.set_title("📅 Receita Mensal", pad=12)
ax3.set_ylabel("USD", labelpad=8)
ax3.grid(axis='y', alpha=0.3)
ax3.set_ylim(0, monthly['Total Sales'].max() * 1.25)

# ── GRÁFICO 4: Barras Verticais — Forma de Pagamento ──────────
ax4 = fig.add_subplot(gs[3, :2])
ax4.set_facecolor(CARD_BG)

pay_colors = [PURPLE, ORANGE, BLUE, GREEN, YELLOW]
bars4 = ax4.bar(payment.index, payment.values,
                color=pay_colors[:len(payment)], width=0.6, edgecolor='none')

for bar, val in zip(bars4, payment.values):
    ax4.text(bar.get_x() + bar.get_width()/2,
             bar.get_height() + 300,
             f"${val:,.0f}",
             ha='center', va='bottom', fontsize=8.5, color=WHITE, fontweight='bold')

ax4.set_title("💳 Receita por Forma de Pagamento", pad=12)
ax4.set_ylabel("USD")
ax4.set_ylim(0, payment.max() * 1.2)
ax4.grid(axis='y', alpha=0.3)
ax4.tick_params(axis='x', rotation=15)

# ── GRÁFICO 5: Barras Agrupadas — Categoria × Status ──────────
ax5 = fig.add_subplot(gs[3, 2:])
ax5.set_facecolor(CARD_BG)

categories = pivot_cat_status.index.tolist()
status_list = pivot_cat_status.columns.tolist()
n_status = len(status_list)
x = np.arange(len(categories))
width = 0.25

status_colors_bar = {'Completed': GREEN, 'Cancelled': RED, 'Pending': BLUE}

for i, status in enumerate(status_list):
    offset = (i - n_status/2 + 0.5) * width     # Deslocamento lateral por status
    ax5.bar(x + offset,
            pivot_cat_status[status].values,
            width=width, label=status,
            color=status_colors_bar.get(status, GRAY),
            edgecolor='none')

ax5.set_title("📊 Categoria × Status", pad=12)
ax5.set_ylabel("Receita (USD)")
ax5.set_xticks(x)
ax5.set_xticklabels(categories, rotation=15, ha='right', fontsize=8)
ax5.legend(loc='upper right', fontsize=8)
ax5.grid(axis='y', alpha=0.3)

# ── GRÁFICO 6: Barras Horizontais — Top Produtos ─────────────
ax6 = fig.add_subplot(gs[4, :2])
ax6.set_facecolor(CARD_BG)

n_prod = len(top_products)
prod_colors = [plt.cm.Oranges(0.4 + 0.6 * i/n_prod) for i in range(n_prod)]  # Gradiente

bars6 = ax6.barh(top_products.index, top_products.values,
                 color=prod_colors, height=0.6, edgecolor='none')

for bar, val in zip(bars6, top_products.values):
    ax6.text(bar.get_width() + 200, bar.get_y() + bar.get_height()/2,
             f"${val:,.0f}", va='center', ha='left', fontsize=8.5,
             color=WHITE, fontweight='bold')

ax6.set_title("🏆 Top Produtos por Receita", pad=12)
ax6.set_xlabel("USD")
ax6.set_xlim(0, top_products.max() * 1.25)
ax6.grid(axis='x', alpha=0.3)

# ── GRÁFICO 7: Barras — Top 10 Cidades ───────────────────────
ax7 = fig.add_subplot(gs[4, 2:])
ax7.set_facecolor(CARD_BG)

city_colors = [BLUE if i == 0 else PURPLE for i in range(len(city_rev))]  # Destaca o 1º

bars7 = ax7.bar(city_rev.index, city_rev.values,
                color=city_colors, width=0.6, edgecolor='none')

for bar, val in zip(bars7, city_rev.values):
    ax7.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 150,
             f"${val:,.0f}", ha='center', va='bottom',
             fontsize=7.5, color=WHITE, fontweight='bold')

ax7.set_title("🌎 Receita por Cidade (Top 10)", pad=12)
ax7.set_ylabel("USD")
ax7.tick_params(axis='x', rotation=35)
ax7.set_ylim(0, city_rev.max() * 1.2)
ax7.grid(axis='y', alpha=0.3)

# ── RODAPÉ ────────────────────────────────────────────────────
fig.text(0.5, 0.01,
         "Amazon Sales Analysis 2025  |  Python: Pandas + Matplotlib + Seaborn  |  Portfolio Project",
         ha='center', fontsize=8.5, color=GRAY, style='italic')

plt.savefig("amazon_dashboard_python.png", dpi=160, bbox_inches='tight',
            facecolor=DARK_BG, edgecolor='none')
plt.close()
print("✅ Dashboard principal salvo!")

# ═══════════════════════════════════════════════════════════════
# 5. FIGURA SECUNDÁRIA — ANÁLISE AVANÇADA
# ═══════════════════════════════════════════════════════════════
print("\n🔬 Gerando Análise Avançada...")

fig2, axes = plt.subplots(2, 3, figsize=(20, 12))
fig2.patch.set_facecolor(DARK_BG)
fig2.suptitle("AMAZON SALES — ANÁLISE AVANÇADA 2025",
              fontsize=16, fontweight='bold', color=WHITE, y=0.98)

# ── A1: Receita Acumulada Semanal ─────────────────────────────
ax_a1 = axes[0][0]
ax_a1.set_facecolor(CARD_BG)

ax_a1.fill_between(weekly['Week'], weekly['Cumulative'], color=GREEN, alpha=0.3)
ax_a1.plot(weekly['Week'], weekly['Cumulative'],
           color=GREEN, linewidth=2.5, marker='o', markersize=5, markerfacecolor=WHITE)
ax_a1.set_title("📈 Receita Acumulada por Semana")
ax_a1.set_xlabel("Semana do Ano"); ax_a1.set_ylabel("USD Acumulado")
ax_a1.grid(alpha=0.3)
ax_a1.annotate(f"Total:\n${weekly['Cumulative'].iloc[-1]:,.0f}",
               xy=(weekly['Week'].iloc[-1], weekly['Cumulative'].iloc[-1]),
               xytext=(-50, -40), textcoords='offset points',
               color=GREEN, fontsize=9, fontweight='bold',
               arrowprops=dict(arrowstyle='->', color=GREEN))

# ── A2: Heatmap — Correlação ──────────────────────────────────
ax_a2 = axes[0][1]
ax_a2.set_facecolor(CARD_BG)

sns.heatmap(
    corr_matrix, ax=ax_a2,
    annot=True,                  # Exibe os valores numéricos dentro das células
    fmt=".2f",
    cmap='YlOrRd',               # Paleta amarelo → laranja → vermelho
    linewidths=1, linecolor=DARK_BG,
    annot_kws={'size': 11, 'color': WHITE},
    cbar_kws={'label': 'Correlação'}
)
ax_a2.set_title("🔥 Mapa de Correlação")
ax_a2.tick_params(colors=WHITE, labelsize=9)

# ── A3: Histograma + KDE — Distribuição de Pedidos ───────────
ax_a3 = axes[0][2]
ax_a3.set_facecolor(CARD_BG)

sns.histplot(df['Total Sales'], kde=True, ax=ax_a3,
             color=ORANGE, bins=20,
             line_kws={'linewidth': 2, 'color': WHITE})  # KDE em branco sobre histograma
ax_a3.set_title("📊 Distribuição dos Pedidos (USD)")
ax_a3.set_xlabel("Total Sales"); ax_a3.set_ylabel("Frequência")
ax_a3.grid(alpha=0.3)
ax_a3.axvline(avg_order, color=BLUE, linestyle='--', linewidth=1.8,
              label=f"Média: ${avg_order:,.0f}")
ax_a3.legend()

# ── A4: Box Plot — Dispersão por Categoria ────────────────────
ax_a4 = axes[1][0]
ax_a4.set_facecolor(CARD_BG)

cat_order = (df.groupby('Category')['Total Sales']
             .median().sort_values(ascending=False).index.tolist())

sns.boxplot(
    data=df, x='Category', y='Total Sales',
    order=cat_order,
    palette=[ORANGE, BLUE, GREEN, PURPLE, YELLOW],
    ax=ax_a4, linewidth=1.2,
    flierprops=dict(marker='o', markerfacecolor=GRAY, markersize=4)  # Estilo dos outliers
)
ax_a4.set_title("📦 Dispersão por Categoria (Box Plot)")
ax_a4.set_xlabel(""); ax_a4.set_ylabel("Total Sales (USD)")
ax_a4.tick_params(axis='x', rotation=20, labelsize=8)
ax_a4.grid(axis='y', alpha=0.3)

# ── A5: Violin Plot — Distribuição por Status ─────────────────
ax_a5 = axes[1][1]
ax_a5.set_facecolor(CARD_BG)

# Violin plot mostra a forma completa da distribuição (mais rico que boxplot)
sns.violinplot(
    data=df, x='Status', y='Total Sales',
    order=['Completed','Pending','Cancelled'],
    palette=[GREEN, BLUE, RED],
    ax=ax_a5, inner='box', linewidth=1.2   # 'box' exibe miniboxplot interno
)
ax_a5.set_title("🎻 Distribuição por Status (Violin)")
ax_a5.set_xlabel(""); ax_a5.set_ylabel("USD")
ax_a5.grid(axis='y', alpha=0.3)

# ── A6: Scatter Plot — Quantidade × Receita por Categoria ─────
ax_a6 = axes[1][2]
ax_a6.set_facecolor(CARD_BG)

cat_palette = {
    'Electronics':     ORANGE,
    'Home Appliances': BLUE,
    'Footwear':        GREEN,
    'Clothing':        PURPLE,
    'Books':           YELLOW
}

for cat, color in cat_palette.items():
    subset = df[df['Category'] == cat]       # Filtra a categoria atual
    ax_a6.scatter(subset['Quantity'], subset['Total Sales'],
                  color=color, alpha=0.65, s=50, label=cat, edgecolors='none')

# Linha de tendência linear (regressão com numpy polyfit grau 1)
z = np.polyfit(df['Quantity'], df['Total Sales'], 1)
p = np.poly1d(z)
x_line = np.linspace(df['Quantity'].min(), df['Quantity'].max(), 100)
ax_a6.plot(x_line, p(x_line), color=WHITE, linewidth=1.5,
           linestyle='--', label='Tendência', alpha=0.6)

ax_a6.set_title("🔵 Qtd. × Receita por Categoria (Scatter)")
ax_a6.set_xlabel("Quantidade"); ax_a6.set_ylabel("Total Sales (USD)")
ax_a6.legend(fontsize=7.5, loc='upper left')
ax_a6.grid(alpha=0.3)

plt.tight_layout(rect=[0, 0, 1, 0.97])

plt.savefig("amazon_analise_avancada_python.png", dpi=160, bbox_inches='tight',
            facecolor=DARK_BG, edgecolor='none')
plt.close()
print("✅ Análise avançada salva!")
print("\n🚀 Análise Python completa!")
