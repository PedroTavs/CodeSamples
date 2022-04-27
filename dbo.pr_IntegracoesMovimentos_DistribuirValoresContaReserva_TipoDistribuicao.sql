
-- =============================================
-- Author:	Pedro Tavares
-- Create date: 2019-11-27
-- Reviewer:	Pedro Tavares
-- Review Date: 2019-11-27
-- Description:	Reencaminha para Procedure de acordo com o Tipo de Distribuição
-- =============================================
CREATE PROCEDURE [dbo].[pr_IntegracoesMovimentos_DistribuirValoresContaReserva_TipoDistribuicao]
(@p_IdIntegracao NUMERIC(18, 0), 
 @p_IdChunk      NUMERIC(9, 0)
)
AS
    BEGIN
        SET NOCOUNT ON;
        
		DECLARE @DistribuitionType char;
		SET @DistribuitionType = (SELECT TOP 1 TipoDistribuicao FROM intgr.IntegracoesMovimentos 
									where IdIntegracao = @p_IdIntegracao 
									and IdChunk = @p_IdChunk
									AND IdTipoMovimento = 'I')

		IF(@DistribuitionType = 'P')
		BEGIN;
			-- Distribução dos Valores da Conta Reserva 
			EXEC pr_IntegracoesMovimentos_DistribuirValoresContaReserva_Proporcional
						@p_IdIntegracao = @p_IdIntegracao, 
						@p_IdChunk = @p_IdChunk
		END;

		IF(@DistribuitionType = 'T')
		BEGIN;
			-- Distribução dos Valores da Conta Reserva 
			EXEC pr_IntegracoesMovimentos_DistribuirValoresContaReserva_Total 
						@p_IdIntegracao = @p_IdIntegracao, 
						@p_IdChunk = @p_IdChunk
		END;
	END;