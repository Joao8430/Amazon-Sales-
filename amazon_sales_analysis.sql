-- ============================================================
-- AMAZON SALES DASHBOARD 2025 — SQL ANALYTICS PORTFOLIO
-- Engine   : DuckDB (compatível com PostgreSQL e BigQuery)
-- Dataset  : amazon_sales_data_2025.csv  (250 pedidos)
-- Módulos  : 10 queries progressivas
--            1. KPIs Executivos
--            2. Análise por Categoria
--            3. Análise Temporal Mensal (MoM)
--            4. Ranking de Produtos (Window Functions)
--            5. Segmentação RFM de Clientes
--            6. Análise por Forma de Pagamento
--            7. Análise Geográfica por Cidade
--            8. Detecção de Anomalias (Z-Score)
--            9. Cohort de Clientes
--           10. View Executiva Consolidada
-- ============================================================


-- ============================================================
-- SETUP: CRIAÇÃO DA TABELA (DuckDB — lê direto do CSV)
-- Objetivo : Criar a tabela com tipos corretos a partir do CSV
-- Técnicas : CAST, strptime para parsing de data customizado
-- ============================================================

CREATE TABLE IF NOT EXISTS sales AS
SELECT
    "Order ID"                          AS order_id,       -- Identificador único do pedido
    strptime("Date", '%d-%m-%y')::DATE  AS order_date,     -- Converte string DD-MM-YY para DATE
    Product                             AS product,        -- Nome do produto
    Category                            AS category,       -- Categoria do produto
    CAST("Price" AS INTEGER)            AS price,          -- Preço unitário (cast de string para int)
    CAST("Quantity" AS INTEGER)         AS quantity,       -- Quantidade comprada
    CAST("Total Sales" AS INTEGER)      AS total_sales,    -- Receita do pedido (price × quantity)
    "Customer Name"                     AS customer_name,  -- Nome do cliente
    "Customer Location"                 AS city,           -- Cidade do cliente
    "Payment Method"                    AS payment_method, -- Forma de pagamento
    Status                              AS status          -- Status: Completed | Cancelled | Pending
FROM read_csv('amazon_sales_data_2025.csv', all_varchar=true);
-- Nota: all_varchar=true lê tudo como texto; os CASTs acima fazem a conversão segura


-- ════════════════════════════════════════════════════════════════
-- QUERY 1 | KPIs EXECUTIVOS
-- Objetivo : Painel de métricas de alto nível para C-Level
-- Técnicas : Aggregation, FILTER, ROUND, CAST, subquery escalar
-- ════════════════════════════════════════════════════════════════

SELECT
    -- Contagem total de pedidos no período
    COUNT(*)                                                        AS total_orders,

    -- Receita bruta total (soma de todos os pedidos independente de status)
    SUM(total_sales)                                                AS gross_revenue,

    -- Receita apenas de pedidos efetivamente concluídos
    SUM(total_sales) FILTER (WHERE status = 'Completed')            AS completed_revenue,

    -- Receita perdida por cancelamentos (oportunidade de melhoria operacional)
    SUM(total_sales) FILTER (WHERE status = 'Cancelled')            AS cancelled_revenue,

    -- Receita ainda em aberto / aguardando confirmação
    SUM(total_sales) FILTER (WHERE status = 'Pending')              AS pending_revenue,

    -- Ticket médio global: receita total ÷ número de pedidos
    ROUND(AVG(total_sales), 2)                                      AS avg_order_value,

    -- Ticket médio apenas dos pedidos concluídos (métrica de qualidade)
    ROUND(
        AVG(total_sales) FILTER (WHERE status = 'Completed'), 2
    )                                                               AS avg_completed_value,

    -- Taxa de conversão: % de pedidos que chegaram ao status Completed
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE status = 'Completed')
               / COUNT(*), 2
    )                                                               AS conversion_rate_pct,

    -- Taxa de cancelamento: % de pedidos cancelados (KPI de risco)
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE status = 'Cancelled')
               / COUNT(*), 2
    )                                                               AS cancellation_rate_pct,

    -- Produto mais vendido por receita total (subquery escalar)
    (
        SELECT product
        FROM   sales
        GROUP  BY product
        ORDER  BY SUM(total_sales) DESC
        LIMIT  1
    )                                                               AS top_product,

    -- Categoria líder em receita
    (
        SELECT category
        FROM   sales
        GROUP  BY category
        ORDER  BY SUM(total_sales) DESC
        LIMIT  1
    )                                                               AS top_category

