-- =============================================
-- Author:		Pedro Tavares
-- Create date:		2019-04-04
-- Reviewer:		Pedro Tavares
-- Review date:		2021-02-12
-- Description:		SP que cria o movimento de subscrição cabeçalho e detalhe na tabela IntegracaoMovimentos
-- =============================================
CREATE PROCEDURE [dbo].[pr_IntegracoesMovimentos_DistribuirContaReserva_InserirSubscricao]
(
	@p_IdIntegracao     NUMERIC(18, 0), 
	@p_IdChunk          NUMERIC(9, 0), 
	@p_MovimentosACriar TYP_MOVIMENTOSACRIAR READONLY, -- Vou ter no maximo 2 movimentos, 1 movimento de subscricao que usa conta reserva e outro movimento de subscricao que usa o excedente.
	@p_PlanoPensoes	 VARCHAR(10) = NULL
)

/*
Estrutura do parametro p_MovimentosACriar
 IdIntegrationRecord NUMERIC(18, 0), 
 IdContratoCReserva  NUMERIC(18, 0), 
 IdEntidadeSuperiora NUMERIC(18, 0), 
 Despesas            NUMERIC(18, 2), 
 TaxaComissao        NUMERIC(18, 2), 
 Comissao            NUMERIC(18, 2), 
 ValorUPs            NUMERIC(18, 2), 
 ValorTotal          NUMERIC(18, 2), 
 NumeroUPs           NUMERIC(18, 2), 
 ContaReserva        INT
*/

