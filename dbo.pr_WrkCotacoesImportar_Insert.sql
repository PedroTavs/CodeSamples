-----------------------------------------------------------------
-- Nome: pr_WrkCotacoesImportar_Insert
-- Autor: Helder Ferreira
-- Data: 2014-04-03
-- Reviewer: Pedro Tavares
-- Review Date:	2021-02-01
-- Descrição: Inserir cotações na tabela WrkCotacoesImportar
-----------------------------------------------------------------
CREATE PROCEDURE [dbo].[pr_WrkCotacoesImportar_Insert]
	@p_TabelaCotacoes as dbo.typ_WrkCotacoesImportar READONLY
AS
BEGIN
	SET NOCOUNT ON;

	INSERT INTO WORK.WrkCotacoesImportar
	(
		[UserJob], 
		[JobDate],
		[Fundo],
		[DataCotacao],
		[NumeroUP],
		[ValorFundo], 
		[ValorCotacao],
		[DadosComErros],
		Estado,
		MantemNUP,
		RecalcComissao
	) 
	SELECT
		[UserJob], 
		[JobDate],
		[Fundo],
		[DataCotacao],
		[NumeroUP],
		[ValorFundo], 
		[ValorCotacao],
		[DadosComErros],
		0, -- Estado
		MantemNUP,
		RecalcComissao
	FROM @p_TabelaCotacoes;

END;