FROM sales;


-- ════════════════════════════════════════════════════════════════
-- QUERY 2 | ANÁLISE POR CATEGORIA
-- Objetivo : Performance financeira e operacional por categoria
-- Técnicas : GROUP BY, FILTER, ROUND, window share (SUM OVER)
-- ════════════════════════════════════════════════════════════════

SELECT
    category,

    -- Volume de pedidos na categoria
    COUNT(*)                                                            AS total_orders,

    -- Receita total da categoria
    SUM(total_sales)                                                    AS total_revenue,

    -- Participação da categoria na receita total (market share interno)
    -- SUM OVER () sem PARTITION calcula o total global — divide a receita da categoria por ele
    ROUND(
        100.0 * SUM(total_sales) / SUM(SUM(total_sales)) OVER (), 2
    )                                                                   AS revenue_share_pct,

    -- Ticket médio da categoria
    ROUND(AVG(total_sales), 2)                                          AS avg_order_value,

    -- Pedidos concluídos na categoria
    COUNT(*) FILTER (WHERE status = 'Completed')                        AS completed_orders,

    -- Pedidos cancelados na categoria
    COUNT(*) FILTER (WHERE status = 'Cancelled')                        AS cancelled_orders,

    -- Taxa de cancelamento por categoria (identifica categorias problemáticas)
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE status = 'Cancelled')
               / COUNT(*), 2
    )                                                                   AS cancel_rate_pct,

    -- Receita máxima de um único pedido na categoria
    MAX(total_sales)                                                    AS max_single_order,

    -- Receita mínima de um único pedido na categoria
    MIN(total_sales)                                                    AS min_single_order

FROM  sales
GROUP BY category
ORDER BY total_revenue DESC;  -- Ordena da categoria mais rentável para a menos


-- ════════════════════════════════════════════════════════════════
-- QUERY 3 | ANÁLISE TEMPORAL MENSAL
-- Objetivo : Evolução de receita e volume mês a mês (MoM)
-- Técnicas : DATE_TRUNC, LAG (window), crescimento MoM, CTE,
--            SUM OVER com ROWS BETWEEN (running total / YTD)
-- ════════════════════════════════════════════════════════════════

WITH monthly_base AS (
    -- Agrega métricas por mês
    SELECT
        DATE_TRUNC('month', order_date)                                   AS month_start,   -- Trunca ao 1º dia do mês (para ordenação correta)
        STRFTIME(order_date, '%Y-%m')                                     AS month_label,   -- Rótulo legível (ex: 2025-02)
        COUNT(*)                                                           AS total_orders,
        SUM(total_sales)                                                   AS total_revenue,
        ROUND(AVG(total_sales), 2)                                         AS avg_ticket,
        COUNT(*) FILTER (WHERE status = 'Completed')                       AS completed_orders,
        COUNT(*) FILTER (WHERE status = 'Cancelled')                       AS cancelled_orders,
        SUM(total_sales) FILTER (WHERE status = 'Completed')               AS completed_revenue
    FROM  sales
    GROUP BY 1, 2   -- GROUP BY pela posição: 1 = month_start, 2 = month_label
)

