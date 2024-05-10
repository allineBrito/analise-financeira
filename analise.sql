CREATE DATABASE DadosFinanceiro

-- visualiza��o previa dos dados de cada tabela
--1 comandos de ftitulos
SELECT * FROM fTitulos;

--dTerceiro
SELECT * FROM dTerceiro;

SELECT Tipo, Estado FROM dTerceiro;
SELECT
    Estado,
    COUNT(*) AS TotalLinhas
FROM
    dTerceiro
GROUP BY
    Estado;

-- dContaBancaria
SELECT * FROM dContaBancaria;

-- fExtratosBancarios
SELECT * FROM fExtratosBancarios;

-- fTitulosMovimentacoes
SELECT * FROM fTitulosMovimentacoes;

----------------------------------------------------

--saber quantos Id de vendedores tem na tabela 
--analise extra para se ter uma base de compara��o
SELECT 
    dt.IdVendedor,
    COUNT(DISTINCT ft.Valor) AS Unico
FROM 
    fTitulos ft
INNER JOIN 
    dTerceiro dt ON ft.IdTerceiro = dt.IdTerceiro
GROUP BY 
    dt.IdVendedor;

--NFs a Receber emitidas em 2023 e 2024 e que ainda nao foram dadas baixa
--Analise extra para se ter uma base de comparacao
SELECT
    YEAR(ft.DataEmissao) AS Ano,
    FORMAT(SUM(ft.Valor), 'C', 'pt-BR') AS [Valor Total NFs a Receber]
FROM
    fTitulos ft
INNER JOIN
    dTerceiro dt ON ft.IdTerceiro = dt.IdTerceiro
WHERE
    ft.TipoTitulo = 'Receber'
    AND ft.DataBaixa IS NULL 
GROUP BY
    YEAR(ft.DataEmissao)
ORDER BY
    Ano DESC;

--------------------------------------------------------------------

--1� item:  NFs a Receber do Vendedor 5 emitidos em 2024 e que ainda nao foram dadas a baixa
--NF, Parcela, Data de Emissao, Valor da NF, Loja, e Data de Vencimento.
 SELECT 
    ft.NumDoc AS NumeroNotaFiscal, ft.Parcela, FORMAT(ft.DataEmissao, 'dd/MM/yyyy') AS DataEmissao,
    ft.Valor AS NotaFiscalValor,
    ft.Loja,
    FORMAT(ft.DataVencto, 'dd/MM/yyyy') AS DataVencimento
FROM fTitulos ft
INNER JOIN dTerceiro dt ON ft.IdTerceiro = dt.IdTerceiro
WHERE ft.TipoTitulo = 'Receber'
AND dt.IdVendedor = '  000005' 
AND YEAR(ft.DataEmissao) = 2024
AND ft.DataBaixa IS NULL;

--Extrai detalhes e informacoes sobre faturas pendentes ("Receber"), emitidas no ano de 2024, 
--Meus criterios foram: O tipo da fatura, as faturas associadas ao vendedor 5, o ano e apenas as faturas em aberto.
------------------------------------------------------------------------------

--2� item: Os clientes que possuem uma representatividade (share) maior que 10% em quantidade de NFs a receber, vencidas e que nao foram baixadas em Fev/24 e a representatividade 

WITH ClientesNFs AS (
    SELECT dt.IdTerceiro, COUNT(*) AS TotalNFs
    FROM fTitulos ft
    INNER JOIN dTerceiro dt ON ft.IdTerceiro = dt.IdTerceiro
    WHERE ft.TipoTitulo = 'Receber' AND ft.DataBaixa IS NULL AND MONTH(ft.DataVencto) = 2 AND YEAR(ft.DataVencto) = 2024
    GROUP BY dt.IdTerceiro),
TotalNFs AS (
    SELECT COUNT(*) AS Total
    FROM fTitulos ft
    INNER JOIN dTerceiro dt ON ft.IdTerceiro = dt.IdTerceiro
    WHERE ft.TipoTitulo = 'Receber' AND ft.DataBaixa IS NULL AND MONTH(ft.DataVencto) = 2 AND YEAR(ft.DataVencto) = 2024)
