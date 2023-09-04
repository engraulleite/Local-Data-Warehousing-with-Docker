# Carrega as tabelas dims_fato

INSERT INTO schema3.dim_tempo (ano, mes, dia, hora, data_completa)
SELECT EXTRACT(YEAR FROM d)::INT, 
       EXTRACT(MONTH FROM d)::INT, 
       EXTRACT(DAY FROM d)::INT, 
       LPAD(EXTRACT(HOUR FROM d)::integer::text, 2, '0'), 
       d::DATE
FROM generate_series('2020-01-01'::DATE, '2024-12-31'::DATE, '1 HOUR'::INTERVAL) d;


INSERT INTO schema3.dim_cliente (id_cliente, nome, tipo)
SELECT id_cliente, 
       nome_cliente, 
       nome_tipo
FROM schema2.st_ft_clientes tb1, schema2.st_ft_tipo_cliente tb2
WHERE tb2.id_tipo = tb1.id_tipo;


INSERT INTO schema3.dim_produto (id_produto, nome_produto, categoria, subcategoria)
SELECT id_produto, 
       nome_produto, 
       nome_categoria, 
       nome_subcategoria
FROM schema2.st_ft_produtos tb1, schema2.st_ft_subcategorias tb2, schema2.st_ft_categorias tb3
WHERE tb3.id_categoria = tb2.id_categoria
AND tb2.id_subcategoria = tb1.id_subcategoria;


INSERT INTO schema3.dim_localidade (id_localidade, pais, regiao, estado, cidade)
SELECT id_localidade, 
          pais, 
          regiao, 
          CASE
              WHEN nome_cidade = 'Natal' THEN 'Rio Grande do Norte'
              WHEN nome_cidade = 'Rio de Janeiro' THEN 'Rio de Janeiro'
              WHEN nome_cidade = 'Belo Horizonte' THEN 'Minas Gerais'
              WHEN nome_cidade = 'Salvador' THEN 'Bahia'
              WHEN nome_cidade = 'Blumenau' THEN 'Santa Catarina'
              WHEN nome_cidade = 'Curitiba' THEN 'Paraná'
              WHEN nome_cidade = 'Fortaleza' THEN 'Ceará'
              WHEN nome_cidade = 'Recife' THEN 'Pernambuco'
              WHEN nome_cidade = 'Porto Alegre' THEN 'Rio Grande do Sul'
              WHEN nome_cidade = 'Manaus' THEN 'Amazonas'
          END estado, 
          nome_cidade
FROM schema2.st_ft_localidades tb1, schema2.st_ft_cidades tb2
WHERE tb2.id_cidade = tb1.id_cidade;


INSERT INTO schema3.fato_vendas (sk_produto, 
                                sk_cliente, 
                                sk_localidade, 
                                sk_tempo, 
                                quantidade, 
                                preco_venda, 
                                custo_produto, 
                                receita_vendas,
                                resultado)
SELECT sk_produto,
       sk_cliente,
       sk_localidade,
       sk_tempo, 
       SUM(quantidade) AS quantidade, 
       SUM(preco_venda) AS preco_venda, 
       SUM(custo_produto) AS custo_produto, 
       SUM(ROUND((CAST(quantidade AS numeric) * CAST(preco_venda AS numeric)), 2)) AS receita_vendas,
       SUM(ROUND((CAST(quantidade AS numeric) * CAST(preco_venda AS numeric)), 2) - custo_produto) AS resultado 
FROM schema2.st_ft_vendas tb1, 
     schema2.st_ft_clientes tb2, 
     schema2.st_ft_localidades tb3, 
     schema2.st_ft_produtos tb4,
     schema3.dim_tempo tb5,
     schema3.dim_produto tb6,
     schema3.dim_localidade tb7,
     schema3.dim_cliente tb8
WHERE tb2.id_cliente = tb1.id_cliente
AND tb3.id_localidade = tb1.id_localizacao
AND tb4.id_produto = tb1.id_produto
AND to_char(tb1.data_transacao, 'YYYY-MM-DD') = to_char(tb5.data_completa, 'YYYY-MM-DD')
AND to_char(tb1.data_transacao, 'HH') = tb5.hora
AND tb2.id_cliente = tb8.id_cliente
AND tb3.id_localidade = tb7.id_localidade
AND tb4.id_produto = tb6.id_produto
GROUP BY sk_produto, sk_cliente, sk_localidade, sk_tempo;