SELECT
    month_label,
    total_orders,
    total_revenue,
    avg_ticket,
    completed_orders,
    cancelled_orders,
    completed_revenue,

    -- LAG: busca o valor do mês ANTERIOR na janela ordenada por month_start
    -- Retorna NULL para o primeiro mês (sem mês anterior para comparar)
    LAG(total_revenue) OVER (ORDER BY month_start)                        AS prev_month_revenue,

    -- Delta absoluto MoM: diferença de receita entre mês atual e anterior
    total_revenue
    - LAG(total_revenue) OVER (ORDER BY month_start)                      AS mom_revenue_delta,

    -- Crescimento percentual MoM
    -- NULLIF evita divisão por zero caso o mês anterior tenha receita 0
    ROUND(
        100.0 * (total_revenue - LAG(total_revenue) OVER (ORDER BY month_start))
              / NULLIF(LAG(total_revenue) OVER (ORDER BY month_start), 0), 2
    )                                                                     AS mom_growth_pct,

    -- Receita acumulada YTD (Year-to-Date / running total)
    -- ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW = soma da primeira até a linha atual
    SUM(total_revenue) OVER (
        ORDER BY month_start
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                                                     AS ytd_revenue

FROM  monthly_base
ORDER BY month_start;


-- ════════════════════════════════════════════════════════════════
-- QUERY 4 | RANKING DE PRODUTOS COM WINDOW FUNCTIONS
-- Objetivo : Classificar produtos por múltiplas dimensões
-- Técnicas : RANK, DENSE_RANK, ROW_NUMBER, NTILE, PERCENT_RANK,
--            PARTITION BY para ranking intra-categoria
-- ════════════════════════════════════════════════════════════════

WITH product_metrics AS (
    -- Calcula métricas base por produto
    SELECT
        product,
        category,
        COUNT(*)                                                              AS total_orders,
        SUM(total_sales)                                                      AS total_revenue,
        ROUND(AVG(total_sales), 2)                                            AS avg_ticket,
        SUM(quantity)                                                         AS total_units_sold,
        COUNT(*) FILTER (WHERE status = 'Completed')                          AS completed_orders,
        COUNT(*) FILTER (WHERE status = 'Cancelled')                          AS cancelled_orders,
        ROUND(
            100.0 * COUNT(*) FILTER (WHERE status = 'Cancelled') / COUNT(*), 2
        )                                                                     AS cancel_rate_pct
    FROM  sales
    GROUP BY product, category
)

SELECT
    product,
    category,
    total_orders,
    total_revenue,
    avg_ticket,
    total_units_sold,
    completed_orders,
    cancelled_orders,
    cancel_rate_pct,

    -- RANK: permite empates, mas pula posições (ex: 1, 1, 3)
    RANK()         OVER (ORDER BY total_revenue DESC)                     AS revenue_rank,

    -- DENSE_RANK: permite empates, mas NÃO pula posições (ex: 1, 1, 2)
    DENSE_RANK()   OVER (ORDER BY total_revenue DESC)                     AS revenue_dense_rank,

    -- ROW_NUMBER: numeração sequencial única mesmo em caso de empate
    ROW_NUMBER()   OVER (ORDER BY total_revenue DESC)                     AS row_num,

    -- PARTITION BY category: ranking reiniciado dentro de cada categoria
    -- Útil para saber qual produto lidera dentro de Eletrônicos, Roupas, etc.
    RANK()         OVER (
                       PARTITION BY category
                       ORDER BY total_revenue DESC
                   )                                                      AS rank_in_category,

    -- NTILE(4): divide os produtos em 4 quartis iguais por receita
    -- Quartil 1 = top 25% (best sellers) | Quartil 4 = bottom 25% (slow movers)
    NTILE(4)       OVER (ORDER BY total_revenue DESC)                     AS revenue_quartile,

    -- PERCENT_RANK: posição percentual normalizada (0.0 = menor | 1.0 = maior)
    -- Útil para entender onde o produto está no espectro completo
    ROUND(
        PERCENT_RANK() OVER (ORDER BY total_revenue), 4
    )                                                                     AS percentile_rank

FROM  product_metrics
ORDER BY total_revenue DESC;


-- ════════════════════════════════════════════════════════════════
-- QUERY 5 | SEGMENTAÇÃO DE CLIENTES — RFM SIMPLIFICADO
-- Objetivo : Classificar clientes por Recência, Frequência e Valor
-- Técnicas : CTE encadeadas, DATE_DIFF, NTILE por dimensão,
--            CASE WHEN para segmentação de negócio
-- ════════════════════════════════════════════════════════════════
-- O modelo RFM é amplamente usado em marketing e CRM:
--   R (Recency)   = Há quantos dias o cliente comprou pela última vez
--   F (Frequency) = Quantas vezes ele comprou no período
--   M (Monetary)  = Quanto ele gastou no total

WITH rfm_base AS (
    -- Calcula as 3 dimensões do RFM por cliente
    SELECT
        customer_name,

        -- RECÊNCIA: dias desde o último pedido até a data mais recente do dataset
        -- Quanto menor o número, mais recente foi a última compra (melhor sinal)
        DATE_DIFF('day',
            MAX(order_date),
            (SELECT MAX(order_date) FROM sales)
        )                                                               AS recency_days,

        -- FREQUÊNCIA: total de pedidos realizados (inclui todos os status)
        COUNT(*)                                                        AS frequency,

        -- VALOR MONETÁRIO: receita total gerada pelo cliente (todos os pedidos)
        SUM(total_sales)                                                AS monetary_value,

        -- Receita efetiva: apenas pedidos concluídos (dinheiro realmente capturado)
        SUM(total_sales) FILTER (WHERE status = 'Completed')            AS completed_value,

        -- Ticket médio do cliente
        ROUND(AVG(total_sales), 2)                                      AS avg_ticket,

        -- Histórico de datas de compra
        MIN(order_date)                                                 AS first_order_date,
        MAX(order_date)                                                 AS last_order_date
    FROM  sales
    GROUP BY customer_name
),

rfm_scored AS (
    -- Converte as métricas brutas em scores de 1 a 4 usando NTILE
    SELECT
        *,
        -- R_Score: 4 = comprou mais recentemente (recency_days menor = melhor)
        NTILE(4) OVER (ORDER BY recency_days ASC)    AS r_score,

        -- F_Score: 4 = comprou mais vezes (frequency maior = melhor)
        NTILE(4) OVER (ORDER BY frequency DESC)      AS f_score,

        -- M_Score: 4 = maior valor gasto (monetary_value maior = melhor)
        NTILE(4) OVER (ORDER BY monetary_value DESC) AS m_score
    FROM rfm_base
)

SELECT
    customer_name,
    recency_days,
    frequency,
    monetary_value,
    completed_value,
    avg_ticket,
    first_order_date,
    last_order_date,
    r_score,
    f_score,
    m_score,

    -- Score RFM total: soma dos 3 scores (mínimo = 3 | máximo = 12)
    (r_score + f_score + m_score)                                       AS rfm_total_score,

    -- Segmentação de negócio baseada no score combinado
    CASE
        WHEN (r_score + f_score + m_score) >= 10 THEN '⭐ Champions'           -- Melhores clientes: compram muito, frequentemente e há pouco tempo
        WHEN (r_score + f_score + m_score) >= 8  THEN '💚 Loyal Customers'     -- Clientes fiéis com bom histórico
        WHEN (r_score + f_score + m_score) >= 6  THEN '🔵 Potential Loyalists' -- Boa tendência, ainda em desenvolvimento
        WHEN (r_score + f_score + m_score) >= 4  THEN '🟡 At Risk'             -- Podem estar perdendo interesse (risco de churn)
        ELSE                                          '🔴 Lost Customers'       -- Inativos há muito tempo ou baixo valor
    END                                                                 AS customer_segment

FROM  rfm_scored
ORDER BY rfm_total_score DESC, monetary_value DESC;


-- ════════════════════════════════════════════════════════════════
-- QUERY 6 | ANÁLISE POR FORMA DE PAGAMENTO
-- Objetivo : Entender preferências e performance por meio de pag.
-- Técnicas : GROUP BY, FILTER, window share (SUM OVER), RANK
-- ════════════════════════════════════════════════════════════════

SELECT
    payment_method,

    -- Volume de pedidos por método de pagamento
    COUNT(*)                                                                    AS total_orders,

    -- Share de pedidos: % deste método sobre o total de pedidos
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)                         AS order_share_pct,

    -- Receita total gerada por método
    SUM(total_sales)                                                            AS total_revenue,

    -- Share de receita: pode ser maior ou menor que o share de pedidos
    -- (ex: Gift Card pode ter menos pedidos mas tickets maiores)
    ROUND(
        100.0 * SUM(total_sales) / SUM(SUM(total_sales)) OVER (), 2
    )                                                                           AS revenue_share_pct,

    -- Ticket médio por método (métodos premium tendem a ter ticket maior)
    ROUND(AVG(total_sales), 2)                                                  AS avg_ticket,

    -- Pedidos concluídos por método
    COUNT(*) FILTER (WHERE status = 'Completed')                                AS completed_orders,

    -- Pedidos cancelados por método
    COUNT(*) FILTER (WHERE status = 'Cancelled')                                AS cancelled_orders,

    -- Taxa de cancelamento por método
    -- Métodos com alta taxa de cancel podem indicar fricção no checkout
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE status = 'Cancelled') / COUNT(*), 2
    )                                                                           AS cancel_rate_pct,

    -- Receita efetiva: apenas pedidos Completed (valor realmente recebido)
    SUM(total_sales) FILTER (WHERE status = 'Completed')                        AS effective_revenue,

    -- Ranking dos métodos por receita gerada
    RANK() OVER (ORDER BY SUM(total_sales) DESC)                                AS revenue_rank

