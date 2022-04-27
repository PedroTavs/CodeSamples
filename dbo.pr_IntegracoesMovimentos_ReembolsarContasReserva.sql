
-- ==================================================================
-- Author:		Pedro Tavares
-- Create date:		2019-03-28
-- Review Author:	Pedro Tavares
-- Review Date:		2021-02-08
-- Description:		SP que cria o reembolso na  Contas Reserva
-- ==================================================================
CREATE PROCEDURE [dbo].[pr_IntegracoesMovimentos_ReembolsarContasReserva]
(
    @listaDadosContasReserva [dbo].[typ_ContaReservaReembolsar] READONLY, 
    @p_IdIntegracao          NUMERIC(18, 0), 
    @p_IdChunk               NUMERIC(9, 0),
	@p_PlanoPensoes			 VARCHAR(10) = NULL

/*A estrutura dos dados recebidos é a seguinte:
        IdEntidadeSuperiora			NUMERIC(18, 0), 
         IdContrato					NUMERIC(18, 0), 
         ValorDisponivel_Unidades	NUMERIC(18, 7), 
         Fundo						SMALLINT */
)
AS
    BEGIN
        SET NOCOUNT ON;
				
        BEGIN ----- Inserir Movimento Reembolso Cabeçalho em IntegracoesMovimentos -----

            DECLARE @numeroSeq			NUMERIC(18, 0);		-- Número de Sequência para os movimentos de Reemboslso
            DECLARE @date				DATE;				-- Data Movimento
			DECLARE @MetodoPagamento	nvarchar(1);		-- Método de Pagamento
			DECLARE @Contas				nvarchar(500);		-- Contas


            SET @numeroSeq =
            (
                SELECT TOP 1 NumeroSequencia
                FROM Intgr.IntegracoesMovimentos
                WHERE IdChunk = @p_IdChunk
                      AND IdIntegracao = @p_IdIntegracao
                ORDER BY NumeroSequencia DESC
            ) + 1;

			SELECT TOP 1 
				@date = DataMovimento,
				@MetodoPagamento = MetodoPagamento,
				@Contas = Contas
			FROM Intgr.IntegracoesMovimentos
			WHERE IdChunk = @p_IdChunk
				AND IdIntegracao = @p_IdIntegracao
			ORDER BY NumeroSequencia DESC			

            INSERT INTO Intgr.IntegracoesMovimentos
            (
                --IdIntegrationRecord - this column value is auto-generated
                IdIntegracao, 
                IdChunk, 
                NumeroSequencia, 
                IdTipoIntegracaoDados, 
                IdTipoMovimento, 
                NumeroMovimento, 
                EntidadeContribuinte, 
                EntidadeParticipante, 
                Produto, 
                Fundo, 
                DataMovimento, 
                IdContratoProduto, 
                [NumeroContratoProduto], 
                IdContrato, 
                [NumeroContrato], 
                TipoContrato, 
                TipoSubscricao, 
                TipoReembolso, 
                NumeroUnidadesParticipacao, 
                MovimentoValorBruto, 
                MovimentoValorLiquido, 
                Cotacao, 
                Motivo, 
                CalcularIRS, 
                MetodoPagamento, 
                Angariador,
			    TaxaComissao,
                ComissaoValor, 
                DespesasValor, 
                DataPrimeiroMovimento, 
                Rendimento, 
                ProdutoReembolsado, 
                NumeroReembolso, 
                Contas, 
                CapitalPercentagem, 
                TipoContribuicao, 
                ContaBancaria, 
                IdSituacaoMovimento, 
                PercentagemDistribuicao, 
                Observacoes, 
                IdMovimentoExterno1, 
                IdMovimentoExterno2, 
                IdContratoExterno1, 
                IdContratoExterno2, 
                IdIntegrationRecordParticipante, 
                IdIntegrationRecordContribuinte, 
                IdTipoCalculoValores, 
                ForcarCriarContrato, 
                IdEntidadeNib, 
                IdSociedadeGestoraExterna, 
                IdSociedadeGestoraPlano, 
                Flexibilizacao, 
                AnularContrato, 
                IdIntegrationRecordParent, 
                IdSituacao,
				ManterUnidades
            )
            SELECT DISTINCT 
                @p_IdIntegracao, -- IdIntegracao - numeric
                @p_IdChunk, -- IdChunk - numeric
                @numeroSeq, -- NumeroSequencia - numeric
                1, -- IdTipoIntegracaoDados - numeric
                'R', -- IdTipoMovimento - varchar
                0, -- NumeroMovimento - int
                0, -- EntidadeContribuinte - int
                CPP.IdEntidadeParticipante, -- EntidadeParticipante - int						
                CP.IdProduto, -- Produto - smallint
                C.IdFundo, -- Fundo	  -- Fundo - smallint
                @date, -- DataMovimento - datetime
                ISNULL(CP.IdContratoProduto, 0), -- IdContratoProduto - NUMERI
                ISNULL(CP.NumeroContratoProduto, 0), -- ContratoMulti - int
                DCR.IdContrato, -- IdContrato - NUMERIC				
                0, -- Contrato - int
                'P', -- TipoContrato - nvarchar
                NULL, -- TipoSubscricao - nvarchar
                'D', -- TipoReembolso - nvarchar
                DCR.Valor_Reembolsar / UltimaCotacao.Cotacao, -- NumeroUnidadesParticipacao - decimal
				DCR.Valor_Reembolsar, -- MovimentoValorBruto - decimal
                DCR.Valor_Reembolsar, -- MovimentoValorLiquido -decimal
                ISNULL(CT.Cotacao, 0), -- Cotacao - decimal
                NULL, -- Motivo - nvarchar
                0, -- CalcularIRS - bit
                @MetodoPagamento, -- MetodoPagamento - nvarchar
                NULL, -- IdEntidadeAngariador - int
				0,	-- TaxaComissao
                0, -- ComissaoValor - decimal
                0, -- DespesasValor - decimal
                NULL, -- DataPrimeiroMovimento - datetime
                0, -- Rendimento - decimal
                NULL, -- ProdutoReembolsado - smallint
                NULL, -- NumeroReembolso - int
                @Contas, -- Contas - varchar
                100, -- CapitalPercentagem - decimal
                'A', -- TipoContribuicao - nvarchar
                NULL, -- ContaBancaria - decimal
                CASE WHEN CT.Cotacao IS NULL 
					THEN 'M'
					ELSE 'A'
				END , -- IdSituacaoMovimento - varchar
                100, -- PercentagemDistribuicao - decimal
                'CR', -- Observacoes - nvarchar
                NULL, -- IdMovimentoExterno1 - nvarchar
                NULL, -- IdMovimentoExterno2 - nvarchar
                NULL, -- IdContratoExterno1 - nvarchar
                NULL, -- IdContratoExterno2 - nvarchar
                IE.IdIntegrationRecord, -- IdIntegrationRecordParticipante
                NULL, -- IdIntegrationRecordContribuinte
                '', -- IdTipoCalculoValores - nvarchar
                0, 
                NULL, -- IdEntidadeNib
                NULL, 
                NULL, 
                0, -- Flexibilizacao
                0, -- AnularContrato
                0, -- IdIntegrationRecordParent
                'C',	  -- IdSituacao - varchar
				0 -- ManterUnidades - bit
            FROM @listaDadosContasReserva AS DCR
			INNER JOIN Contratos AS C ON C.IdContrato = DCR.IdContrato
			INNER JOIN ContratosProdutoParticipantes AS CPP ON CPP.IdContratoProdutoParticipante = C.IdContratoProdutoParticipante
			INNER JOIN ContratosProduto AS CP ON CP.IdContratoProduto = CPP.IdContratoProduto
            LEFT JOIN dbo.Cotacoes AS CT ON CT.IdFundo = DCR.Fundo 
											AND CT.DataCotacao = @date
			LEFT JOIN Intgr.IntegracoesEntidades AS IE 
				ON IE.IdIntegracao = @p_IdIntegracao
				AND IE.IdPapelTipoCriar = 'P'
			OUTER APPLY
			(
				SELECT TOP (1) 
					Q.[Cotacao]
				FROM dbo.[Cotacoes] AS Q 
				WHERE Q.[IdFundo] = C.[IdFundo]
						AND Q.[DataCotacao] <= @date
				ORDER BY Q.[DataCotacao] DESC
			) UltimaCotacao
            WHERE C.IdContrato = DCR.IdContrato
                    AND C.IdFundo = DCR.Fundo;			
                         

        END;

        BEGIN ----- Inserir Movimento Reembolso Detalhe em IntegracoesMovimentos -----
            ---- Preencher tabela de integração com dados dos detalhes
            INSERT INTO Intgr.IntegracoesMovimentos
            (
                --IdIntegrationRecord - this column value is auto-generated
                IdIntegracao, 
                IdChunk, 
                NumeroSequencia, 
                IdTipoIntegracaoDados, 
                IdTipoMovimento, 
                NumeroMovimento, 
                EntidadeContribuinte, 
                EntidadeParticipante, 
                Produto, 
                Fundo, 
                DataMovimento, 
                IdContratoProduto, 
                [NumeroContratoProduto], 
                IdContrato, 
                [NumeroContrato], 
                TipoContrato, 
                TipoSubscricao, 
                TipoReembolso, 
                NumeroUnidadesParticipacao, 
                MovimentoValorBruto, 
                MovimentoValorLiquido, 
                Cotacao, 
                Motivo, 
                CalcularIRS, 
                MetodoPagamento, 
                Angariador, 
			    TaxaComissao,
                ComissaoValor, 
                DespesasValor, 
                DataPrimeiroMovimento, 
                Rendimento, 
                ProdutoReembolsado, 
                NumeroReembolso, 
                Contas, 
                CapitalPercentagem, 
                TipoContribuicao, 
                ContaBancaria, 
                IdSituacaoMovimento, 
                PercentagemDistribuicao, 
                Observacoes, 
                IdMovimentoExterno1, 
                IdMovimentoExterno2, 
                IdContratoExterno1, 
                IdContratoExterno2, 
                IdIntegrationRecordParticipante, 
                IdIntegrationRecordContribuinte, 
                IdTipoCalculoValores, 
                ForcarCriarContrato, 
                IdEntidadeNib, 
                IdSociedadeGestoraExterna, 
                IdSociedadeGestoraPlano, 
                Flexibilizacao, 
                AnularContrato, 
                IdIntegrationRecordParent, 
                IdSituacao,
				ManterUnidades
            )
            SELECT @p_IdIntegracao, -- IdIntegracao - numeric
                    @p_IdChunk, -- IdChunk - numeric
                    @numeroSeq + 1, -- NumeroSequencia - numeric
                    1, -- IdTipoIntegracaoDados - numeric
                    'O', -- IdTipoMovimento - varchar
                    0, -- NumeroMovimento - int
                    0, -- EntidadeContribuinte - int
                    IM.EntidadeParticipante, -- EntidadeParticipante - int
                    IM.Produto, -- Produto - smallint
                    IM.Fundo, -- Fundo - smallint
                    IM.DataMovimento, -- DataMovimento - datetime
                    IM.IdContratoProduto, -- IdContratoProduto - int
                    IM.[NumeroContratoProduto], -- ContratoMulti - int
                    IM.IdContrato, -- IdContrato
                    IM.IdContrato, -- Contrato - int
                    IM.TipoContrato, -- TipoContrato - nvarcharss
                    IM.TipoSubscricao, -- TipoSubscricao - nvarchar
                    IM.TipoReembolso, -- TipoReembolso - nvarchar
                    IM.NumeroUnidadesParticipacao, -- NumeroUnidadesParticipacao - decimal
                    IM.MovimentoValorBruto, -- MovimentoValorBruto - decimal
                    IM.MovimentoValorLiquido, -- MovimentoValorLiquido - decimal
                    IM.Cotacao, -- Cotacao - decimal
                    IM.Motivo, -- Motivo - nvarchar
                    IM.CalcularIRS, -- CalcularIRS - bit
                    IM.MetodoPagamento, -- MetodoPagamento - nvarchar
                    IM.Angariador, -- Angariador - int
					IM.TaxaComissao, --Taxa Comissao
                    IM.ComissaoValor, -- ComissaoValor - decimal
                    IM.DespesasValor, -- DespesasValor - decimal
                    IM.DataPrimeiroMovimento, -- DataPrimeiroMovimento - datetime
                    IM.Rendimento, -- Rendimento - decimal
                    IM.ProdutoReembolsado, -- ProdutoReembolsado - smallint
                    IM.NumeroReembolso, -- NumeroReembolso - int
                    IM.Contas, -- Contas - varchar
                    IM.CapitalPercentagem, -- CapitalPercentagem - decimal
                    IM.TipoContribuicao, -- TipoContribuicao - nvarchar
                    IM.ContaBancaria, -- ContaBancaria - decimal
                    IM.IdSituacaoMovimento, -- IdSituacaoMovimento - varchar
                    IM.PercentagemDistribuicao, -- PercentagemDistribuicao - decimal
                    IM.Observacoes, -- Observacoes - nvarchar
                    NULL, -- IdMovimentoExterno1 - nvarchar
                    NULL, -- IdMovimentoExterno2 - nvarchar
                    NULL, -- IdContratoExterno1 - nvarchar
                    NULL, -- IdContratoExterno2 - nvarchar
                    IM.IdIntegrationRecordParticipante, -- IdIntegrationRecordParticipante - numeric
                    IM.IdIntegrationRecordContribuinte, -- IdIntegrationRecordContribuinte - numeric
                    IM.IdTipoCalculoValores, -- IdTipoCalculoValores - nvarchar
                    IM.ForcarCriarContrato, 
                    NULL, -- IdEntidadeNib
                    IM.IdSociedadeGestoraExterna, 
                    IM.IdSociedadeGestoraPlano, 
                    IM.Flexibilizacao, 
                    IM.AnularContrato, 
                    IM.IdIntegrationRecord, -- IdIntegrationRecordParent - numeric
                    IM.IdSituacao,	  -- IdSituacao - varchar
					IM.ManterUnidades -- ManterUnidades - bit
            FROM Intgr.IntegracoesMovimentos IM
            WHERE IM.NumeroSequencia = @numeroSeq
                    AND IM.IdIntegracao = @p_IdIntegracao
                    AND IM.IdChunk = @p_IdChunk;

            -- Inserir na tabela de informações dos movimentos (Planos de pensões)
            INSERT INTO Intgr.IntegracoesMovimentosInformacoes 
			(
				IdIntegrationRecord, 
				IdInformacao, 
				Valor
			)
            SELECT 
				IM.IdIntegrationRecord, 
				2000, 
				CASE WHEN @p_PlanoPensoes IS NULL
					THEN Sub.Valor
					ELSE @p_PlanoPensoes
				END
            FROM Intgr.IntegracoesMovimentos IM
            OUTER APPLY
            (
	            SELECT TOP 1 IMII.Valor
	            FROM Intgr.IntegracoesMovimentos IMI
	            INNER JOIN Intgr.IntegracoesMovimentosInformacoes IMII
		            ON IMII.IdIntegrationRecord = IMI.IdIntegrationRecord
	            WHERE IMI.IdIntegracao = @p_IdIntegracao
				            AND IM.IdChunk = @p_IdChunk
				            AND IdTipoMovimento = 'I'
            ) Sub
            WHERE IM.NumeroSequencia = @numeroSeq + 1
                    AND IM.IdIntegracao = @p_IdIntegracao
                    AND IM.IdChunk = @p_IdChunk
                    AND IM.IdTipoMovimento = 'O';
        END;

		BEGIN ----- Validar movimentos de Reembolso -----
			EXEC pr_IntegracoesMovimentos_ValidacoesActualizarEstadoIntegracao 
				@p_IdIntegracao=@p_IdIntegracao,
				@p_IdArea='MS';
		END;
    END;