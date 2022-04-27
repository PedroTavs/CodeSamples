-----------------------------------------------------------------
-- Autor:	Pedro Tavares
-- Data:	2019-09-11
-- Reviewer:	Pedro Tavares
-- Review date: 2019-09-11
-- Descrição:	Obtém cotações com mensagem de erros
-----------------------------------------------------------------
CREATE PROCEDURE [dbo].[pr_WrkCotacoesImportar_ObterCotacoesErro]
	@p_UserJob varchar(10)
AS
BEGIN
	SET NOCOUNT ON;
	
	SELECT
		Fundo,
		DataCotacao,
		NumeroUP,
		ValorFundo, 
		ValorCotacao,
		Estado,
		DadosComErros
	FROM WORK.WrkCotacoesImportar
	where UserJob = @p_UserJob
		AND Estado NOT IN ( 0, 2)
		AND dbo.TRIM(DadosComErros) <> ''

END;