FROM  sales
GROUP BY payment_method
ORDER BY total_revenue DESC;


-- ════════════════════════════════════════════════════════════════
-- QUERY 7 | ANÁLISE GEOGRÁFICA POR CIDADE
-- Objetivo : Identificar mercados mais e menos relevantes
-- Técnicas : GROUP BY, RANK, NTILE, subquery correlacionada
-- ════════════════════════════════════════════════════════════════

SELECT
    city,

    -- Volume e receita por cidade
    COUNT(*)                                                                    AS total_orders,
    SUM(total_sales)                                                            AS total_revenue,

    -- Market share da cidade na receita total
    ROUND(
        100.0 * SUM(total_sales) / SUM(SUM(total_sales)) OVER (), 2
    )                                                                           AS revenue_share_pct,

    -- Ticket médio da cidade (pode indicar poder de compra local)
    ROUND(AVG(total_sales), 2)                                                  AS avg_ticket,

    -- Pedidos concluídos na cidade
    COUNT(*) FILTER (WHERE status = 'Completed')                                AS completed_orders,

    -- Taxa de conclusão por cidade (cidades com baixa taxa merecem investigação)
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE status = 'Completed') / COUNT(*), 2
    )                                                                           AS completion_rate_pct,

    -- Categoria mais comprada em cada cidade (subquery correlacionada)
    -- s2.city = s1.city: correlaciona a subquery com a linha atual do grupo externo
    (
        SELECT   category
        FROM     sales s2
        WHERE    s2.city = s1.city
        GROUP BY category
        ORDER BY SUM(total_sales) DESC
        LIMIT 1
    )                                                                           AS top_category,

    -- Ranking geral por receita
    RANK()   OVER (ORDER BY SUM(total_sales) DESC)                              AS revenue_rank,

    -- Quartil geográfico (Q1 = cidades no top 25% de receita)
    NTILE(4) OVER (ORDER BY SUM(total_sales) DESC)                              AS revenue_quartile