SELECT dt.IdTerceiro, dt.RazaoSocial AS Cliente, CN.TotalNFs, TN.Total AS TotalGeral,
    FORMAT((CN.TotalNFs * 100.0 / NULLIF(TN.Total, 0)), 'N2') + '%' AS Share,
        FORMAT(MAX(ft.DataVencto), 'dd/MM/yyyy') AS UltimaNotaFiscalVencida
FROM ClientesNFs CN
CROSS JOIN TotalNFs TN
INNER JOIN dTerceiro dt ON CN.IdTerceiro = dt.IdTerceiro
INNER JOIN fTitulos ft ON ft.IdTerceiro = dt.IdTerceiro
WHERE (CN.TotalNFs * 100.0 / NULLIF(TN.Total, 0)) > 10
GROUP BY dt.IdTerceiro, dt.RazaoSocial, CN.TotalNFs, TN.Total
ORDER BY Share DESC;



--Passos: contar o numero de NF A RECEBER, vencidas e que n�o foram baixadas, no periodo informado, para assim saber a contibui��o de cada cliente
--Ap�s calcular a representatividade  � feita dividindo o numero total de NF a receber e muktiplicar por 100
--No final filtrar os clientes que share � maior que 10%. 
--Meus criterios foram: ID do cliente, o numero de faturas pendentes, a participa��o % das faturas de cada cliente, em rela��o ao total, o totalgeral refere-se a quantidade de faturas em aberto

-------------------------------------------------------------------------------

--3� item: O nome do vendedor juntamente com o estado e a m�dia do valor do t�tulos a receber emitidos em 2023 de cada funcion�rio por estado

SELECT 
    dt.Vendedor AS Vendedor,
    dt.Estado,
    FORMAT(AVG(ft.Valor), 'C', 'pt-BR') AS MediadosValores
FROM 
    fTitulos ft
INNER JOIN 
    dTerceiro dt ON ft.IdTerceiro = dt.IdTerceiro
WHERE 
    YEAR(ft.DataEmissao) = 2023
    AND dt.Vendedor IS NOT NULL
    AND dt.Vendedor <> ''
    --AND dt.Estado NOT LIKE '%EX%' --Caso queira excluir o Estado "EX"
    AND dt.Vendedor <> ''  
GROUP BY 
    dt.Vendedor, dt.Estado
ORDER BY
    dt.Vendedor ASC, dt.Estado ASC;


--Passos: Seleciono o nome do vendedor, Estado e a m�dia de NF A RECEBER no periodo informado, usando a funcao AVG (
--Logo agrupo os resultados pelo nome, estado e valor
--Meus criterios foram: agrupei as tabelas para visualizar os valores das faturas abertas aos vendedores e Estados. Eliminei os registros onde o vendedor nao era valido. Agrupei os vendedores e os Estados e calculei o valor medio da fatura de cada combbinacao.
----------------------------------------------------------------------------

--4� item: Nome do cliente, juntamente com sua compra atual (NF a receber) e data. Epara cada cliente, inclua o valor da sua maior compra anterior

SELECT
    ter.[RazaoSocial] AS NomeCliente,
    t.[NumDoc] AS NumNotaFiscal,
    FORMAT(t.[DataBaixa], 'dd/MM/yyyy') AS DataCompraAtual,
    FORMAT(MAX(t.[Valor]), 'C', 'pt-br') AS MaiorCompra,
    CONVERT(varchar, MAX(t.[DataBaixa]), 103) AS DataMaiorCompra
FROM
    [dbo].[fTitulos] t
JOIN
    [dbo].[dTerceiro] ter ON t.[IdTerceiro] = ter.[IdTerceiro]
WHERE
    t.[TipoTitulo] = 'Receber' AND ter.[RazaoSocial] IS NOT NULL
    AND t.[NumDoc] IS NOT NULL AND t.[DataBaixa] IS NOT NULL
GROUP BY
    ter.[RazaoSocial], t.[NumDoc], t.[DataBaixa], t.[Valor]
ORDER BY
    ter.RazaoSocial ASC;



--Primeiro busco as informacoes sobre as compras atuais de cada cliente, e acresento os detalhes das sias maiores compras em aberto, junto as tabelas dTerceiro e fTitulos. Obtenho o NumDoc da compraAtual.
--Considero apenas as compras anteriores ao GETDATE, filtro apenas os clientes, depois ordeno pelo nome do cliente
