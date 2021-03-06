
/****** Object:  StoredProcedure [dbo].[pr_WrkCotacoesImportar_ValidarCalcular]    Script Date: 01/02/2021 15:12:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Helder Ferreira
-- Create date:		2014-03-03
-- Reviewer:		Pedro Tavares
-- Review date:		2021-02-04
-- Description:		Valida e calcula cotações
-- =============================================
ALTER PROCEDURE [dbo].[pr_WrkCotacoesImportar_ValidarCalcular]
	@p_UserJob varchar(10),
	@p_IsBinfolio bit
AS
BEGIN

	SET NOCOUNT ON;

	-- Actualizar o estado dos registos
	MERGE WORK.WrkCotacoesImportar AS tblTarget
	USING
	(
		SELECT 
			WRK.UserJob,
			WRK.IdCotacao,
			WRK.Fundo,
			WRK.DataCotacao,
			VF.NumeroUnidades As NumeroUnidades,
			WRK.ValorCotacao,
			ISNULL(CONVERT(DECIMAL(18,2), (VF.NumeroUnidades * WRK.ValorCotacao)), 0) As ValorFundo,
			VF.CotacaoFundo,
			CASE
				WHEN F0.[IdFundo] IS NULL THEN 1 -- Fundo não existe
				WHEN QU.[DataCotacao] IS NOT NULL THEN 2  -- Já existe cotação para a data 
				ELSE 0 -- Cotação sem erros
			END AS EstadoCotacao,
			Case 
				WHEN F0.[IdFundo] IS NOT NULL then WRK.DadosComErros ELSE WRK.DadosComErros + ' - Fundo não Existe. ' 
			END as DadosComErros
		FROM WORK.WrkCotacoesImportar AS WRK
		LEFT JOIN dbo.[Cotacoes] AS QU
			ON QU.[IdFundo] = WRK.Fundo
			AND QU.[DataCotacao] = WRK.DataCotacao
		LEFT JOIN [CfgClt].[Fundos] AS F0
			ON F0.[IdFundo] = WRK.Fundo
		OUTER APPLY
		(
			SELECT TOP 1 
				Q.[NumeroUnidadesParticipacao] AS NumeroUnidades, 
				Q.[ValorFundo] AS ValorFundo,
				Q.[Cotacao] AS CotacaoFundo 
			FROM dbo.[Cotacoes]	AS Q
			WHERE Q.[IdFundo] = WRK.Fundo
				AND Q.[DataCotacao] <= WRK.DataCotacao
			ORDER BY Q.[DataCotacao] DESC
		) AS VF
		WHERE WRK.UserJob = @p_UserJob

	) AS tblSource
	ON tblTarget.UserJob = tblSource.UserJob
		AND tblTarget.IdCotacao = tblSource.IdCotacao
		AND tblTarget.Fundo = tblSource.Fundo
		AND tblTarget.DataCotacao = tblSource.DataCotacao
		AND tblSource.EstadoCotacao > 0
	WHEN MATCHED
		THEN UPDATE
		SET
			tblTarget.Estado = tblSource.EstadoCotacao,
			tblTarget.NumeroUP = tblSource.NumeroUnidades,
			tblTarget.ValorFundo = tblSource.ValorFundo,
			tblTarget.ValorCotacao = tblSource.ValorCotacao,
			tblTarget.DadosComErros = tblSource.DadosComErros;

	-- Atualiza os registos em que o Fundo e a Data e a mesma
	UPDATE WCI
	SET WCI.DadosComErros = WCI.DadosComErros + ' - Cotação repetida.'
	FROM WORK.WrkCotacoesImportar AS WCI
	WHERE WCI.UserJob = @p_UserJob
		AND WCI.Fundo IS NOT NULL 
		AND WCI.Fundo > 0
		AND EXISTS
		(
			SELECT TOP 1 1
			FROM WORK.WrkCotacoesImportar AS WCIA
			WHERE WCIA.UserJob = WCI.UserJob
				AND WCIA.IdCotacao <> WCI.IdCotacao
				AND WCIA.Fundo = WCI.Fundo
				AND WCIA.DataCotacao = WCI.DataCotacao
		);


	-- Verificar fundos para os quais a data de fecho ja foi definida e ja existe cotação para a data 
	UPDATE WCI
	SET WCI.DadosComErros = WCI.DadosComErros + ' - Data de cotação anterior a data de fecho do produto.',
		WCI.ESTADO = 1 
	FROM WORK.WrkCotacoesImportar AS WCI
	WHERE WCI.UserJob = @p_UserJob
		AND WCI.Fundo IS NOT NULL 
		AND WCI.Fundo > 0
		AND WCI.ESTADO = 2 
		AND EXISTS
		(
			SELECT TOP 1 1
			FROM [CfgClt].[ProdutosFundos] AS PF
			INNER JOIN [CfgClt].Produtos AS P
				on P.IdProduto = PF.[IdProduto]
				and P.DataFecho > WCI.DataCotacao
			where PF.[IdFundo] = WCI.Fundo
		);


	-- Verificar se existem reembolsos à data em questão
	UPDATE WCI
	SET WCI.DadosComErros = WCI.DadosComErros + ' - Existem reembolsos para a data ' + CONVERT(varchar, WCI.DataCotacao,103) +'.',
		WCI.ESTADO = 1 
	FROM WORK.WrkCotacoesImportar AS WCI
	WHERE WCI.UserJob = @p_UserJob
		AND WCI.Fundo IS NOT NULL 
		AND WCI.Fundo > 0
		AND WCI.ESTADO = 2 
		AND EXISTS
		(
			SELECT TOP 1 1
			FROM dbo.ReembolsosIndividuais AS RU
			INNER JOIN dbo.Contratos AS C
				ON C.IdContrato = RU.IdContrato
				AND C.IdFundo = WCI.Fundo
			INNER JOIN dbo.ReembolsosMultiplos AS RM
				ON RM.IdReembolsoMultiplo = RU.IdReembolsoMultiplo
				AND RM.DataReembolso = WCI.DataCotacao
				AND RM.IdEstado not like 'M' --adicionado para garantir que a importação é conseguida mesmo quando só existem movimentos temporários.
		);

	----Verificar se existem subscrições reembolsadas à data em questão
	--UPDATE WCI
	--SET WCI.DadosComErros = WCI.DadosComErros + ' - Existem subscrições reembolsadas para a data ' + CONVERT(varchar, WCI.DataCotacao,103) +'.',
	--	WCI.ESTADO = 1 
	--FROM WORK.WrkCotacoesImportar AS WCI
	--WHERE WCI.UserJob = @p_UserJob
	--	AND WCI.Fundo IS NOT NULL 
	--	AND WCI.Fundo > 0
	--	AND WCI.ESTADO = 2 
	--	AND EXISTS
	--	(
	--		SELECT TOP 1 1
	--		FROM  DBO.SubscricoesMultiplas AS SM 
	--		INNER JOIN dbo.SubscricoesIndividuais AS SU
	--			ON SU.IdSubscricaoMultipla = SM.IdSubscricaoMultipla
	--			AND SU.Estado NOT IN 
	--			(
	--				' '
	--			)
	--		INNER JOIN dbo.Contratos AS C
	--			ON C.IdContrato = SU.IdContrato
	--			AND C.IdFundo = WCI.Fundo
	--		INNER JOIN CFGBIZ.subestado AS SE 
	--			ON SE.SM_STAT = SU.Estado
	--			AND SE.EstadoMovimentosTemporarios = 0
	--		WHERE SM.DataMovimento = WCI.DataCotacao
		
	--	);

	----Verificar se existem movimentos de transferencia interna/externa a data em questão
	--UPDATE WCI
	--SET WCI.DadosComErros = WCI.DadosComErros + ' - Existem Transferencias internas para a data ' + CONVERT(varchar, WCI.DataCotacao,103) +'.',
	--	WCI.ESTADO = 1 
	--FROM WORK.WrkCotacoesImportar AS WCI
	--WHERE WCI.UserJob = @p_UserJob
	--	AND WCI.Fundo IS NOT NULL 
	--	AND WCI.Fundo > 0
	--	AND WCI.ESTADO = 2 
	--	AND EXISTS
	--	(
	--		SELECT TOP 1 1
	--		FROM  DBO.SubscricoesMultiplas AS SM 
	--		INNER JOIN cfgclt.sub00 AS S0 
	--			ON S0.tsub = SM.IdTipoSubscricao 
	--			AND S0.uts_tipo IN ('I', 'T')
	--		INNER JOIN dbo.SubscricoesIndividuais AS SU
	--			ON SU.IdSubscricaoMultipla = SM.IdSubscricaoMultipla			
	--		INNER JOIN dbo.Contratos AS C
	--			ON C.IdContrato = SU.IdContrato
	--			AND C.IdFundo = WCI.Fundo
	--		INNER JOIN CFGBIZ.subestado AS SE 
	--			ON SE.SM_STAT = SU.Estado
	--			AND SE.EstadoMovimentosTemporarios = 0
	--		WHERE SM.DataMovimento = WCI.DataCotacao
		
	--	);

	-- Validação do número de unidades de participação
	UPDATE WCI
	SET WCI.DadosComErros = WCI.DadosComErros + ' - O  nº de Unidades de Participação é diferente do nº de Unidades registadas no SGC.',
		WCI.ESTADO = 1
	FROM WORK.WrkCotacoesImportar AS WCI
	LEFT JOIN dbo.[Cotacoes] AS QU
		ON QU.IdFundo = WCI.Fundo
		AND QU.DataCotacao = WCI.DataCotacao
	WHERE WCI.UserJob = @p_UserJob
		AND WCI.Fundo IS NOT NULL 
		AND WCI.Fundo > 0	
		AND QU.IdFundo IS NULL -- Apenas quando não existir cotação à data
		AND WCI.NumeroUP > 0 -- Apenas quando for passado um número de unidades de participação para comparar
		AND WCI.NumeroUP <>
		(
			SELECT TOP 1 C.NumeroUnidadesParticipacao
			FROM dbo.Cotacoes C
			WHERE C.IdFundo = WCI.Fundo
				AND C.DataCotacao < WCI.DataCotacao
			ORDER BY DataCotacao DESC
		);

	-- Validar se já existem cotações para os dias/fundos indicados no ficheiro (esta validação só ocorre se o processo invocado for o Binfólio)
	UPDATE WCI
	SET WCI.DadosComErros = WCI.DadosComErros + ' - Já existe cotação para a data ' + CONVERT(varchar, WCI.DataCotacao,103)+'.',
		WCI.ESTADO = 1
	FROM WORK.WrkCotacoesImportar AS WCI
	INNER JOIN dbo.[Cotacoes] AS QU
		ON QU.IdFundo = WCI.Fundo
		AND QU.DataCotacao = WCI.DataCotacao
	WHERE WCI.UserJob = @p_UserJob
		AND WCI.Fundo IS NOT NULL 
		AND WCI.Fundo > 0
		AND @p_IsBinfolio = 1
END;