FROM  sales s1
GROUP BY city
ORDER BY total_revenue DESC;


-- ════════════════════════════════════════════════════════════════
-- QUERY 8 | DETECÇÃO DE ANOMALIAS — Z-SCORE
-- Objetivo : Identificar pedidos fora do padrão para auditoria
-- Técnicas : CTE, STDDEV, Z-Score estatístico, CROSS JOIN,
--            PERCENT_RANK, CASE WHEN, ABS
-- ════════════════════════════════════════════════════════════════
-- O Z-Score mede quantos desvios padrão um valor está da média:
--   Z =  (valor - média) / desvio_padrão
--   |Z| > 1.5  → Levemente atípico (Atenção)
--   |Z| > 2.0  → Outlier significativo
--   |Z| > 3.0  → Anomalia severa (provável erro ou fraude)

WITH order_stats AS (
    -- Calcula média e desvio padrão globais da receita — retorna 1 única linha
    SELECT
        AVG(total_sales)    AS global_avg,
        STDDEV(total_sales) AS global_std
    FROM sales
),

orders_with_zscore AS (
    -- Une cada pedido com as estatísticas globais e calcula o Z-Score
    SELECT
        s.order_id,
        s.order_date,
        s.product,
        s.category,
        s.customer_name,
        s.city,
        s.total_sales,
        s.status,
        ROUND(o.global_avg, 2)                                              AS global_avg,
        ROUND(o.global_std, 2)                                              AS global_std,

        -- Z-Score do pedido: quão distante da média (em desvios padrão)
        -- NULLIF(global_std, 0) evita divisão por zero se todos os valores forem iguais
        ROUND(
            (s.total_sales - o.global_avg) / NULLIF(o.global_std, 0), 3
        )                                                                   AS z_score,

        -- Percentil do pedido: posição relativa em relação a todos os pedidos
        -- 0.00 = menor receita | 100.00 = maior receita
        ROUND(
            PERCENT_RANK() OVER (ORDER BY s.total_sales) * 100, 2
        )                                                                   AS percentile

    FROM  sales s
    CROSS JOIN order_stats o  -- CROSS JOIN com tabela de 1 linha aplica stats a todas as linhas
)