AS
    BEGIN

        SET NOCOUNT ON;
		BEGIN ----- Movimentos Subscrições Cabeçalho e Detalhe da Conta Reserva -----
			DECLARE @IdIntegrationRecord_CR_Cab NUMERIC (18,0),
					@IdIntegrationRecord_CR_Det NUMERIC (18,0),
					@NumSequencia INT,
					@p_despesas numeric(18,7),
					-- Impostos
					@decTaxaComissaoIndividual numeric(18,12),
					@decValorTotalIndividual numeric(18,12),
					@decComissaoIndividual numeric(18,12),
					@decValorUPsIndividual numeric(18,12),
					@decNumeroUPsIndividual numeric(18,12),
					@xmlSubscricoesImpostosXml xml,
					@blnValorValido bit,
					@strMensagem varchar(500),
					-- help
					@IdFundo  numeric(18,0),
					@IdProduto  numeric(18,0),
					@IdContribuinte numeric(18,0),
					@TipoContribuinte Varchar(1),
					@TipoContrato varchar(1),
					@TipoMovimento varchar(1),
					@DataMovimento Date,
					@IdContrato numeric(18,0),
					@p_Conta varchar(50),
					@tblMovimentosIndividuaisImpostos [dbo].[typ_MovimentosIndividuaisImpostos],
					@decTotalImpostos numeric(18,12),
					@IdContratoProdutoParticipante numeric(18,0),
					@EntidadeParticipante numeric(18,0),
					@IdIntegrationRecord_Inserted numeric(18,0),
					@IdMetodoPagamento varchar(1);

			-- Create Movimento Cabeçalho da Conta Reserva
			SET @NumSequencia =
			(
				SELECT TOP 1 NumeroSequencia
				FROM Intgr.IntegracoesMovimentos
				WHERE IdIntegracao = @p_IdIntegracao
						AND IdChunk = @p_IdChunk
				ORDER BY NumeroSequencia DESC
			) + 1;

			-- Inserção do movimento Cabeçalho Conta Reserva
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
			[NumeroContratoProduto], 
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
			DataDevida,
			IdMovimentoExterno1, 
			IdMovimentoExterno2, 
			IdContratoExterno1, 
			IdContratoExterno2, 
			IdIntegrationRecordParticipante, 
			IdIntegrationRecordContribuinte, 
			IdTipoCalculoValores, 
			ForcarCriarContrato, 
			IdEntidadeNib, 
			IdIntegrationRecordParent, 
			IdSituacao, 
			UsaDinheiroContaReserva,
			TipoDistribuicao
			)
					SELECT  @p_IdIntegracao, -- IdIntegracao - numeric
							@p_IdChunk, -- IdChunk - numeric
							@NumSequencia, -- NumeroSequencia - numeric
							1, -- IdTipoIntegracaoDados - numeric
							'S', -- IdTipoMovimento - varchar
							0, -- NumeroMovimento - int
							EntidadeContribuinte, -- EntidadeContribuinte - int										
							EntidadeParticipante, -- EntidadeParticipante - int										
							Produto, -- Produto - smallint
							0, -- Fundo - smallint
							DataMovimento, -- DataMovimento - datetime
							NumeroContratoProduto, -- NumeroContratoProduto - int
							NumeroContrato, -- NumeroContrato - int																	
							TipoContrato, -- TipoContrato - nvarchar
							IM.TipoSubscricao, -- TipoSubscricao - nvarchar
							TipoReembolso, -- TipoReembolso - nvarchar
							0, -- NumeroUnidadesParticipacao - decimal											
							0,--MC.ValorTotal, -- MovimentoValorBruto - decimal																						
							0,--MC.ValorTotal - MC.Comissao, -- MovimentoValorLiquido - decimal								
							0, -- Cotacao - decimal
							Motivo, -- Motivo - nvarchar
							CalcularIRS, -- CalcularIRS - bit
							'R', -- MetodoPagamento - nvarchar
							Angariador, -- Angariador - int
							0, -- ComissaoValor - decimal														
							0, -- DespesasValor - decimal
							DataPrimeiroMovimento, -- DataPrimeiroMovimento - datetime
							NULL, -- Rendimento - decimal
							ProdutoReembolsado, -- ProdutoReembolsado - smallint
							NumeroReembolso, -- NumeroReembolso - int
							Contas, -- Contas - varchar
							CapitalPercentagem, -- CapitalPercentagem - decimal
							TipoContribuicao, -- TipoContribuicao - nvarchar
							ContaBancaria, -- ContaBancaria - decimal
							IdSituacaoMovimento, -- IdSituacaoMovimento - varchar
							NULL, -- PercentagemDistribuicao - decimal
							NULL, -- Observacoes - nvarchar
							DataMovimento,
							NULL, -- IdMovimentoExterno1 - nvarchar
							NULL, -- IdMovimentoExterno2 - nvarchar
							NULL, -- IdContratoExterno1 - nvarchar
							NULL, -- IdContratoExterno2 - nvarchar
							IdIntegrationRecordParticipante, -- IdIntegrationRecordParticipante - numeric
							IdIntegrationRecordContribuinte, -- IdIntegrationRecordContribuinte - numeric
							IdTipoCalculoValores, -- IdTipoCalculoValores - nvarchar
							ForcarCriarContrato, 
							IdEntidadeNib, -- IdEntidadeNib
							0, -- IdIntegrationRecordParent - numeric
							IdSituacao, -- IdSituacao - varchar
							MC.ContaReserva,
							IM.TipoDistribuicao
					FROM Intgr.IntegracoesMovimentos IM
					INNER JOIN @p_MovimentosACriar MC 
						ON IM.IdIntegrationRecord = MC.IdIntegrationRecord
					WHERE IdIntegracao = @p_IdIntegracao
							AND IdChunk = @p_IdChunk
							AND MC.ContaReserva = 1;

			SET @IdIntegrationRecord_CR_Cab = SCOPE_IDENTITY();

			-- Create Movimento Detalhe da Conta Reserva
			SET @NumSequencia +=1

			SELECT 
				@decNumeroUPsIndividual = MC.NumeroUPs,
				@IdFundo = IM.Fundo,
				@IdProduto = IM.Produto,
				@IdContribuinte = IM.EntidadeContribuinte,
				@TipoContribuinte = IM.TipoContribuicao,
				@TipoContrato = IM.TipoContrato,
				@TipoMovimento = IM.TipoSubscricao,
				@DataMovimento = IM.DataMovimento,
				@IdContrato = MC.IdContratoCReserva,
				@p_Conta = IM.Contas,
				@EntidadeParticipante = IM.EntidadeParticipante,
				@decValorUPsIndividual = MC.ValorUPs,
				@decValorTotalIndividual = MC.ValorTotal,
				@p_despesas = IM.DespesasValor
			FROM Intgr.IntegracoesMovimentos IM
			INNER JOIN @p_MovimentosACriar MC 
				ON IM.IdIntegrationRecord = MC.IdIntegrationRecord
			WHERE IdIntegracao = @p_IdIntegracao
							AND IdChunk = @p_IdChunk
							AND MC.ContaReserva = 1;

			-- CalcularValores
			EXEC pr_SubscricoesIndividuais_CalcularValoresPorValorTotal 
				@p_IdFundo = @IdFundo,
				@p_IdProduto = @IdProduto,
				@p_IdContribuinte = @IdContribuinte,
				@p_TipoContribuinte =  @TipoContribuinte,
				@p_TipoContrato = @TipoContrato,
				@p_TipoMovimento = 'S',
				@p_DataMovimento = @DataMovimento,
				@p_IdContrato = @IdContrato,
				@p_PlanoPensoes = @p_PlanoPensoes,
				@p_Conta = @p_Conta,
				@p_CalcularComissoes = 1,
				@p_EstadoSubscricao = 'A',
				@p_Despesas = @p_Despesas OUTPUT,
				@p_TaxaComissao = @decTaxaComissaoIndividual OUTPUT,
				@p_Comissao = @decComissaoIndividual OUTPUT,
				@p_ValorUPs = @decValorUPsIndividual OUTPUT,
				@p_ValorTotal = @decValorTotalIndividual OUTPUT,
				@p_NumeroUPs = @decNumeroUPsIndividual OUTPUT,
				@p_MovimentosImpostosXml = @xmlSubscricoesImpostosXml OUTPUT,
				@p_ValorValido = @blnValorValido OUTPUT,
				@p_Mensagem = @strMensagem OUTPUT,
				@p_ValidaComissao = 0;


			-- Inserção do movimento Detalhe Conta Reserva
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
			[NumeroContratoProduto], 
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
			DataDevida,
			IdMovimentoExterno1, 
			IdMovimentoExterno2, 
			IdContratoExterno1, 
			IdContratoExterno2, 
			IdIntegrationRecordParticipante, 
			IdIntegrationRecordContribuinte, 
			IdTipoCalculoValores, 
			ForcarCriarContrato, 
			IdEntidadeNib, 
			IdIntegrationRecordParent, 
			IdSituacao, 
			UsaDinheiroContaReserva,
			TipoDistribuicao
			)
					SELECT @p_IdIntegracao, -- IdIntegracao - numeric
							@p_IdChunk, -- IdChunk - numeric
							@NumSequencia, -- NumeroSequencia - numeric
							1, -- IdTipoIntegracaoDados - numeric
							'I', -- IdTipoMovimento - varchar
							0, -- NumeroMovimento - int
							EntidadeContribuinte, -- EntidadeContribuinte - int										
							EntidadeParticipante, -- EntidadeParticipante - int										
							Produto, -- Produto - smallint
							Fundo, -- Fundo - smallint
							DataMovimento, -- DataMovimento - datetime
							NumeroContratoProduto, -- ContratoMulti - int
							IdContrato, -- Contrato - int																	
							TipoContrato, -- TipoContrato - nvarchar
							IM.TipoSubscricao, -- TipoSubscricao - nvarchar
							TipoReembolso, -- TipoReembolso - nvarchar
							@decNumeroUPsIndividual, -- NumeroUnidadesParticipacao - decimal											
							@decValorTotalIndividual, -- MovimentoValorBruto - decimal																						
							@decValorUPsIndividual, -- MovimentoValorLiquido - decimal					
							Cotacao, -- Cotacao - decimal
							Motivo, -- Motivo - nvarchar
							CalcularIRS, -- CalcularIRS - bit
							'R', -- MetodoPagamento - nvarchar
							Angariador, -- Angariador - int
							0, -- ComissaoValor - decimal														
							@p_despesas, -- DespesasValor - decimal
							DataPrimeiroMovimento, -- DataPrimeiroMovimento - datetime
							Rendimento, -- Rendimento - decimal
							ProdutoReembolsado, -- ProdutoReembolsado - smallint
							NumeroReembolso, -- NumeroReembolso - int
							Contas, -- Contas - varchar
							100, -- CapitalPercentagem - decimal
							TipoContribuicao, -- TipoContribuicao - nvarchar
							ContaBancaria, -- ContaBancaria - decimal
							IdSituacaoMovimento, -- IdSituacaoMovimento - varchar
							100, -- PercentagemDistribuicao - decimal
							NULL, -- Observacoes - nvarchar
							DataDevida, -- DataDevida - datetime
							NULL, -- IdMovimentoExterno1 - nvarchar
							NULL, -- IdMovimentoExterno2 - nvarchar
							NULL, -- IdContratoExterno1 - nvarchar
							NULL, -- IdContratoExterno2 - nvarchar
							IdIntegrationRecordParticipante, -- IdIntegrationRecordParticipante - numeric
							IdIntegrationRecordContribuinte, -- IdIntegrationRecordContribuinte - numeric
							IdTipoCalculoValores, -- IdTipoCalculoValores - nvarchar
							ForcarCriarContrato, 
							IdEntidadeNib, -- IdEntidadeNib
							@IdIntegrationRecord_CR_Cab, -- IdIntegrationRecordParent - numeric
							IdSituacao, -- IdSituacao - varchar
							MC.ContaReserva,
							IM.TipoDistribuicao
					FROM Intgr.IntegracoesMovimentos IM
						INNER JOIN @p_MovimentosACriar MC ON IM.IdIntegrationRecord = MC.IdIntegrationRecord
					WHERE IdIntegracao = @p_IdIntegracao
							AND IdChunk = @p_IdChunk
							AND MC.ContaReserva = 1;

			SET @IdIntegrationRecord_CR_Det = SCOPE_IDENTITY();

			-- Inserir informação do movimento (Plano de Pensões)
			IF(@p_PlanoPensoes IS NOT NULL)
			BEGIN

				INSERT INTO Intgr.IntegracoesMovimentosInformacoes
				(
					IdIntegrationRecord,
					IdInformacao,
					Valor
				)
				VALUES (@IdIntegrationRecord_CR_Det, 2000, @p_PlanoPensoes);

			END;

			SET @decComissaoIndividual = NULL;
			SET @decNumeroUPsIndividual = 0;
			SET @decTaxaComissaoIndividual = NULL;
			SET @decTotalImpostos = 0;
			SET @decValorTotalIndividual = 0;
			SET @decValorUPsIndividual = 0;
			SET @p_despesas = 0;
			SET @xmlSubscricoesImpostosXml =null;
		END;

		BEGIN ----- Movimentos Subscrições Normais Cabeçalho e Detalhe -----
			DECLARE @IdIntegrationRecord_Normal_Cab numeric (18,0);

			-- Insert
			SET @NumSequencia += 1;

			-- Inserção do movimento Cabeçalho normal
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
			[NumeroContratoProduto], 
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
			DataDevida,
			IdMovimentoExterno1, 
			IdMovimentoExterno2, 
			IdContratoExterno1, 
			IdContratoExterno2, 
			IdIntegrationRecordParticipante, 
			IdIntegrationRecordContribuinte, 
			IdTipoCalculoValores, 
			ForcarCriarContrato, 
			IdEntidadeNib, 
			IdIntegrationRecordParent, 
			IdSituacao, 
			UsaDinheiroContaReserva,
			TipoDistribuicao
			)
					SELECT @p_IdIntegracao, -- IdIntegracao - numeric
							@p_IdChunk, -- IdChunk - numeric
							@NumSequencia, -- NumeroSequencia - numeric
							1, -- IdTipoIntegracaoDados - numeric
							'S', -- IdTipoMovimento - varchar
							0, -- NumeroMovimento - int
							EntidadeContribuinte, -- EntidadeContribuinte - int										
							EntidadeParticipante, -- EntidadeParticipante - int										
							Produto, -- Produto - smallint
							0, -- Fundo - smallint
							DataMovimento, -- DataMovimento - datetime
							NumeroContratoProduto, -- NumeroContratoProduto - int
							NumeroContrato, -- NumeroContrato - int																	
							TipoContrato, -- TipoContrato - nvarchar
							IM.TipoSubscricao, -- TipoSubscricao - nvarchar
							TipoReembolso, -- TipoReembolso - nvarchar
							0, -- NumeroUnidadesParticipacao - decimal											
							0,--MC.ValorTotal, -- MovimentoValorBruto - decimal																						
							0,--MC.ValorTotal - MC.Comissao, -- MovimentoValorLiquido - decimal								
							0, -- Cotacao - decimal
							Motivo, -- Motivo - nvarchar
							CalcularIRS, -- CalcularIRS - bit
							MetodoPagamento, -- MetodoPagamento - nvarchar
							Angariador, -- Angariador - int
							0, -- ComissaoValor - decimal														
							0, -- DespesasValor - decimal
							DataPrimeiroMovimento, -- DataPrimeiroMovimento - datetime
							NULL, -- Rendimento - decimal
							ProdutoReembolsado, -- ProdutoReembolsado - smallint
							NumeroReembolso, -- NumeroReembolso - int
							Contas, -- Contas - varchar
							CapitalPercentagem, -- CapitalPercentagem - decimal
							TipoContribuicao, -- TipoContribuicao - nvarchar
							ContaBancaria, -- ContaBancaria - decimal
							IdSituacaoMovimento, -- IdSituacaoMovimento - varchar
							NULL, -- PercentagemDistribuicao - decimal
							NULL, -- Observacoes - nvarchar
							DataMovimento,
							NULL, -- IdMovimentoExterno1 - nvarchar
							NULL, -- IdMovimentoExterno2 - nvarchar
							NULL, -- IdContratoExterno1 - nvarchar
							NULL, -- IdContratoExterno2 - nvarchar
							IdIntegrationRecordParticipante, -- IdIntegrationRecordParticipante - numeric
							IdIntegrationRecordContribuinte, -- IdIntegrationRecordContribuinte - numeric
							IdTipoCalculoValores, -- IdTipoCalculoValores - nvarchar
							ForcarCriarContrato, 
							IdEntidadeNib, -- IdEntidadeNib
							0, -- IdIntegrationRecordParent - numeric
							IdSituacao, -- IdSituacao - varchar
							MC.ContaReserva,
							IM.TipoDistribuicao
					FROM Intgr.IntegracoesMovimentos IM
					INNER JOIN @p_MovimentosACriar MC 
						ON IM.IdIntegrationRecord = MC.IdIntegrationRecord
					WHERE IdIntegracao = @p_IdIntegracao
							AND IdChunk = @p_IdChunk
							AND MC.ContaReserva = 0;

			SET @IdIntegrationRecord_Normal_Cab = SCOPE_IDENTITY();

			-- Create Movimento Detalhe da Conta Reserva
			SET @NumSequencia +=1;

			-- Inserção do movimento Detalhe Subscrição Normal
			-- Impostos
			SELECT 
				@decNumeroUPsIndividual = MC.NumeroUPs,
				@IdFundo = IM.Fundo,
				@IdProduto = IM.Produto,
				@IdContribuinte = IM.EntidadeContribuinte,
				@TipoContribuinte = IM.TipoContribuicao,
				@TipoContrato = IM.TipoContrato,
				@TipoMovimento = IM.TipoSubscricao,
				@DataMovimento = IM.DataMovimento,
				@p_Conta = IM.Contas,
				@EntidadeParticipante = IM.IdIntegrationRecordParticipante,
				@decValorUPsIndividual = MC.ValorUPs,
				@decValorTotalIndividual = MC.ValorTotal,
				@p_despesas = IM.DespesasValor
			FROM Intgr.IntegracoesMovimentos IM
			INNER JOIN @p_MovimentosACriar MC 
				ON IM.IdIntegrationRecord = MC.IdIntegrationRecord
			WHERE IdIntegracao = @p_IdIntegracao
							AND IdChunk = @p_IdChunk
							AND MC.ContaReserva = 0;
		
							
			-- Obter Id Contrato
			SELECT @IdContrato = C.IdContrato,
					@IdContratoProdutoParticipante = C.IdContratoProdutoParticipante
			FROM @p_MovimentosACriar AS MC 
			INNER JOIN Intgr.IntegracoesMovimentos IM
				ON IM.IdIntegrationRecord = MC.IdIntegrationRecord
			INNER JOIN ContratosProduto AS CP
				ON CP.NumeroContratoProduto = IM.NumeroContratoProduto
				AND CP.IdEntidadeContribuinte = IM.EntidadeContribuinte
			INNER JOIN ContratosProdutoParticipantes AS CPP
				ON CPP.IdContratoProduto = CP.IdContratoProduto
				AND CPP.IdEntidadeParticipante = IM.EntidadeParticipante
			INNER JOIN Contratos AS C
				ON C.IdContratoProdutoParticipante = CPP.IdContratoProdutoParticipante
				AND C.IdFundo = IM.Fundo
			WHERE IdIntegracao = @p_IdIntegracao
							AND IdChunk = @p_IdChunk
							AND MC.ContaReserva = 0;

			-- CalcularValores
			EXEC pr_SubscricoesIndividuais_CalcularValoresPorValorTotal
				@p_IdFundo = @IdFundo,
				@p_IdProduto = @IdProduto,
				@p_IdContribuinte = @IdContribuinte,
				@p_TipoContribuinte =  @TipoContribuinte,
				@p_TipoContrato = @TipoContrato,
				@p_TipoMovimento = 'S',
				@p_DataMovimento = @DataMovimento,
				@p_IdContrato = @IdContrato,
				@p_PlanoPensoes = @p_PlanoPensoes,
				@p_Conta = @p_Conta,
				@p_CalcularComissoes = 1,
				@p_EstadoSubscricao = 'A',
				@p_Despesas = @p_Despesas OUTPUT,
				@p_TaxaComissao = @decTaxaComissaoIndividual OUTPUT,
				@p_Comissao = @decComissaoIndividual OUTPUT,
				@p_ValorUPs = @decValorUPsIndividual OUTPUT,
				@p_ValorTotal = @decValorTotalIndividual OUTPUT,
				@p_NumeroUPs = @decNumeroUPsIndividual OUTPUT,
				@p_MovimentosImpostosXml = @xmlSubscricoesImpostosXml OUTPUT,
				@p_ValorValido = @blnValorValido OUTPUT,
				@p_Mensagem = @strMensagem OUTPUT

			-- Calcular Impostos
			EXEC dbo.pr_Fiscalidade_CalcularImpostos
				@p_Produto = @IdProduto,
				@p_Fundo = @IdFundo,
				@p_IdTipoMovimento = 'S',
				@p_IdMovimentoIndividual = 0,
				@p_IdEntidadeParticipante = @EntidadeParticipante,
				@p_IdMotivoReembolso = NULL,
				@p_DataMovimento = @DataMovimento,
				@p_NumeroUPs = @decNumeroUPsIndividual,
				@p_ValorUPs = @decValorUPsIndividual,
				@p_Comissao = @decComissaoIndividual, 
				@p_Moeda = '',
				@p_TotalInvestido = @decValorTotalIndividual,
				@p_Rendimento = NULL,
				@p_Contas = @p_Conta,
				@p_PercentagemCapital = 100,
				@p_TipoContribuicao = @TipoContribuinte,
				-- Contrato
				@p_IdContratoProdutoParticipante = @IdContratoProdutoParticipante,
				@p_IdContrato = @IdContrato,
				-- Rendimento Empresa
				@p_RendimentoEmpresa = NULL,
				-- Total investido Empresa
				@p_TotalInvestidoEmpresa = NULL,
				@p_IdTipoReembolso = NULL,
				@p_RecalcularImpostos = 1,
				@p_ValorTotalMovimentoMultiplo = @decValorTotalIndividual,
				@p_UniqueIdentifier = null,
				-- User Job
				@p_UserJob = null,
				-- Valor de IRS calculado
				@p_tblMovimentosIndividuaisImpostos = @tblMovimentosIndividuaisImpostos,
				@p_ImpostosResultados = @xmlSubscricoesImpostosXml OUTPUT,
				@p_TotalImpostos = @decTotalImpostos OUTPUT,
				@p_ValorTotal = @decValorTotalIndividual OUTPUT;

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
				[NumeroContratoProduto],
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
				DataDevida,
				IdMovimentoExterno1, 
				IdMovimentoExterno2, 
				IdContratoExterno1, 
				IdContratoExterno2, 
				IdIntegrationRecordParticipante, 
				IdIntegrationRecordContribuinte, 
				IdTipoCalculoValores, 
				ForcarCriarContrato, 
				IdEntidadeNib, 
				IdIntegrationRecordParent, 
				IdSituacao,
				UsaDinheiroContaReserva,
				TipoDistribuicao
				)
			SELECT  @p_IdIntegracao, -- IdIntegracao - numeric
					@p_IdChunk, -- IdChunk - numeric
					@NumSequencia, -- NumeroSequencia - numeric
					1, -- IdTipoIntegracaoDados - numeric
					'I', -- IdTipoMovimento - varchar
					0, -- NumeroMovimento - int
					EntidadeContribuinte, -- EntidadeContribuinte - int										
					EntidadeParticipante, -- EntidadeParticipante - int										
					Produto, -- Produto - smallint
					Fundo, -- Fundo - smallint
					DataMovimento, -- DataMovimento - datetime
					NumeroContratoProduto, -- ContratoMulti - int
					NumeroContrato, -- Contrato - int																	
					TipoContrato, -- TipoContrato - nvarchar
					IM.TipoSubscricao, -- TipoSubscricao - nvarchar
					TipoReembolso, -- TipoReembolso - nvarchar
					@decNumeroUPsIndividual, -- NumeroUnidadesParticipacao - decimal											
					@decValorTotalIndividual, -- MovimentoValorBruto - decimal																						
					@decValorUPsIndividual, -- MovimentoValorLiquido - decimal
					Cotacao, -- Cotacao - decimal
					Motivo, -- Motivo - nvarchar
					CalcularIRS, -- CalcularIRS - bit
					MetodoPagamento, -- MetodoPagamento - nvarchar
					Angariador, -- Angariador - int
					@decTaxaComissaoIndividual, -- TaxaComissao
					@decComissaoIndividual, -- ComissaoValor - decimal	
					@p_despesas, -- DespesasValor - decimal
					DataPrimeiroMovimento, -- DataPrimeiroMovimento - datetime
					Rendimento, -- Rendimento - decimal
					ProdutoReembolsado, -- ProdutoReembolsado - smallint
					NumeroReembolso, -- NumeroReembolso - int
					Contas, -- Contas - varchar
					CapitalPercentagem, -- CapitalPercentagem - decimal
					TipoContribuicao, -- TipoContribuicao - nvarchar
					ContaBancaria, -- ContaBancaria - decimal
					IdSituacaoMovimento, -- IdSituacaoMovimento - varchar
					100, -- PercentagemDistribuicao - decimal
					Observacoes, -- Observacoes - nvarchar
					DataDevida,
					NULL, -- IdMovimentoExterno1 - nvarchar
					NULL, -- IdMovimentoExterno2 - nvarchar
					NULL, -- IdContratoExterno1 - nvarchar
					NULL, -- IdContratoExterno2 - nvarchar
					IdIntegrationRecordParticipante, -- IdIntegrationRecordParticipante - numeric
					IdIntegrationRecordContribuinte, -- IdIntegrationRecordContribuinte - numeric
					IdTipoCalculoValores, -- IdTipoCalculoValores - nvarchar
					ForcarCriarContrato, 
					IdEntidadeNib, -- IdEntidadeNib
					@IdIntegrationRecord_Normal_Cab, -- IdIntegrationRecordParent - numeric
					IdSituacao, -- IdSituacao - varchar
					MC.ContaReserva,
					IM.TipoDistribuicao
            FROM Intgr.IntegracoesMovimentos IM
                INNER JOIN @p_MovimentosACriar MC ON IM.IdIntegrationRecord = MC.IdIntegrationRecord
            WHERE IdIntegracao = @p_IdIntegracao
                    AND IdChunk = @p_IdChunk
                    AND MC.ContaReserva = 0;

			-- Obter último ID Inserido
			SELECT @IdIntegrationRecord_Inserted = SCOPE_IDENTITY()

			IF(@decTotalImpostos <> 0)
			BEGIN
				--Inserir novos Impostos para subscrição Individual
				INSERT INTO Intgr.IntegracoesMovimentosImpostos 
				(
					IdIntegrationRecord,
					IdCodigoImposto,
					IdOrdem,
					IdTipoMovimento,
					IdTabelasTaxas,
					ValorImposto,
					TaxaAplicada,
					ValorCalculado,
					TaxaCalculada,
					ValorManual
				)
				SELECT
					@IdIntegrationRecord_Inserted,
					TXML.IdCodigoImposto,
					TXML.IdOrdem,
					'S',
					TXML.IdTabelasTaxas,
					TXML.ValorImposto,
					TXML.TaxaAplicada,
					TXML.ValorCalculado,
					TXML.TaxaCalculada,
					TXML.ValorManual
				FROM dbo.[udf_MovimentosIndividuaisImpostos_GetRecordsFromXml](@xmlSubscricoesImpostosXml) AS TXML;
			END;

			-- Inserir Informação do movimento (Plano de Pensões)
			IF(@p_PlanoPensoes IS NOT NULL)
			BEGIN

				INSERT INTO Intgr.IntegracoesMovimentosInformacoes
				(
					IdIntegrationRecord,
					IdInformacao,
					Valor
				)
				VALUES (@IdIntegrationRecord_Inserted, 2000, @p_PlanoPensoes);

			END;

    END;
END;