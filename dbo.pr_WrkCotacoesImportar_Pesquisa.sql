
-----------------------------------------------------------------
-- Author:	Helder Ferreira
-- Date:	2014-04-01
-- Reviewer:	Pedro Tavares
-- Review date: 2021-02-02
-- Description: Pesquisar Cotaçoes da tabela WrkCotacoesImportar
-----------------------------------------------------------------
CREATE PROCEDURE [dbo].[pr_WrkCotacoesImportar_Pesquisa]
	@p_PageNumber INT,
	@p_PageRows INT,
	@p_QueryFields as dbo.typ_QueryFields READONLY
AS
BEGIN
	SET NOCOUNT ON;
	
	-- * Fixed Query Parameters *
	DECLARE
		@strSqlQuery NVARCHAR(MAX) = N'',
		@strSqlQueryOrderBy NVARCHAR(MAX),
		@strSqlQueryParameters NVARCHAR(MAX) = N' @p_PageNumber int, @p_PageRows int';

	-- * Specific Query Parameters *
	SET @strSqlQueryParameters = @strSqlQueryParameters + ', @p_UserJob varchar(10)';

		-- * Filter Variables - Declaration *
	DECLARE	
		@p_UserJob varchar(10);

	-- * Filter Variables - Get Values from parameter list *
	-- User Job
	SET @p_UserJob = dbo.udf_QueryFields_GetString(@p_QueryFields, 'p_UserJob');

	---- * Build Query String - Order By *
	--SET @strSqlQueryOrderBy = dbo.udf_QueryFields_GetOrderByClause(@p_QueryFields, 'LCVPEL.IdEmissao DESC');

		-- * Build Query String - SELECT *
	SET @strSqlQuery = @strSqlQuery + N'
	WITH cteRegistos
	AS
	(
		-- Specific Query
		-- Obter linhas de uma Emissão
		SELECT	
			wrk.UserJob,
			wrk.JobDate,
			wrk.IdCotacao,
			wrk.Fundo AS IdFundo,
			wrk.DataCotacao,
			wrk.NumeroUP,
			wrk.ValorFundo,
			wrk.ValorCotacao,
			wrk.Estado,
			wrk.DadosComErros,
			F.DescricaoCompleta AS Fundo,
			wrk.MantemNUP AS MantemNUP,
			wrk.RecalcComissao AS RecalcComissao,
			-- RowNumber - obrigatório
			ROW_NUMBER() OVER (ORDER BY wrk.Fundo ASC, wrk.DataCotacao Desc) AS RowNumber
		FROM WORK.WrkCotacoesImportar AS wrk
		LEFT JOIN CfgClt.Fundos AS F
		ON F.IdFundo = wrk.Fundo
		WHERE wrk.UserJob = @p_UserJob';

	-- Query - Parte final
	SET @strSqlQuery += dbo.udf_QueryFields_GetFinalSelectClause(DEFAULT);

	-- * Execute Query *
	EXEC sp_executesql @strSqlQuery,
						@strSqlQueryParameters,
						@p_PageNumber = @p_PageNumber,
						@p_PageRows = @p_PageRows,
						-- Specific Query Parameters
						@p_UserJob = @p_UserJob
END;