SELECT
    order_id,
    order_date,
    product,
    category,
    customer_name,
    city,
    total_sales,
    status,
    global_avg,
    global_std,
    z_score,
    percentile,

    -- Classifica o nível de anomalia baseado no Z-Score absoluto
    CASE
        WHEN ABS(z_score) > 3   THEN '🚨 Anomalia Severa'     -- Extremamente fora do padrão
        WHEN ABS(z_score) > 2   THEN '⚠️  Outlier Alto'        -- Significativamente atípico
        WHEN ABS(z_score) > 1.5 THEN '🔶 Atenção'             -- Levemente elevado
        ELSE                         '✅ Normal'               -- Dentro do esperado
    END                                                         AS anomaly_flag

FROM  orders_with_zscore
WHERE ABS(z_score) > 1.5          -- Filtra apenas pedidos que merecem revisão
ORDER BY ABS(z_score) DESC;       -- Os mais anômalos primeiro


-- ════════════════════════════════════════════════════════════════
-- QUERY 9 | COHORT DE CLIENTES
-- Objetivo : Agrupar clientes pelo mês da primeira compra e
--            analisar comportamento ao longo do tempo
-- Técnicas : CTE dupla, MIN, DATE_DIFF, JOIN, cohort analysis
-- ════════════════════════════════════════════════════════════════
-- Análise de Cohort responde: "Clientes que compraram pela primeira
-- vez em Fevereiro, como se comportaram nos meses seguintes?"
-- É fundamental para entender retenção e LTV (Lifetime Value).

WITH first_purchase AS (
    -- Determina o mês da primeira compra de cada cliente (cohort de entrada)
    SELECT
        customer_name,
        MIN(order_date)                          AS first_purchase_date,    -- Data exata da 1ª compra
        STRFTIME(MIN(order_date), '%Y-%m')       AS cohort_month            -- Mês do cohort (ex: 2025-02)
    FROM  sales
    GROUP BY customer_name
),

customer_activity AS (
    -- Junta toda a atividade de cada cliente com seu cohort de entrada
    SELECT
        s.customer_name,
        s.order_date,
        s.total_sales,
        s.status,
        f.cohort_month,
        f.first_purchase_date,

        -- Mês 0 = mês da 1ª compra | Mês 1 = 1 mês depois | Mês 2 = 2 meses depois
        -- Permite rastrear em qual "período de vida" o cliente estava em cada compra
        DATE_DIFF('month', f.first_purchase_date, s.order_date) AS months_since_first
    FROM  sales s
    JOIN  first_purchase f USING (customer_name)   -- JOIN pelo nome do cliente
)

