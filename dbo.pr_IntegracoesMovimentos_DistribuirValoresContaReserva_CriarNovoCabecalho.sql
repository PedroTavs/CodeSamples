
-- =============================================
-- Author:	Pedro Tavares
-- Create date: 2020-01-29
-- Description:	Método que trata dos movimentos de detalhe com finalidades diferentes mas que possuem o mesmo cabeçalho.
--				Um detalhe usa Conta reserva, o outro não usa conta reserva mas partilham o mesmo cabeçalho.
-- =============================================
CREATE PROCEDURE dbo.pr_IntegracoesMovimentos_DistribuirValoresContaReserva_CriarNovoCabecalho (
	@p_IdIntegracao			NUMERIC(18, 0),
	@p_IdChunk				NUMERIC(9, 0),
	@p_IdIntegrationRecord	NUMERIC(18,0),
	@p_UsaContaReserva		BIT
	)
AS
BEGIN
	SET NOCOUNT ON;

	-- variáveis de apoio
	DECLARE
		@NovaPercentagem			NUMERIC(10,2),
		@p_despesas					NUMERIC(18,7),
		-- Impostos
		@decTaxaComissaoIndividual	NUMERIC(18,12),
		@decValorTotalIndividual	NUMERIC(18,12),
		@decComissaoIndividual		NUMERIC(18,12),
		@decValorUPsIndividual		NUMERIC(18,12),
		@decNumeroUPsIndividual		NUMERIC(18,12),
		@xmlSubscricoesImpostosXml	XML,
		@blnValorValido				BIT,
		@strMensagem				VARCHAR(500),
		@IdFundo					NUMERIC(18,0),
		@IdProduto					NUMERIC(18,0),
		@IdContribuinte				NUMERIC(18,0),
		@TipoContribuinte			VARCHAR(1),
		@TipoContrato				VARCHAR(1),
		@TipoMovimento				VARCHAR(1),
		@DataMovimento				Date,
		@IdContrato					NUMERIC(18,0),
		@p_Conta					VARCHAR(50),
		@tblMovimentosIndividuaisImpostos [dbo].[typ_MovimentosIndividuaisImpostos],
		@decTotalImpostos			NUMERIC(18,12),
		@IdContratoProdutoParticipante NUMERIC(18,0),
		@EntidadeParticipante		NUMERIC(18,0),
		@NovoIdIntegrationRecordParent NUMERIC(18,0),
		@NumSequencia					INT;

	-- atualizar percentagens
	SET @NovaPercentagem = 100;

	-- Se movimento não UsaConta reserva então recalcular Comissao / Impostos
	IF(@p_UsaContaReserva = 0)
	BEGIN
		-- obter informações do Movimento
		SELECT 
			@decNumeroUPsIndividual = IM.NumeroUnidadesParticipacao,
			@IdFundo = IM.Fundo,
			@IdProduto = IM.Produto,
			@IdContribuinte = IM.EntidadeContribuinte,
			@TipoContribuinte = IM.TipoContribuicao,
			@TipoContrato = IM.TipoContrato,
			@TipoMovimento = IM.TipoSubscricao,
			@DataMovimento = IM.DataMovimento,
			@p_Conta = IM.Contas,
			@EntidadeParticipante = IM.IdIntegrationRecordParticipante,
			@decValorUPsIndividual = IM.MovimentoValorBruto,
			@decValorTotalIndividual = IM.MovimentoValorBruto,
			@p_despesas = IM.DespesasValor
		FROM Intgr.IntegracoesMovimentos AS IM
		WHERE IdIntegracao = @p_IdIntegracao
			AND IdChunk = @p_IdChunk
			AND IdIntegrationRecord=@p_IdIntegrationRecord;

		-- Obter Id Contrato
		SELECT @IdContrato = C.IdContrato,
				@IdContratoProdutoParticipante = C.IdContratoProdutoParticipante
		FROM Intgr.IntegracoesMovimentos IM
		INNER JOIN ContratosProduto AS CP
			ON CP.NumeroContratoProduto = IM.NumeroContratoProduto
			AND CP.IdEntidadeContribuinte = IM.EntidadeContribuinte
		INNER JOIN ContratosProdutoParticipantes AS CPP
			ON CPP.IdContratoProduto = CP.IdContratoProduto
			AND CPP.IdEntidadeParticipante = IM.EntidadeParticipante
		INNER JOIN Contratos AS C
			ON C.IdContratoProdutoParticipante = CPP.IdContratoProdutoParticipante
			AND C.IdFundo = IM.Fundo
		WHERE	IdIntegracao = @p_IdIntegracao
				AND IdChunk = @p_IdChunk
				AND IdIntegrationRecord = @p_IdIntegrationRecord

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
			@p_PlanoPensoes = null,
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
			@p_PercentagemCapital = @NovaPercentagem,
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

		-- Update valores do movimento
		UPDATE Intgr.IntegracoesMovimentos
			SET MovimentoValorLiquido = @decValorTotalIndividual - @decComissaoIndividual - @p_despesas,
				TaxaComissao = @decTaxaComissaoIndividual,
				ComissaoValor = @decComissaoIndividual,
				PercentagemDistribuicao = @NovaPercentagem
		WHERE IdIntegrationRecord = @p_IdIntegrationRecord
			AND IdIntegracao = @p_IdIntegracao
			AND IdChunk = @p_IdChunk;

		IF(@decTotalImpostos <> 0)
		BEGIN
			--Inserir novos Impostos para subscrição Individual
			UPDATE Intgr.IntegracoesMovimentosImpostos
			SET
				IdCodigoImposto = TXML.IdCodigoImposto,
				IdOrdem = TXML.IdOrdem,
				IdTipoMovimento = 	'S',
				IdTabelasTaxas = TXML.IdTabelasTaxas,
				ValorImposto = TXML.ValorImposto,
				TaxaAplicada = TXML.TaxaAplicada,
				ValorCalculado = TXML.ValorCalculado,
				TaxaCalculada = TXML.TaxaCalculada,
				ValorManual	= TXML.ValorManual
			FROM dbo.[udf_MovimentosIndividuaisImpostos_GetRecordsFromXml](@xmlSubscricoesImpostosXml) AS TXML
			WHERE IdIntegrationRecord = @p_IdIntegrationRecord
		END;
	END
	ELSE
	BEGIN 
		SELECT 
			@decValorTotalIndividual = IM.MovimentoValorBruto
		FROM Intgr.IntegracoesMovimentos AS IM 
		WHERE IdIntegrationRecord = @p_IdIntegrationRecord
			AND IdIntegracao = @p_IdIntegracao
			AND IdChunk = @p_IdChunk;
	END;

	-- Criar Novo Cabeçalho
	SET @NumSequencia =
	(
		SELECT TOP 1 NumeroSequencia
		FROM Intgr.IntegracoesMovimentos
		WHERE IdIntegracao = @p_IdIntegracao
				AND IdChunk = @p_IdChunk
		ORDER BY NumeroSequencia DESC
	) + 1;

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

	-- confirmar cada valor individualmente
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
			TipoSubscricao, -- TipoSubscricao - nvarchar
			TipoReembolso, -- TipoReembolso - nvarchar
			0, -- NumeroUnidadesParticipacao - decimal											
			MovimentoValorBruto, -- MovimentoValorBruto - decimal																						
			MovimentoValorLiquido,--MC.ValorTotal - MC.Comissao, -- MovimentoValorLiquido - decimal								
			0, -- Cotacao - decimal
			Motivo, -- Motivo - nvarchar
			CalcularIRS, -- CalcularIRS - bit
			MetodoPagamento, -- MetodoPagamento - nvarchar
			Angariador, -- Angariador - int
			ComissaoValor, -- ComissaoValor - decimal														
			DespesasValor, -- DespesasValor - decimal
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
			@p_UsaContaReserva,
			IM.TipoDistribuicao
	FROM Intgr.IntegracoesMovimentos IM
	WHERE IdIntegracao = @p_IdIntegracao
			AND IdChunk = @p_IdChunk
			AND IdIntegrationRecord = @p_IdIntegrationRecord; 

	-- Update do novo Cabeçalho ao movimento de Detalhe
	SET @NovoIdIntegrationRecordParent = SCOPE_IDENTITY();

	UPDATE Intgr.IntegracoesMovimentos
		SET IdIntegrationRecordParent = @NovoIdIntegrationRecordParent
	WHERE IdIntegrationRecord = @p_IdIntegrationRecord
			AND IdIntegracao = @p_IdIntegracao
			AND IdChunk = @p_IdChunk;
END