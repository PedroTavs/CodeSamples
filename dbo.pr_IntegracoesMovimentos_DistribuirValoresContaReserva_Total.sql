
-- =============================================
-- Author:	Pedro Tavares
-- Create date: 2019-11-27
-- Reviewer:	Pedro Tavares
-- Review Date: 2021-02-12
-- Description:	Realiza a distribuição dos valores da conta reserva sem desdobrar movimentos de subscrição
-- =============================================
CREATE PROCEDURE [dbo].[pr_IntegracoesMovimentos_DistribuirValoresContaReserva_Total]
(
	@p_IdIntegracao NUMERIC(18, 0), 
	@p_IdChunk      NUMERIC(9, 0)
)
AS
    BEGIN
        SET NOCOUNT ON;

		BEGIN ----- Obter Dados Conta Reserva -----
           	   
		   CREATE TABLE #ContratosValorDisponivel
            (IdEntidadeSuperiora		NUMERIC(18, 0), 
             IdContrato_ContaReserva	NUMERIC(18, 0), 
			 Valor_ContaReserva			NUMERIC(18,7),
             Fundo						SMALLINT
            );

            -- Obter os Contratos referentes às Contas Reserva que serão afetadas e obter o seu valor total disponível
            INSERT INTO #ContratosValorDisponivel
            (IdEntidadeSuperiora, 
             IdContrato_ContaReserva, 
			 Valor_ContaReserva,
             Fundo
            )
			SELECT DISTINCT
				IM.EntidadeContribuinte,
				C.IdContrato,
				ISNULL(RoundValue, 0),
				C.IdFundo
			FROM Intgr.IntegracoesMovimentos AS IM 
			INNER JOIN dbo.ContratosProduto AS CP 
				ON CP.IdProduto = IM.Produto 
				AND CP.NumeroContratoProduto = IM.NumeroContratoProduto 
			INNER JOIN dbo.Entidades E 
				ON E.EntidadeReserva = 1
			INNER JOIN dbo.ContratosProdutoParticipantes CPP 
				ON CPP.IdEntidadeParticipante = E.IdEntidade 
				AND CPP.IdContratoProduto = CP.IdContratoProduto
			INNER JOIN Contratos AS C 
				ON C.IdContratoProdutoParticipante = CPP.IdContratoProdutoParticipante 
				AND C.IdSituacao IN ('A', 'P')
				AND IM.Fundo = C.IdFundo
			-- Obter cotação do dia
			CROSS APPLY
			(
				SELECT TOP (1) F.[IdFundo] AS IdFundo, 
								ISNULL(Q.[Cotacao], 0.0) AS Cotacao, 
								ISNULL(Q.[DataCotacao], dbo.udf_GetMinDate()) AS DataCotacao
				FROM [CfgClt].[Fundos] AS F
					LEFT JOIN dbo.[Cotacoes] AS Q ON Q.[IdFundo] = F.[IdFundo]
														AND Q.[DataCotacao] <= IM.DataMovimento
				WHERE F.[IdFundo] = C.IdFundo
						AND F.[DataCriacao] <= IM.DataMovimento
				ORDER BY Q.[DataCotacao] DESC
			) CotacaoDia
			CROSS APPLY
			(
				SELECT SaldoNUP
				FROM dbo.udf_Contratos_ObterSaldoAData('', IM.DataMovimento, 'A', C.IdContrato, default)
			) SaldoNUP
			CROSS APPLY(
				SELECT RoundValue * CotacaoDia.Cotacao as Valor
					FROM dbo.udf_Math_RoundUPs(C.IdFundo, SaldoNUP)
			) ValorDisponivel
			CROSS APPLY (
				SELECT RoundValue
					FROM dbo.udf_Math_RoundUPs(C.IdFundo, ValorDisponivel.Valor)
			) RoundValue
			WHERE IM.IdIntegracao = @p_IdIntegracao
				AND IM.IdChunk = @p_IdChunk
				AND IM.IdTipoMovimento = 'I'
				AND IM.IdSituacao != 'E'
    END;

		BEGIN ----- Update Movimentos -----
			-- alterar o tipo de movimento de subscrição que usa conta reserva para o tipo Saída C/ Direitos Adquiridos CAC
			UPDATE Intgr.IntegracoesMovimentos
				SET 
					--TipoSubscricao = 'H',
					MetodoPagamento = 'R',
					UsaDinheiroContaReserva = 1,
					MovimentoValorBruto = MovimentoValorLiquido,
					TaxaComissao = null,
					ComissaoValor = 0
				WHERE	IdIntegracao = @p_IdIntegracao
						AND IdChunk = @p_IdChunk
						AND IdTipoMovimento in ('I','S')
						AND IdSituacao != 'E'


			-- Apagar Impostos dos movimentos
			DELETE FROM Intgr.IntegracoesMovimentosImpostos
			WHERE IdIntegrationRecord in (
					SELECT IdIntegrationRecord 
					FROM Intgr.IntegracoesMovimentos
					WHERE IdIntegracao = @p_IdIntegracao
						AND IdChunk = @p_IdChunk
						AND IdTipoMovimento in ('I','S')
						AND IdSituacao != 'E' 
			)

			UPDATE Intgr.IntegracoesMovimentos
				SET 
					IdSituacao = 'V'
			WHERE	IdIntegracao = @p_IdIntegracao
					AND IdChunk = @p_IdChunk
					AND IdSituacao != 'E'
   		END;

		BEGIN ----- Reembolso Conta Reserva -----
			DECLARE @ContaReservaAReembolsar TYP_CONTARESERVAREEMBOLSAR;
			DECLARE @NumeroRegistos INT;

			INSERT INTO @ContaReservaAReembolsar
            (IdEntidadeSuperiora, 
            IdContrato, 
            Valor_Reembolsar,
            Fundo
            )
                SELECT IdEntidadeSuperiora, 
                        IdContrato_ContaReserva, 
                        #ContratosValorDisponivel.Valor_ContaReserva,
                        Fundo
                FROM #ContratosValorDisponivel

			-- guardar o numero de registos
			SET @NumeroRegistos =
			(
				SELECT COUNT(IdContrato)
				FROM @ContaReservaAReembolsar
			);

			IF @NumeroRegistos != 0
				BEGIN
					--Chamar SP para criar as linhas de reembolso parcial na tabela IntegraçõesMovimentos
					EXEC pr_IntegracoesMovimentos_ReembolsarContasReserva 
							@listaDadosContasReserva = @ContaReservaAReembolsar, 
							@p_IdIntegracao = @p_IdIntegracao, 
							@p_IdChunk = @p_IdChunk;
			END;
		END;

        DROP TABLE #ContratosValorDisponivel;
	END;