SELECT
    cohort_month,

    -- Quantos clientes únicos entraram neste cohort (compraram pela 1ª vez neste mês)
    COUNT(DISTINCT customer_name)                                       AS cohort_size,

    -- Total de pedidos feitos pelo cohort ao longo de todo o período
    COUNT(*)                                                             AS total_orders,

    -- Receita total gerada pelo cohort (inclui meses subsequentes)
    SUM(total_sales)                                                     AS total_revenue,

    -- LTV simplificado: receita média por cliente do cohort
    ROUND(SUM(total_sales)::FLOAT / COUNT(DISTINCT customer_name), 2)   AS revenue_per_customer,

    -- Frequência média: pedidos por cliente do cohort
    ROUND(COUNT(*)::FLOAT / COUNT(DISTINCT customer_name), 2)            AS orders_per_customer,

    -- Longevidade do cohort: quantos meses após a 1ª compra ainda houve atividade
    MAX(months_since_first)                                              AS max_months_active

FROM  customer_activity
GROUP BY cohort_month
ORDER BY cohort_month;


-- ════════════════════════════════════════════════════════════════
-- QUERY 10 | VIEW EXECUTIVA CONSOLIDADA
-- Objetivo : Combinar todas as dimensões em um único relatório
-- Técnicas : CTEs múltiplas encadeadas, subqueries escalares,
--            QUALIFY (window filter), NULLIF, cálculo de net rate
-- ════════════════════════════════════════════════════════════════

WITH kpi AS (
    -- KPIs globais calculados uma única vez e reutilizados pelas demais CTEs
    SELECT
        COUNT(*)                                                                    AS total_orders,
        SUM(total_sales)                                                            AS gross_revenue,
        SUM(total_sales) FILTER (WHERE status = 'Completed')                        AS net_revenue,
        ROUND(AVG(total_sales), 2)                                                  AS avg_ticket,
        ROUND(
            100.0 * COUNT(*) FILTER (WHERE status = 'Completed') / COUNT(*), 2
        )                                                                           AS conversion_pct
    FROM sales
),

cat_ranked AS (
    -- Ranking de categorias com participação percentual na receita
    SELECT
        category,
        SUM(total_sales)                                                            AS cat_revenue,
        RANK() OVER (ORDER BY SUM(total_sales) DESC)                                AS cat_rank,
        ROUND(
            100.0 * SUM(total_sales) / (SELECT gross_revenue FROM kpi), 2
        )                                                                           AS cat_share_pct
    FROM  sales
    GROUP BY category
),

top_city AS (
    -- Top 3 cidades por receita
    SELECT
        city,
        SUM(total_sales)                                AS city_revenue,
        RANK() OVER (ORDER BY SUM(total_sales) DESC)    AS city_rank
    FROM   sales
    GROUP  BY city
    QUALIFY city_rank <= 3    -- QUALIFY: filtra após window functions (não existe WHERE equivalente)
),

top_product AS (
    -- Top 3 produtos por receita
    SELECT
        product,
        SUM(total_sales)                                AS prod_revenue,
        RANK() OVER (ORDER BY SUM(total_sales) DESC)    AS prod_rank
    FROM   sales
    GROUP  BY product
    QUALIFY prod_rank <= 3
)

-- Relatório final: une todos os KPIs e top performers em uma única linha executiva
SELECT
    -- Bloco 1: KPIs financeiros globais
    k.total_orders,
    k.gross_revenue,
    k.net_revenue,
    ROUND(
        k.net_revenue * 100.0 / NULLIF(k.gross_revenue, 0), 2
    )                                                               AS net_rate_pct,   -- % da receita que foi efetivamente convertida
    k.avg_ticket,
    k.conversion_pct,

    -- Bloco 2: Líderes por dimensão (subqueries escalares — retornam 1 valor)
    (SELECT category      FROM cat_ranked  WHERE cat_rank  = 1)    AS top_category,
    (SELECT cat_share_pct FROM cat_ranked  WHERE cat_rank  = 1)    AS top_cat_share_pct,

    (SELECT product       FROM top_product WHERE prod_rank = 1)    AS top_product,
    (SELECT prod_revenue  FROM top_product WHERE prod_rank = 1)    AS top_product_revenue,

    (SELECT city          FROM top_city    WHERE city_rank = 1)    AS top_city,
    (SELECT city_revenue  FROM top_city    WHERE city_rank = 1)    AS top_city_revenue

FROM kpi k;
