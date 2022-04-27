-----------------------------------------------------------------
-- Autor:		Pedro Tavares
-- Data:		2019-04-26
-- Reviewer:		Pedro Tavares
-- Review Date:		2021-01-28
-- Descrição:		Recalcular as cotações dos movimentos Temporários
-----------------------------------------------------------------
CREATE PROCEDURE [dbo].[pr_WrkCotacoesImportar_RecalculoMovimentostemporarios]
(
	@p_UserJob           VARCHAR(10), 
    @p_ListaFundosUpdate dbo.typ_ListaFundosUpdate READONLY,
	@p_Username        VARCHAR(50)
)
AS
    BEGIN
        SET NOCOUNT ON;
		                
		BEGIN ----- Reembolsos -----
			BEGIN ----- Obter Lista dos Movimentos de Reembolso a serem Recalculados (servirá para posteriormente recalcular os valores todos de cada reembolso) -----

				CREATE TABLE #ReembolsosARecalcular
				(RowNumber				INT, 
				 IdReembolsoIndividual	NUMERIC(18, 0), 
				 IdReembolsoMultiplo	NUMERIC(18, 0), 
				 IdContrato				NUMERIC(18, 0), 
				 RM_DataReembolso		DATE, 
				 IdFundo				INT, 
				 Contas					VARCHAR(500),
				 NumeroUPs_Novo			DECIMAL(19,12),
				 Criar					bit,
				 PlanoPensoes		   NVARCHAR(10),
				 ManterUnidades			bit
				);
				INSERT INTO #ReembolsosARecalcular
				(RowNumber, 
				 IdReembolsoIndividual, 
				 IdReembolsoMultiplo, 
				 IdContrato, 
				 RM_DataReembolso, 
				 IdFundo, 
				 Contas,
				 NumeroUPs_Novo,
				 Criar,
				 PlanoPensoes,
				 ManterUnidades
				)
					   SELECT ROW_NUMBER() OVER(
							  ORDER BY RI.IdReembolsoIndividual, RM.DataReembolso) AS RowNumber, 
							  RI.IdReembolsoIndividual, 
							  RI.IdReembolsoMultiplo, 
							  RI.IdContrato, 
							  RM.DataReembolso, 
							  C.IdFundo, 
							  RM.Contas,
							  RI.NumeroUPs,
							  1,
							  ISNULL(MI.Valor, ''),
							  RME.ManterUnidades
					   FROM ReembolsosIndividuais AS RI
							INNER JOIN ReembolsosMultiplos AS RM ON RI.IdReembolsoMultiplo = RM.IdReembolsoMultiplo
							INNER JOIN Contratos AS C ON C.IdContrato = RI.IdContrato
							INNER JOIN @p_ListaFundosUpdate AS LFU ON LFU.DataCotacao = RM.DataReembolso
																	  AND LFU.IdFundo = C.IdFundo
							INNER JOIN Cotacoes AS C0 ON C0.DataCotacao = RM.DataReembolso
														 AND C0.IdFundo = LFU.IdFundo
							INNER JOIN CfgClt.Fundos AS F ON F.IdFundo = LFU.IdFundo --adicionado Inner join para garantir que apenas se faz o update para os fundos com cotação conhecida.
							INNER JOIN ReembolsosMultiplosExtensao AS RME ON RME.IdReembolsoMultiplo = RM.IdReembolsoMultiplo
							LEFT JOIN dbo.MovimentosInformacoes AS MI 
								ON MI.IdMovimentoIndividual = RI.IdReembolsoIndividual
								AND MI.TipoMovimento = 'R'
								AND MI.Info = 2000
					   WHERE IdEstado IN ('M', 'N') -- Temporário ou Não Concretizado
							 AND F.SuporteCotacaoDesconhecida = 1
							 AND (RME.IdNaturezaReembolso = 'T'
								  OR RME.IdNaturezaReembolso = 'P')
							 AND RI.Recalculado = 0;
			END;
			
			--
			
			/*
			 * Descontinuado
			 * Os reembolsos temporários agora guardam as unidades
			 * O número de UPs guardado nos reembolsos totais já reflete o saldo disponível no contrato
			BEGIN ----- Inserir novo Numero UPs dos Reembolsos Totais na tabela temp -----
				UPDATE	#ReembolsosARecalcular				 
					SET 
						NumeroUPs_Novo = ValorUPContrato.ValorUpContrato
				FROM #ReembolsosARecalcular RAR
				INNER JOIN dbo.Contratos AS C 
					ON C.IdContrato = RAR.IdContrato
				INNER JOIN @p_ListaFundosUpdate AS LFU 
					ON LFU.DataCotacao = RAR.RM_DataReembolso
					AND LFU.IdFundo = C.IdFundo
				INNER JOIN dbo.Cotacoes AS C0 
					ON C0.DataCotacao = RAR.RM_DataReembolso
					AND C0.IdFundo = LFU.IdFundo
				INNER JOIN CfgClt.Fundos AS F 
					ON F.IdFundo = LFU.IdFundo 
				INNER JOIN dbo.ReembolsosMultiplosExtensao AS RME 
					ON RME.IdReembolsoMultiplo = RAR.IdReembolsoMultiplo
					AND RME.IdNaturezaReembolso = 'T'
				INNER JOIN dbo.ReembolsosIndividuais AS RI 
					ON RI.IdReembolsoIndividual = RAR.IdReembolsoIndividual
				INNER JOIN dbo.ReembolsosMultiplos AS RM 
					ON RM.IdReembolsoMultiplo = RI.IdReembolsoMultiplo
				-- Obter saldo do contrato em UPs
				OUTER APPLY
				(
					SELECT
						SaldoNUP
					FROM dbo.udf_Contratos_ObterSaldoAData(RAR.Contas, C0.DataCotacao, RM.TipoContribuicao, C.IdContrato, RAR.PlanoPensoes)
				) ValorUPContrato(ValorUpContrato)
				WHERE RAR.ManterUnidades = 0; -- Manter Valor Patrimonial - Recalcular UPs
			END;
			*/

			--

			BEGIN ----- Inserir novo Numero UPs dos Reembolsos Parciais na tabela temp -----
				-- 1) Verificar se o saldo disponível no contrato é suficiente e diferente de 0 para realizar o rembolso parcial.
				-- Se for suficiente então utiliza-se o valor do reembolso.
				-- Se não for suficiente então utiliza-se o valor restante do contrato.
				
				UPDATE #ReembolsosARecalcular
					SET 
						NumeroUPs_Novo = Valor.UnidadesReembolsar		
				FROM #ReembolsosARecalcular AS RAR
						INNER JOIN ReembolsosIndividuais AS RI ON RI.IdReembolsoIndividual = RAR.IdReembolsoIndividual
						INNER JOIN ReembolsosMultiplos AS RM ON RM.IdReembolsoMultiplo = RI.IdReembolsoMultiplo
						INNER JOIN Contratos AS C ON C.IdContrato = RAR.IdContrato
						INNER JOIN @p_ListaFundosUpdate AS LFU ON LFU.DataCotacao = RAR.RM_DataReembolso
																AND LFU.IdFundo = C.IdFundo
						INNER JOIN Cotacoes AS C0 ON C0.DataCotacao = RAR.RM_DataReembolso
													AND C0.IdFundo = LFU.IdFundo
						INNER JOIN CfgClt.Fundos AS F ON F.IdFundo = LFU.IdFundo --adicionado Inner join para garantir que apenas se faz o update para os fundos com cotação conhecida.
						INNER JOIN ReembolsosMultiplosExtensao AS RME ON RME.IdReembolsoMultiplo = RAR.IdReembolsoMultiplo
															AND RME.IdNaturezaReembolso = 'P'
						-- Como é um reembolso parcial, vamos buscar o numero de UPs do contrato e passamos para Valor de UPs
						OUTER APPLY
				(
					SELECT CASE
								WHEN(SaldoNUP IS NULL
									OR SaldoNUP = 0)
								THEN 0
								ELSE SaldoNUP * LFU.Cotacao
							END
					FROM dbo.udf_Contratos_ObterSaldoAData(RAR.Contas, LFU.DataCotacao, RM.TipoContribuicao, C.IdContrato, RAR.PlanoPensoes) -- retorna o numero de UPs do contrato
				) VUP_Contrato(ValorUPsContrato)  -- retorna o valor das ups
				-- Verificar se valor é válido para reembolsar
						OUTER APPLY
				(
					SELECT CASE
								WHEN VUP_Contrato.ValorUPsContrato > RI.ValorUPs
								THEN RI.ValorUPs
								WHEN VUP_Contrato.ValorUPsContrato = 0
								THEN 0
								ELSE VUP_Contrato.ValorUPsContrato
							END
				) ValorReembolsar(ValorUPs) 
				-- Calcular o Valor das UPs
						OUTER APPLY
				(
					SELECT RoundValue
					FROM dbo.udf_Math_RoundUPs(C.IdFundo, (ValorReembolsar.ValorUPs / LFU.Cotacao))
				) AS Valor(UnidadesReembolsar)   -- Calcular o numero de unidades a reembolsar
				WHERE RAR.ManterUnidades = 0; -- Manter Valor Patrimonial - Recalcular UPs
			END;

			--

			BEGIN ----- Update valores do Número de UPs dos Reembolsos um a um -----
				DECLARE @MaxNumber INT,
						@MinNumber INT,
						@IdReembolsoIndividual NUMERIC(18, 0),
						@decNumeroUPsIndividual decimal(19, 12) = 0;

				SET @MaxNumber = (SELECT COUNT(IdReembolsoIndividual) FROM #ReembolsosARecalcular)
				SET @MinNumber = 0;

				-- percorrer lista de reembolsos
				WHILE @MaxNumber > @MinNumber
				BEGIN
					SET @MinNumber = @MinNumber + 1;
									
						SELECT
							@IdReembolsoIndividual = RAR.IdReembolsoIndividual,
							@decNumeroUPsIndividual = RAR.NumeroUPs_Novo
						FROM #ReembolsosARecalcular AS RAR
						-- Obter total contrato disponível para garantir que apenas se atualizam os reembolsos válidos (evitar criar 2 reembolsos totais para o mesmo fundo)
						OUTER APPLY
						(
							SELECT SaldoNUP
							FROM dbo.udf_Contratos_ObterSaldoAData(RAR.Contas, RAR.RM_DataReembolso, 'A', RAR.IdContrato, RAR.PlanoPensoes)
						) ValorUPContrato(ValorUpContrato)
						WHERE RowNumber = @MinNumber
							and ValorUPContrato.ValorUpContrato > 0

					-- atualizar linha de reembolso a recalcular para evitar atualizar reembolsos inválidos
					-- a variável @decNumeroUPsIndividual será <> 0 se for um reembolso válido
					UPDATE #ReembolsosARecalcular
						SET Criar = CASE	WHEN @decNumeroUPsIndividual > 0
											THEN 1
											ELSE 0
									END
					WHERE IdReembolsoIndividual = @IdReembolsoIndividual

					-- reset variáveis
					SET @decNumeroUPsIndividual = 0;
					SET @IdReembolsoIndividual = 0;
				END;
			END;

			--

			BEGIN ----- Recálculo dos Valores dos Reembolsos (comissão, valorUps, ValorTotal etc) -----
				
				Declare @IdFundo SMALLINT,
						@IdProduto SMALLINT,
						@TipoReembolso VARCHAR(1),
						@IdMotivoReembolso BIGINT,
						@IdContribuinte INT,
						@TipoContrato VARCHAR(1),
						@DataMovimento DATETIME,
						@IdContrato NUMERIC(18, 0),
						@Contas VARCHAR(400),
						@PlanoPensoes NVARCHAR(10),
						@Moeda VARCHAR(3),
						@TipoContribuicao VARCHAR(1),
						@PercentagemCapital DECIMAL(5, 2),
						@RecalcularImpostos BIT,
						@decRendimento decimal(15, 2) = 0,
						@decRendimentoIndividual decimal(15, 2) = 0,
						@decTotalInvestidoIndividual decimal(15, 2) = 0,
						@decTaxaComissaoIndividual decimal(5, 2) = 0,
						@decComissaoIndividual decimal(10, 2) = 0,
						@decValorUPsIndividual decimal(15, 2) = 0,
						@decValorTotalIndividual decimal(15, 2) = 0,
						@decRendimentoEmpresa decimal(19, 12) = 0,
						@decTotalInvestidoEmpresa decimal(19, 12) = 0,
						@decTotalImpostos decimal (19,12)=0,
						@decValorTotal  decimal (19,12)=0,
						@decDespesas decimal (15,2) = 0,
						@idContratoProdutoParticipante int,
						@tblMovimentosIndividuaisImpostos [dbo].[typ_MovimentosIndividuaisImpostos],
						@tblMovimentosIndividuaisImpostosComissoes [dbo].[typ_MovimentosIndividuaisImpostos],
						@xmlReembolsosImpostosXml XML,
						@xmlReembolsosImpostosComissoesXml XML,
						@blnValorValido bit,
						@strMensagem varchar(400),
						@IdEntidadePartipante int,
						@strUniqueIdentifier nvarchar(24),
						@IdTipoReembolso varchar(1),
						@datDataCotacao datetime,
						@intIdReembolsoMultiplo numeric(18, 0);

				-- Variáveis de apoio à iteração
				SET @MaxNumber =
				(
					SELECT COUNT(IdContrato)
					FROM #ReembolsosARecalcular
				);
				SET @MinNumber = 0;

				SET @datDataCotacao =
				(
					SELECT TOP 1 DataCotacao
					FROM @p_ListaFundosUpdate
				);

				-- Percorrer cada reembolso para recalcular os valores todos.
				WHILE @MaxNumber > @MinNumber
				BEGIN
					SET @MinNumber = @MinNumber + 1;


					-- Salvaguardar contratos já reembolsados por outros reembolsos temporários nas iterações anteriores
					UPDATE RAR
					SET RAR.NumeroUPs_Novo = ValorReembolsar.Unidades,
						RAR.Criar = CASE WHEN ValorReembolsar.Unidades = 0 
										THEN 0 
										ELSE 1 
									END
					FROM #ReembolsosARecalcular AS RAR
					INNER JOIN ReembolsosIndividuais AS RI 
						ON RI.IdReembolsoIndividual = RAR.IdReembolsoIndividual
					INNER JOIN ReembolsosMultiplos AS RM 
						ON RM.IdReembolsoMultiplo = RI.IdReembolsoMultiplo
					OUTER APPLY
					(
						SELECT SaldoNUP
						FROM dbo.udf_Contratos_ObterSaldoAData(RAR.Contas, RAR.RM_DataReembolso, RM.TipoContribuicao, RAR.IdContrato, RAR.PlanoPensoes)
					) ValorUPContrato(Saldo)
					OUTER APPLY
					(
						SELECT CASE
							WHEN ValorUPContrato.Saldo > RAR.NumeroUPs_Novo
							THEN RAR.NumeroUPs_Novo
							ELSE ValorUPContrato.Saldo
						END
					) ValorReembolsar(Unidades)
					WHERE RAR.RowNumber = @MinNumber;

					-- Guardar aviso de movimento não concretizado caso não haja saldo no contrato
					INSERT INTO WORK.WrkRecalculoMensagens (UserJob, JobDate, Mensagem, Visualizada)
					SELECT
						@p_UserJob,
						@datDataCotacao,
						'Contrato sem saldo. Movimento ' 
							+ CAST(RAR.IdReembolsoMultiplo AS VARCHAR) 
							+ ' - Fundo ' 
							+ CAST(C.IdFundo AS VARCHAR) 
							+ ' não concretizado.',
						0
					FROM #ReembolsosARecalcular AS RAR
					INNER JOIN dbo.Contratos AS C
							ON C.IdContrato = RAR.IdContrato
					WHERE RAR.RowNumber = @MinNumber
						AND RAR.NumeroUPs_Novo = 0
						AND RAR.Criar = 0;

					-- Atualizar estado do movimento
					UPDATE RM
					SET IdEstado = 'N' -- Não Concretizado
					FROM #ReembolsosARecalcular AS RAR
					INNER JOIN dbo.ReembolsosMultiplos AS RM
						ON RM.IdReembolsoMultiplo = RAR.IdReembolsoMultiplo
					WHERE RAR.RowNumber = @MinNumber
						AND RAR.NumeroUPs_Novo = 0
						AND RAR.Criar = 0;


					-- Obter dados para recalcular valores
					SELECT @IdFundo = RAR.IdFundo, 
							@IdProduto = CP.IdProduto, 
							@IdReembolsoIndividual = RAR.IdReembolsoIndividual, 
							@TipoReembolso = RM.IdTipoReembolso, 
							@IdMotivoReembolso = RI.IdMotivoReembolso, 
							@IdContribuinte = CP.IdEntidadeContribuinte,
							@TipoContrato = C.IdTipoContrato, 
							@DataMovimento = RAR.RM_DataReembolso, 
							@IdContrato = RAR.IdContrato, 
							@Contas = RM.Contas, 
							@Moeda = RI.Moeda, 
							@TipoContribuicao = RM.TipoContribuicao, 
							@PercentagemCapital = RM.PercentagemCapital, 
							@RecalcularImpostos = 1,
							@decNumeroUPsIndividual = RAR.NumeroUPs_Novo,
							@IdEntidadePartipante = CPP.IdEntidadeParticipante,
							@IdTipoReembolso = RM.IdTipoReembolso,
							@idContratoProdutoParticipante = CPP.IdContratoProdutoParticipante,
							@PlanoPensoes = RAR.PlanoPensoes,
							@decDespesas = RI.Despesas,
							@intIdReembolsoMultiplo = RAR.IdReembolsoMultiplo
					FROM ReembolsosIndividuais AS RI
							INNER JOIN #ReembolsosARecalcular AS RAR ON RI.IdReembolsoIndividual = RAR.IdReembolsoIndividual
							INNER JOIN ReembolsosMultiplos AS RM ON RM.IdReembolsoMultiplo = RAR.IdReembolsoMultiplo
							INNER JOIN Contratos AS C ON C.IdContrato = RI.IdContrato
							INNER JOIN ContratosProdutoParticipantes AS CPP ON CPP.IdContratoProdutoParticipante = C.IdContratoProdutoParticipante
							INNER JOIN ContratosProduto AS CP ON CP.IdContratoProduto = CPP.IdContratoProduto
					WHERE	RAR.RowNumber = @MinNumber
							AND RAR.Criar = 1;	
					
					-- Calcular Valores do reembolso
					EXEC pr_ReembolsosIndividuais_CalcularValoresPorNumeroUPOuValorUP 
							@p_IdFundo = @IdFundo, 
							@p_IdProduto = @IdProduto, 
							@p_IdReembolsoIndividual = @IdReembolsoIndividual, 
							@p_TipoReembolso = @TipoReembolso, 
							@p_IdMotivoReembolso = @IdMotivoReembolso, 
							@p_IdContribuinte = @IdContribuinte, 
							@p_TipoContrato = @TipoContrato, 
							@p_DataMovimento = @DataMovimento, 
							@p_IdContrato = @IdContrato, 
							@p_Contas = @Contas,
							@p_PlanoPensoes = @PlanoPensoes,
							@p_CalcularComissao = 0, 
							@p_CalcularPorNumeroUP = 1, -- este é 0
							@p_Moeda = @Moeda, 
							@p_TipoContribuicao = @TipoContribuicao, 
							@p_PercentagemCapital = @PercentagemCapital, 
							@p_RecalcularImpostos = @RecalcularImpostos, 
							@p_UserJob = @p_UserJob,
							-- alteração nova		
							@p_Rendimento = @decRendimento OUTPUT,
							@p_TotalInvestido = @decTotalInvestidoIndividual OUTPUT,
							@p_TaxaComissao = @decTaxaComissaoIndividual OUTPUT,
							@p_Comissao = @decComissaoIndividual OUTPUT,
							@p_ValorUPs = @decValorUPsIndividual OUTPUT,
							@p_Despesas = @decDespesas OUTPUT,
							@p_ValorTotal = @decValorTotalIndividual OUTPUT,
							@p_NumeroUPs = @decNumeroUPsIndividual OUTPUT,
							@p_ValorValido = @blnValorValido OUTPUT,
							@p_Mensagem = @strMensagem OUTPUT,
							@p_RecalculoUnidades = 1;

					-- Verificar se o total individual é negativo
					IF(@decValorTotalIndividual < 0)
					BEGIN
						-- Guardar aviso de movimento não concretizado
						INSERT INTO WORK.WrkRecalculoMensagens (UserJob, JobDate, Mensagem, Visualizada)
						SELECT
							@p_UserJob,
							@datDataCotacao,
							'Valor de Despesas superior ao valor reembolsado. Movimento ' 
								+ CAST(RAR.IdReembolsoMultiplo AS VARCHAR) 
								+ ' - Fundo ' 
								+ CAST(C.IdFundo AS VARCHAR) 
								+ ' não concretizado.',
							0
						FROM #ReembolsosARecalcular AS RAR
						INNER JOIN dbo.Contratos AS C
							ON C.IdContrato = RAR.IdContrato
						WHERE RAR.IdReembolsoIndividual = @IdReembolsoIndividual;

						-- Atualizar estado do movimento
						UPDATE RM
						SET IdEstado = 'N' -- Não Concretizado
						FROM #ReembolsosARecalcular AS RAR
						INNER JOIN dbo.ReembolsosMultiplos AS RM
							ON RM.IdReembolsoMultiplo = RAR.IdReembolsoMultiplo
						WHERE RAR.IdReembolsoIndividual = @IdReembolsoIndividual;
					END
					ELSE
					BEGIN
					-- Calcular o valor investido e rendimento
					SET @strUniqueIdentifier = left(newid(),24);

					EXEC dbo.[pr_ReembolsosIndividuais_CalcularRendimentoEValorInvestido]
						@p_IdProduto = @IdProduto,
						@p_IdFundo = @IdFundo,
						@p_IdReembolsoIndividual = 0,
						@p_IdEntidadeParticipante = @IdEntidadePartipante,
						@p_IdMotivoReembolso = @IdMotivoReembolso,
						@p_DataReembolso = @DataMovimento,
						@p_NumeroUPs = @decNumeroUPsIndividual,
						@p_ValorUPs = @decValorUPsIndividual,
						@p_Comissoes = @decComissaoIndividual,
						@p_Despesas = @decDespesas,
						@p_ValorTotal = @decValorTotalIndividual,
						@p_IdContrato = @IdContrato,
						@p_TotalInvestido = @decTotalInvestidoIndividual,
						@p_Rendimento = @decRendimento,
						@p_Contas = @Contas,
						@p_PercentagemCapital = @PercentagemCapital,
						@p_TipoContribuicao = @TipoContribuicao,
						@p_UsarWorkTable = 1,
						@p_UniqueIdentifier = @strUniqueIdentifier,
						@p_RendimentoOut = @decRendimentoIndividual OUTPUT, --
						@p_RendimentoEmpresa = @decRendimentoEmpresa OUTPUT,--
						@p_TotalInvestidoOut = @decTotalInvestidoIndividual OUTPUT,--
						@p_TotalInvestidoEmpresa = @decTotalInvestidoEmpresa OUTPUT,--
						@p_UserJob = @p_UserJob;
			
					
					-- Manter impostos de input manual
					INSERT INTO @tblMovimentosIndividuaisImpostos
					(
						--IdMovimentoIndividualImpostos,
						IdMovimentoIndividual,
						IdCodigoImposto,
						IdOrdem,
						IdTabelasTaxas,
						ValorImposto,
						TaxaAplicada,
						ValorCalculado,
						TaxaCalculada,
						ValorManual,
						IdFundo,
						ManterValor
					)
					SELECT
						--RII.IdReembolsoIndividualImposto,
						RAR.IdReembolsoIndividual,
						RII.IdCodigoImposto,
						RII.IdOrdem,
						RII.IdTabelasTaxas,
						RII.ValorImposto,
						RII.TaxaAplicada,
						RII.ValorCalculado,
						RII.TaxaCalculada,
						RII.ValorManual,
						RAR.IdFundo,
						1
					FROM dbo.ReembolsosIndividuais AS RI
					INNER JOIN #ReembolsosARecalcular AS RAR 
						ON RI.IdReembolsoIndividual = RAR.IdReembolsoIndividual
					INNER JOIN dbo.ReembolsosIndividuaisImpostos AS RII
						ON RII.IdReembolsoIndividual = RI.IdReembolsoIndividual
					INNER JOIN cfgbiz.Impostos AS I
						ON I.IdCodigoImposto = RII.IdCodigoImposto
					WHERE RAR.RowNumber = @MinNumber
						AND RAR.Criar = 1
						AND RII.ValorManual = 1
						AND I.IdTipoValor!='D';

					-- Calcular impostos
					EXEC dbo.pr_Fiscalidade_CalcularImpostos
						@p_Produto = @IdProduto,
						@p_Fundo = @IdFundo,
						@p_IdTipoMovimento = 'R',
						@p_IdMovimentoIndividual = 0,
						@p_IdEntidadeParticipante = @IdEntidadePartipante,
						@p_IdMotivoReembolso = @IdMotivoReembolso,
						@p_DataMovimento = @DataMovimento,
						@p_NumeroUPs = @decNumeroUPsIndividual,
						@p_ValorUPs = @decValorUPsIndividual,
						@p_Comissao = @decComissaoIndividual,
						@p_Despesas = @decDespesas,
						@p_Moeda = '',
						@p_TotalInvestido = @decTotalInvestidoIndividual,
						@p_Rendimento = @decRendimentoIndividual,
						@p_Contas = @Contas,
						@p_PercentagemCapital = @PercentagemCapital,
						@p_TipoContribuicao = @TipoContribuicao,
						-- Contrato
						@p_IdContratoProdutoParticipante = @idContratoProdutoParticipante,
						@p_IdContrato = @IdContrato,
						-- Rendimento Empresa
						@p_RendimentoEmpresa = @decRendimentoEmpresa,
						-- Total investido Empresa
						@p_TotalInvestidoEmpresa = @decTotalInvestidoEmpresa,
						@p_IdTipoReembolso = @IdTipoReembolso,
						@p_IdEstadoReembolso = 'A',
						@p_RecalcularImpostos = 1,
						@p_ValorTotalMovimentoMultiplo = @decValorTotal,
						@p_UniqueIdentifier = @strUniqueIdentifier,
						-- User Job
						@p_UserJob = @p_UserJob,
						-- Valor de IRS calculado
						@p_tblMovimentosIndividuaisImpostos = @tblMovimentosIndividuaisImpostos,
						@p_tblMovimentosIndividuaisImpostosComissoes = @tblMovimentosIndividuaisImpostosComissoes, 
						@p_ImpostosResultados = @xmlReembolsosImpostosXml OUTPUT,
						@p_ImpostosComissoesResultados = @xmlReembolsosImpostosComissoesXml OUTPUT,
						@p_TotalImpostos = @decTotalImpostos OUTPUT,
						@p_ValorTotal = @decValorTotalIndividual OUTPUT;

					IF(@decValorTotalIndividual < 0)
					BEGIN

						-- Guardar aviso de movimento não concretizado
						INSERT INTO WORK.WrkRecalculoMensagens (UserJob, JobDate, Mensagem, Visualizada)
						SELECT
							@p_UserJob,
							@datDataCotacao,
							'Valor de impostos superior ao valor reembolsado. Movimento ' 
								+ CAST(RAR.IdReembolsoMultiplo AS VARCHAR) 
								+ ' - Fundo ' 
								+ CAST(C.IdFundo AS VARCHAR) 
								+ ' não concretizado.',
							0
						FROM #ReembolsosARecalcular AS RAR
						INNER JOIN dbo.Contratos AS C
							ON C.IdContrato = RAR.IdContrato
						WHERE RAR.IdReembolsoIndividual = @IdReembolsoIndividual;

						-- Atualizar estado do movimento
						UPDATE RM
						SET IdEstado = 'N' -- Não Concretizado
						FROM #ReembolsosARecalcular AS RAR
						INNER JOIN dbo.ReembolsosMultiplos AS RM
							ON RM.IdReembolsoMultiplo = RAR.IdReembolsoMultiplo
						WHERE RAR.IdReembolsoIndividual = @IdReembolsoIndividual;

					END
					ELSE
					BEGIN

						IF(@decTotalImpostos <> 0)
						BEGIN
						
							DELETE RII
							FROM ReembolsosIndividuaisImpostos AS RII
							INNER JOIN Cfgbiz.Impostos AS I
								ON I.IdCodigoImposto = RII.IdCodigoImposto
							WHERE IdReembolsoIndividual = @IdReembolsoIndividual
								AND I.IdTipoValor = 'I';

							-- Inserir novos Impostos para reembolso Individual
							INSERT INTO dbo.ReembolsosIndividuaisImpostos 
							(
								IdReembolsoIndividual,
								IdCodigoImposto,
								IdOrdem,
								IdTabelasTaxas,
								ValorImposto,
								TaxaAplicada,
								ValorCalculado,
								TaxaCalculada,
								ValorManual
							)
							SELECT
								@IdReembolsoIndividual,
								TXML.IdCodigoImposto,
								TXML.IdOrdem,
								CASE WHEN TXML.IdTabelasTaxas = 0
									THEN NULL
									ELSE TXML.IdTabelasTaxas
								END,
								TXML.ValorImposto,
								TXML.TaxaAplicada,
								TXML.ValorCalculado,
								TXML.TaxaCalculada,
								TXML.ValorManual
							FROM dbo.[udf_MovimentosIndividuaisImpostos_GetRecordsFromXml](@xmlReembolsosImpostosXml) AS TXML;

						END;

						IF(@decComissaoIndividual<>0)
						BEGIN
							DELETE RII
							FROM ReembolsosIndividuaisImpostos AS RII
							INNER JOIN Cfgbiz.Impostos AS I
								ON I.IdCodigoImposto = RII.IdCodigoImposto
							WHERE IdReembolsoIndividual = @IdReembolsoIndividual
								AND I.IdTipoValor = 'C';

							-- Inserir novos Impostos COmissoes para reembolso Individual
							INSERT INTO dbo.ReembolsosIndividuaisImpostos 
							(
								IdReembolsoIndividual,
								IdCodigoImposto,
								IdOrdem,
								IdTabelasTaxas,
								ValorImposto,
								TaxaAplicada,
								ValorCalculado,
								TaxaCalculada,
								ValorManual
							)
							SELECT
								@IdReembolsoIndividual,
								TXML.IdCodigoImposto,
								TXML.IdOrdem,
								CASE WHEN TXML.IdTabelasTaxas = 0
									THEN NULL
									ELSE TXML.IdTabelasTaxas
								END,
								TXML.ValorImposto,
								TXML.TaxaAplicada,
								TXML.ValorCalculado,
								TXML.TaxaCalculada,
								TXML.ValorManual
							FROM dbo.[udf_MovimentosIndividuaisImpostos_GetRecordsFromXml](@xmlReembolsosImpostosComissoesXml) AS TXML;
						END


						-- Guardar plano reembolsado na WORK table
						-- ReembolsosIndividuais trigger on INSERT utiliza para filtrar subscrições reembolsáveis
						IF (@PlanoPensoes <> '')
						BEGIN
							INSERT INTO WORK.PlanosPensoesReembolsos (IdReembolsoMultiplo, PlanoPensoes)
							VALUES (@intIdReembolsoMultiplo, @PlanoPensoes);
						END

						--Update dos valores do Reembolso
						UPDATE  ReembolsosIndividuais 
						SET
							Rendimento = @decRendimentoIndividual,
							TotalInvestido = @decTotalInvestidoIndividual,
							TaxaComissao = @decTaxaComissaoIndividual,
							Comissoes = @decComissaoIndividual,
							ValorUPs = @decValorUPsIndividual,
							ValorTotal = @decValorTotalIndividual,
							NumeroUPs = @decNumeroUPsIndividual,
							Recalculado = 1
						WHERE IdReembolsoIndividual = @IdReembolsoIndividual;

						DELETE FROM WORK.PlanosPensoesReembolsos
						WHERE IdReembolsoMultiplo = @intIdReembolsoMultiplo
							AND PlanoPensoes = @PlanoPensoes;
						
					END;

					DELETE FROM @tblMovimentosIndividuaisImpostos;
					DELETE FROM @tblMovimentosIndividuaisImpostosComissoes;

					-- reset variáveis
					SELECT	@IdFundo = 0, 
							@IdProduto = 0, 
							@IdReembolsoIndividual = 0, 
							@TipoReembolso = 0, 
							@IdMotivoReembolso = 0, 
							@IdContribuinte = 0,
							@TipoContrato = 0, 
							@DataMovimento = 0, 
							@IdContrato = 0, 
							@Contas = 0, 
							@Moeda = 0, 
							@TipoContribuicao = 0, 
							@PercentagemCapital = 0, 
							@RecalcularImpostos = 0,
							@decNumeroUPsIndividual = 0,
							@IdEntidadePartipante = 0,
							@IdTipoReembolso = 0,
							@idContratoProdutoParticipante = 0,
							@intIdReembolsoMultiplo = 0;
				END;
				END;
				-- fim ciclo
			
			-- Atualizar ReembolsosIndividuaisValores
			DECLARE @tblReembolsosIndividuais dbo.typ_MovimentosChaves;

			INSERT INTO @tblReembolsosIndividuais
			(
				IdMovimento
			)
			SELECT
				IdReembolsoIndividual
			FROM #ReembolsosARecalcular
			WHERE Criar = 1;

			-- Eliminar linha de valor líquido com valor temporário
			DELETE RIV
			FROM dbo.ReembolsosIndividuaisValores AS RIV
			INNER JOIN @tblReembolsosIndividuais AS TRI
				on TRI.IdMovimento = RIV.IdReembolsoIndividual;

			-- Inserir linhas a partir dos reembolsos individuais
			EXEC dbo.pr_Reembolsos_InserirValorATransferir @p_tblReembolsosIndividuais = @tblReembolsosIndividuais;
			

			END;

			--

			BEGIN ----- Atualizar valores totais dos Reembolsos Multiplos				
				
				
				WITH 
					CTE_ListaReembolsosMultiplosUpdate
					(
						IdReembolsoMultiplo
					)
					 AS
					( 
						SELECT 
							DISTINCT 
								RI2.IdReembolsoMultiplo 
						FROM #ReembolsosARecalcular AS RAR
						INNER JOIN ReembolsosIndividuais AS RI2
							ON RI2.IdReembolsoIndividual = RAR.IdReembolsoIndividual
					), 
				SomaReembolsos_CTE(
						IdReembolsoMultiplo, 
						SomaValorUP, 
						SomaComissoes, 
						SomaValorTotal, 
						SomaTotalInvestido, 
						SomaRendimento,
						NumRemb_FaltaCotacao)
				AS (
					SELECT	RI.IdReembolsoMultiplo, 
							SUM(RI.ValorUPs), 
							SUM(RI.Comissoes), 
							SUM(RI.ValorTotal), 
							SUM(RI.TotalInvestido), 
							SUM(RI.Rendimento),
							MultiLinha.Num		
					FROM CTE_ListaReembolsosMultiplosUpdate LRMU
					INNER JOIN ReembolsosIndividuais AS RI
						ON RI.IdReembolsoMultiplo = LRMU.IdReembolsoMultiplo						
					CROSS APPLY(
						SELECT COUNT(*) AS Num 
						FROM ReembolsosIndividuais AS RI0
						WHERE RI0.IdReembolsoMultiplo = LRMU.IdReembolsoMultiplo
							AND RI0.Recalculado = 0
					) MultiLinha
					GROUP BY Ri.IdReembolsoMultiplo,MultiLinha.Num
					)		
					UPDATE ReembolsosMultiplos
						SET 
						ValorUPs = CTE.SomaValorUP,
						Comissoes = CTE.SomaComissoes,
						ValorTotal = CTE.SomaValorTotal,
						TotalInvestido = CTE.SomaTotalInvestido,
						Rendimento =  CTE.SomaRendimento,
						IdEstado = CASE 
										WHEN CTE.NumRemb_FaltaCotacao > 0
										THEN RM.IdEstado
										ELSE 'A'
									END
					FROM ReembolsosMultiplos AS RM
						INNER JOIN SomaReembolsos_CTE AS CTE 
							ON RM.IdReembolsoMultiplo = CTE.IdReembolsoMultiplo;

				-- Verificar se existem reembolsos do mesmo dia com dependências (Reembolso Capital e Reembolso Renda) com estados diferentes
				WITH ReembolsosDependInvalido_CTE(
					IdReembolsoMultiploRenda,
					IdReembolsoMultiploCapital
				)
				AS (
				SELECT	RM_Renda.IdReembolsoMultiplo,
						RM_Capital.IdReembolsoMultiplo
				FROM #ReembolsosARecalcular AS RAR
				INNER JOIN ReembolsosMultiplos AS RM_Renda
					ON RAR.IdReembolsoMultiplo = RM_Renda.IdReembolsoMultiplo
				INNER JOIN ReembolsosMultiplosExtensao AS RME
					ON RME.IdReembolsoMultiplo = RM_Renda.IdReembolsoMultiplo
				INNER JOIN ReembolsosMultiplos AS RM_Capital
					ON RME.IdReembolsoMultiploCapital = RM_Capital.IdReembolsoMultiplo
				WHERE	RM_Capital.IdEstado = 'N' 
						AND RAR.RM_DataReembolso = RM_Capital.DataReembolso
						AND RM_Renda.IdEstado !=  'M'
						)
				UPDATE RM
					SET IdEstado = 'N'
				FROM ReembolsosMultiplos AS RM
				INNER JOIN ReembolsosDependInvalido_CTE AS CTE
					ON RM.IdReembolsoMultiplo = CTE.IdReembolsoMultiploRenda;

				
				-- Corrigir percentagens de distribuição
				DECLARE @tblReembolsos TABLE
				(
					RowNumber int identity(1,1),
					IdReembolsoMultiplo numeric(18,0)
				);

				DECLARE @tblIndividuais TABLE
				(
					RowNumber int identity(1,1),
					IdReembolsoIndividual numeric(18,0)
				);

				DECLARE @percDistribRestante numeric(5,2),
						@resto numeric(15,2),
						@movsIndividuais int,
						@maxIndividuais int,
						@idReembolso numeric(18,0),
						@percDist numeric(5,2),
						@valorRemb numeric(15,2);

				INSERT INTO @tblReembolsos (IdReembolsoMultiplo)
				SELECT DISTINCT(RAR.IdReembolsoMultiplo)
				FROM #ReembolsosARecalcular AS RAR
				INNER JOIN dbo.ReembolsosMultiplos AS RMM
					ON RMM.IdReembolsoMultiplo = RAR.IdReembolsoMultiplo
				WHERE RMM.IdEstado = 'A';

				SET @MinNumber = 0;
				SET @MaxNumber = 
				(
					SELECT MAX(RowNumber)
					FROM @tblReembolsos
				);

				WHILE(@MaxNumber > @MinNumber)
				BEGIN

					SET @MinNumber = @MinNumber + 1;

					SET @percDistribRestante = 100;
					SET @resto = 
					(
						SELECT RM.ValorTotal
						FROM @tblReembolsos AS TR
						INNER JOIN dbo.ReembolsosMultiplos AS RM
							ON RM.IdReembolsoMultiplo = TR.IdReembolsoMultiplo
						WHERE TR.RowNumber = @MinNumber
					);

					DELETE FROM @tblIndividuais;

					INSERT INTO @tblIndividuais (IdReembolsoIndividual)
					SELECT RI.IdReembolsoIndividual
					FROM @tblReembolsos AS TR
					INNER JOIN dbo.ReembolsosIndividuais AS RI
						ON RI.IdReembolsoMultiplo = TR.IdReembolsoMultiplo
					WHERE TR.RowNumber = @MinNumber;

					SET @movsIndividuais = 
					(
						SELECT MIN(RowNumber)
						FROM @tblIndividuais
					);
					SET @maxIndividuais = 
					(
						SELECT MAX(RowNumber)
						FROM @tblIndividuais
					);

					WHILE(@maxIndividuais >= @movsIndividuais)
					BEGIN

						SELECT
							@idReembolso = TI.IdReembolsoIndividual,
							@valorRemb = RI.ValorTotal,
							@percDist = CASE WHEN @resto = 0 
											THEN 0.00
											ELSE ROUND((RI.ValorTotal * (@percDistribRestante / 100) / @resto) * 100, 2)
										END
						FROM @tblIndividuais AS TI
						INNER JOIN dbo.ReembolsosIndividuais AS RI
							ON RI.IdReembolsoIndividual = TI.IdReembolsoIndividual
						WHERE TI.RowNumber = @movsIndividuais;

						UPDATE dbo.ReembolsosIndividuais
						SET PercentagemDistribuicao = @percDist
						WHERE IdReembolsoIndividual = @idReembolso;

						SET @percDistribRestante = @percDistribRestante - @percDist;
						SET @resto = @resto - @valorRemb;
						SET @movsIndividuais = @movsIndividuais + 1;

					END;

				END;
				
			END;
		
		END;

        -- 

        BEGIN ----- Subscrições -----

			BEGIN ----- Obter Lista dos Movimentos de Subscrição a serem Recalculados -----
				
				CREATE TABLE #tblSubscricoesIndividuaisTotais
				(
					IdSubscricaoIndividual numeric(18, 0),
					IdFundo smallint,
					DiferencaValor numeric(18, 2), 
					DiferencaRendimento numeric(18, 2), 
					DiferencaNumeroUps decimal(25, 12),
					Valor numeric(18, 2), 
					Rendimento numeric(18, 2), 
					NumeroUps decimal(25, 12)
				);

				CREATE TABLE #SubscricoesARecalcular
				(RowNumber             INT, 
					IdSubscricaoIndividual NUMERIC(18, 0), 
					IdSubscricaoMultipla   NUMERIC(18, 0), 
					IdContrato				NUMERIC(18, 0), 
					SM_DataMovimento		DATE, 
					IdFundo				INT,
					Contas				VARCHAR(500),
					PlanoPensoes		   NVARCHAR(10)
				);

				INSERT INTO #SubscricoesARecalcular
				(RowNumber, 
					IdSubscricaoIndividual, 
					IdSubscricaoMultipla, 
					IdContrato, 
					SM_DataMovimento, 
					IdFundo,
					Contas,
					PlanoPensoes
				)
				SELECT 
					ROW_NUMBER() OVER(ORDER BY SI.IdSubscricaoIndividual DESC) AS RowNumber,
					SI.IdSubscricaoIndividual,
					SI.IdSubscricaoMultipla,
					C.IdContrato,
					SM.DataMovimento,
					F.IdFundo,
					SI.Conta,
					ISNULL(MI.Valor, '')
				FROM @p_ListaFundosUpdate AS LFU
						INNER JOIN dbo.SubscricoesMultiplas AS SM ON SM.DataMovimento = LFU.DataCotacao
						INNER JOIN dbo.SubscricoesIndividuais AS SI ON SI.IdSubscricaoMultipla = SM.IdSubscricaoMultipla
						INNER JOIN dbo.Contratos AS C ON C.IdContrato = SI.IdContrato
														AND C.IdFundo = LFU.IdFundo
						INNER JOIN dbo.Cotacoes AS C0 ON C0.DataCotacao = SM.DataMovimento
														AND C0.IdFundo = LFU.IdFundo
						INNER JOIN CfgClt.Fundos AS F ON F.IdFundo = LFU.IdFundo --adicionado Inner join para garantir que apenas se faz o update para os fundos com cotação desconhecida.
						-- filtro para obter apenas subscrições individuais temporárias.
						INNER JOIN dbo.SubscricoesIndividuaisValores SIV ON SI.IdSubscricaoIndividual = SIV.IdSubscricaoIndividual
																			AND SIV.IdTipoValor = 'V' -- Valor Total
																			AND SIV.IdEstadoTransferenciaBancariaValor = 'T'-- Transferido/Pago
						LEFT JOIN dbo.MovimentosInformacoes AS MI 
								ON MI.IdMovimentoIndividual = SI.IdSubscricaoIndividual
								AND MI.TipoMovimento = 'S'
								AND MI.Info = 2000
						LEFT JOIN dbo.TransferenciasBancariasValoresMovimentosSubscricoes AS TBVM -- Registo criado na geração da transferência SEPA
							ON TBVM.IdSubscricaoIndividualValor = SIV.IdSubscricaoIndividualValor
							AND TBVM.IdEstadoTransferenciaBancariaValor = 'T'
						LEFT JOIN dbo.TransferenciasInternas AS TI -- Subscrições pertencentes a transferências
								ON TI.IdSubscricaoMultipla = SM.IdSubscricaoMultipla
						LEFT JOIN dbo.ContaReservaMovimentosRelacao AS CRMR
								ON CRMR.IdSubscricaoMultipla = SM.IdSubscricaoMultipla
				WHERE F.SuporteCotacaoDesconhecida = 1
						AND SI.Estado IN ('M','R')
						AND 
						(
							SM.IdMetodoPagamento NOT LIKE 'T' OR
							TBVM.IdValorAgrupado IS NOT NULL
						)
						AND TI.IdTransferenciaInterna IS NULL -- Excluir subscrições de transferências internas
						AND CRMR.IdSubscricaoMultipla IS NULL;
			END;

			--

			BEGIN ----- Update NumUPs Subscrição -----
				UPDATE SI
					SET 
						SI.NumeroUPs = Valor.Unidades, 
						Estado = CASE
									WHEN(Valor.Unidades IS NOT NULL
										AND Valor.Unidades != 0)
									THEN ' '
									ELSE SI.Estado
								END
				FROM @p_ListaFundosUpdate AS LFU
					INNER JOIN dbo.SubscricoesMultiplas AS SM 
						ON SM.DataMovimento = LFU.DataCotacao
					INNER JOIN dbo.SubscricoesIndividuais AS SI 
						ON SI.IdSubscricaoMultipla = SM.IdSubscricaoMultipla
					INNER JOIN #SubscricoesARecalcular AS SAR
						ON SAR.IdSubscricaoIndividual = SI.IdSubscricaoIndividual
					INNER JOIN dbo.Contratos AS C 
						ON C.IdContrato = SI.IdContrato
					INNER JOIN dbo.Cotacoes AS C0 
						ON C0.DataCotacao = SM.DataMovimento
					INNER JOIN CfgClt.Fundos AS F 
						ON F.IdFundo = LFU.IdFundo --adicionado Inner join para garantir que apenas se faz o update para os fundos com cotação desconhecida.
													-- filtro para obter apenas subscrições individuais temporárias.
					INNER JOIN dbo.SubscricoesIndividuaisValores SIV 
						ON SI.IdSubscricaoIndividual = SIV.IdSubscricaoIndividual
					OUTER APPLY
					(
						SELECT RoundValue
						FROM dbo.udf_Math_RoundUPs(c.IdFundo, CASE WHEN C0.Cotacao = 0 THEN 0 ELSE (SI.ValorUPs / C0.Cotacao) END)
					) AS Valor(Unidades)
					LEFT JOIN dbo.TransferenciasBancariasValoresMovimentosSubscricoes AS TBVM -- Registo criado na geração da transferência SEPA
							ON TBVM.IdSubscricaoIndividualValor = SIV.IdSubscricaoIndividualValor
							AND TBVM.IdEstadoTransferenciaBancariaValor = 'T'
				WHERE F.SuporteCotacaoDesconhecida = 1
						AND SI.Estado IN ('M','R')
						AND SIV.IdTipoValor = 'V' -- Valor Total
						AND SIV.IdEstadoTransferenciaBancariaValor = 'T'-- Transferido/Pago
						AND C.idFundo = LFU.IdFundo
						AND C0.IdFundo = LFU.IdFundo
						AND 
						(
							SM.IdMetodoPagamento NOT LIKE 'T' OR
							TBVM.IdValorAgrupado IS NOT NULL
						);
			END;

			--

			BEGIN ----- Recálculo dos Valores da Subscrição (comissão, valorUps, ValorTotal etc) -----
				Declare @IdSubscricaoindividual INT,
						@p_Despesas DECIMAL(10,2),
						@xmlSubscricoesImpostosXml XML,
						@TipoContribuinte varchar(1)

				-- Variáveis de apoio à iteração
				SET @MaxNumber =
				(
					SELECT COUNT(IdContrato)
					FROM #SubscricoesARecalcular
				);
				SET @MinNumber = 0;
				SET @p_Despesas = 0;


				-- Percorrer cada subscricao para recalcular os valores todos.
				WHILE @MaxNumber > @MinNumber
				BEGIN
					SET @MinNumber = @MinNumber + 1;

					-- Obter dados para recalcular valores
					SELECT @IdFundo = SAR.IdFundo, 
							@IdProduto = CP.IdProduto, 
							@IdSubscricaoindividual = SAR.IdSubscricaoIndividual, 
							@IdContribuinte = CP.IdEntidadeContribuinte,
							@TipoContrato = C.IdTipoContrato, 
							@DataMovimento = SM.DataMovimento, 
							@IdContrato = SAR.IdContrato, 
							@RecalcularImpostos = 1,
							@decNumeroUPsIndividual = SI.NumeroUPs,
							@IdEntidadePartipante = CPP.IdEntidadeParticipante,
							@idContratoProdutoParticipante = CPP.IdContratoProdutoParticipante,
							@Contas = SI.Conta,
							@TipoContribuinte = SM.IdTipoActividadeContribuinte,
							@PlanoPensoes = SAR.PlanoPensoes,
							@decComissaoIndividual = SI.Comissao,
							@p_Despesas = SI.Despesas
					FROM SubscricoesIndividuais AS SI
							INNER JOIN #SubscricoesARecalcular AS SAR ON  SI.IdSubscricaoIndividual = SAR.IdSubscricaoIndividual
							INNER JOIN SubscricoesMultiplas AS SM ON SM.IdSubscricaoMultipla = SAR.IdSubscricaoMultipla
							INNER JOIN Contratos AS C ON C.IdContrato = SAR.IdContrato
							INNER JOIN ContratosProdutoParticipantes AS CPP ON CPP.IdContratoProdutoParticipante = C.IdContratoProdutoParticipante
							INNER JOIN ContratosProduto AS CP ON CP.IdContratoProduto = CPP.IdContratoProduto
					WHERE SAR.RowNumber = @MinNumber;	
					
					SET @strUniqueIdentifier =left(newid(),24);

					-- Calcular Valores
					EXEC pr_SubscricoesIndividuais_CalcularValoresPorNumeroUP 
						@p_IdFundo = @IdFundo,
						@p_IdProduto = @IdProduto,
						@p_IdContribuinte = @IdContribuinte,
						@p_TipoContribuinte = @TipoContribuinte,
						@p_TipoContrato = @TipoContrato,
						@p_TipoMovimento = 'S',
						@p_DataMovimento = @DataMovimento,
						@p_IdContrato = @IdContrato,
						@p_Conta = @Contas,
						@p_PlanoPensoes = @PlanoPensoes,
						@p_ManterComissao = 1,
						@p_ManterValorTotal = 0,
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
						@p_IdEntidadeParticipante = @IdEntidadePartipante,
						@p_IdMotivoReembolso = NULL,
						@p_DataMovimento = @DataMovimento,
						@p_NumeroUPs = @decNumeroUPsIndividual,
						@p_ValorUPs = @decValorUPsIndividual,
						@p_Comissao = @decComissaoIndividual, 
						@p_Despesas = @p_Despesas,
						@p_Moeda = '',
						@p_TotalInvestido = @decValorTotalIndividual,
						@p_Rendimento = NULL,
						@p_Contas = @Contas,
						@p_PercentagemCapital = NULL,
						@p_TipoContribuicao = @TipoContribuicao,
						-- Contrato
						@p_IdContratoProdutoParticipante = @idContratoProdutoParticipante,
						@p_IdContrato = @IdContrato,
						-- Rendimento Empresa
						@p_RendimentoEmpresa = NULL,
						-- Total investido Empresa
						@p_TotalInvestidoEmpresa = NULL,
						@p_IdTipoReembolso = NULL,
						@p_RecalcularImpostos = 1,
						@p_ValorTotalMovimentoMultiplo = @decValorTotalIndividual,
						@p_UniqueIdentifier = @strUniqueIdentifier,
						-- User Job
						@p_UserJob = @p_UserJob,
						-- Valor de IRS calculado
						@p_tblMovimentosIndividuaisImpostos = @tblMovimentosIndividuaisImpostos, -- esta informação é enviada a nulo, recalculada no SP e retornam o xml abaixo.
						@p_ImpostosResultados = @xmlSubscricoesImpostosXml OUTPUT,
						@p_TotalImpostos = @decTotalImpostos OUTPUT,
						@p_ValorTotal = @decValorTotalIndividual OUTPUT;

					IF(@decTotalImpostos <> 0)
					BEGIN
						
						DELETE FROM SubscricoesIndividuaisImpostos WHERE IdSubscricaoIndividual = @IdSubscricaoindividual

						--Inserir novos Impostos para subscrição Individual
						INSERT INTO dbo.SubscricoesIndividuaisImpostos 
						(
							IdSubscricaoIndividual,
							IdCodigoImposto,
							IdOrdem,
							IdTabelasTaxas,
							ValorImposto,
							TaxaAplicada,
							ValorCalculado,
							TaxaCalculada,
							ValorManual
						)
						SELECT
							@IdSubscricaoindividual,
							TXML.IdCodigoImposto,
							TXML.IdOrdem,
							TXML.IdTabelasTaxas,
							TXML.ValorImposto,
							TXML.TaxaAplicada,
							TXML.ValorCalculado,
							TXML.TaxaCalculada,
							TXML.ValorManual
						FROM dbo.[udf_MovimentosIndividuaisImpostos_GetRecordsFromXml](@xmlSubscricoesImpostosXml) AS TXML;
					END;

					UPDATE  SubscricoesIndividuais SET
						TaxaComissao = @decTaxaComissaoIndividual,
						Comissao = @decComissaoIndividual,
						ValorUPs = @decValorUPsIndividual,
						ValorTotal = @decValorTotalIndividual,
						NumeroUPs = @decNumeroUPsIndividual							
					WHERE IdSubscricaoIndividual = @IdSubscricaoindividual;


					BEGIN -- Atualizar histórico de subscrições Transferência Externa --

					UPDATE TH
					SET
						TH.NumeroUPs = Historico.Unidades
					FROM dbo.TransferenciasHistoricos AS TH
					INNER JOIN dbo.SubscricoesIndividuais AS SI
						ON SI.IdSubscricaoIndividual = TH.IdSubscricaoIndividual
					INNER JOIN dbo.Contratos AS C
						ON C.IdContrato = SI.IdContrato
					CROSS APPLY
					(
						SELECT RoundValue
						FROM dbo.udf_Math_RoundUPs(C.IdFundo, SI.NumeroUPs * (TH.Valor / SI.ValorUPs))
					) Historico(Unidades)
					WHERE TH.IdSubscricaoIndividual = @IdSubscricaoindividual;

					-- Acertar valores de arredondamento entre as Transferências e as Subscrições
					DELETE FROM #tblSubscricoesIndividuaisTotais;

					INSERT INTO #tblSubscricoesIndividuaisTotais
					(
						IdSubscricaoIndividual,
						IdFundo,
						DiferencaValor,
						DiferencaRendimento,
						DiferencaNumeroUps,
						Valor,
						Rendimento,
						NumeroUps
					)
					SELECT 
						SI.idSubscricaoIndividual,
						C.IdFundo,
						ISNULL(SI.ValorTotal,0) - HistoricoAcumulado.Valor,
						ISNULL(SI.Rendimento,0) - HistoricoAcumulado.Rendimento,
						SI.NumeroUPs - HistoricoAcumulado.NumeroUps,
						HistoricoAcumulado.Valor,
						HistoricoAcumulado.Rendimento,
						HistoricoAcumulado.NumeroUps
					FROM dbo.SubscricoesIndividuais AS SI
					INNER JOIN dbo.Contratos AS C 
					ON C.IdContrato = SI.IdContrato
					OUTER APPLY
					(
						SELECT 
							SUM(TH.Valor + TH.Rendimento),
							SUM(TH.Rendimento),
							SUM(TH.NumeroUPs)
						FROM dbo.TransferenciasHistoricos AS TH 
						WHERE TH.IdSubscricaoIndividual = SI.IdSubscricaoIndividual
					) HistoricoAcumulado(Valor, Rendimento, NumeroUps)
					WHERE SI.IdSubscricaoIndividual = @IdSubscricaoindividual;
	
					--Distribuir diferenças de Rendimento pelas registos do historico
					WITH CTE_AcertoHistorico
					(
						IdSubscricaoIndividual, 
						IdFundo,
						AcertoValorInvestido, 
						AcertoRendimento,
						AcertoUnidades, 
						NumeroUnidades, 
						DiferencaValor, 
						DiferencaRendimento,
						DiferencaUnidades,
						TotalUnidades, 
						NumeroSequencia
					) 
					AS 
					(
						SELECT 
							SIT.IdSubscricaoIndividual, 
							SIT.IdFundo,
							CAST(Acerto.Valor AS numeric(18, 2)), 
							CAST(Acerto.Rendimento AS numeric(18, 2)), 
							CAST(Acertos.Unidades AS decimal(25, 12)), 
							TH.NumeroUPs,
							CAST(SIT.DiferencaValor - Acerto.Valor AS numeric(18, 2)),
							CAST(SIT.DiferencaRendimento -Acerto.Rendimento  AS numeric(18, 2)),			
							CAST(SIT.DiferencaNumeroUps - Acertos.Unidades AS decimal(25, 12)),
							CAST(SIT.NumeroUps - TH.NumeroUps AS decimal(25, 12)), 
							TH.NumeroSequencia
						FROM #tblSubscricoesIndividuaisTotais SIT
						INNER JOIN dbo.TransferenciasHistoricos AS TH 
						ON TH.IdSubscricaoIndividual = SIT.IdSubscricaoIndividual
							AND TH.NumeroSequencia = 1 
						CROSS APPLY 
						(
							SELECT 
								ROUND(SIT.DiferencaRendimento * (TH.NumeroUPs / SIT.NumeroUps), 2), 
								ROUND(SIT.DiferencaValor * (TH.NumeroUPs / SIT.NumeroUps), 2)				
						)Acerto(Valor, Rendimento) 
						CROSS APPLY
						(
							SELECT RoundValue
							FROM dbo.udf_Math_RoundUPs(SIT.IDFUNDO,SIT.DiferencaNumeroUps * (TH.NumeroUPs / SIT.NumeroUps))
						) AS Acertos(Unidades)
						WHERE SIT.DiferencaNumeroUps <> 0 
							OR SIT.DiferencaRendimento <> 0  
							OR SIT.DiferencaValor <> 0 

						UNION ALL 
				
						SELECT 
							CAH.IdSubscricaoIndividual,
							CAH.IdFundo, 
							CAST(Acerto.Valor AS numeric(18, 2)), 
							CAST(Acerto.Rendimento AS numeric(18, 2)), 
							CAST(Acertos.Unidades AS decimal(25, 12)), 
							TH.NumeroUPs,
							CAST(CAH.DiferencaValor - Acerto.Valor AS numeric(18, 2)), 
							CAST(CAH.DiferencaRendimento - Acerto.Rendimento AS numeric(18, 2)), 			
							CAST(CAH.DiferencaUnidades- Acertos.Unidades AS decimal(25, 12)), 
							CAST(CAH.TotalUnidades - TH.NumeroUPs AS decimal(25, 12)),
							TH.NumeroSequencia
						FROM CTE_AcertoHistorico AS CAH
						INNER JOIN dbo.TransferenciasHistoricos AS TH
						ON TH.IdSubscricaoIndividual = CAH.IdSubscricaoIndividual 
							AND TH.NumeroSequencia= CAH.NumeroSequencia + 1			
						CROSS APPLY 
						(
							SELECT 
								ROUND(CAH.DiferencaValor * (TH.NumeroUPs/ CAH.TotalUnidades), 2), 
								ROUND(CAH.DiferencaRendimento * (TH.NumeroUPs / CAH.TotalUnidades), 2)				
						)Acerto(Valor, Rendimento) 		
						CROSS APPLY
						(
							SELECT RoundValue
							FROM dbo.udf_Math_RoundUPs(CAH.IDFUNDO,CAH.DiferencaUnidades * (TH.NumeroUPs / CAH.TotalUnidades))
						) AS Acertos(Unidades)
					 
					) 

					UPDATE TH
					SET 
						TH.Rendimento = TH.Rendimento + AR.AcertoRendimento, 
						TH.Valor = TH.Valor + AR.AcertoValorInvestido, 
						TH.NumeroUPs = TH.NumeroUPs + AR.AcertoUnidades
					FROM CTE_AcertoHistorico AS AR
					INNER JOIN dbo.TransferenciasHistoricos AS TH
						ON TH.IdSubscricaoIndividual = AR.IdSubscricaoIndividual		
						AND TH.NumeroSequencia = AR.NumeroSequencia
					OPTION(maxrecursion 0 );

					END;


					DELETE FROM @tblMovimentosIndividuaisImpostos;

				END;
			-- fim ciclo
			END;

			--

			BEGIN ----- Atualizar valores totais das Subscricoes Multiplas
				WITH SomaSubscricoes_CTE(
						IdSubscricaoMultipla, 
						SomaValorUP, 
						SomaComissoes, 
						SomaValorTotal, 
						SomaRendimento,
						SomaDespesas,
						NumRemb_FaltaCotacao)
				AS (
					SELECT	SI.IdSubscricaoMultipla, 
							SUM(SI.ValorUPs), 
							SUM(SI.Comissao), 
							SUM(SI.ValorTotal), 
							SUM(SI.Rendimento),
							SUM(SI.Despesas),
							MultiLinha.Num		
					FROM SubscricoesIndividuais AS SI
						INNER JOIN #SubscricoesARecalcular AS SAR 
							ON SI.IdSubscricaoIndividual = SAR.IdSubscricaoIndividual
						CROSS APPLY(
							SELECT COUNT(*) AS Num 
							FROM SubscricoesIndividuais AS SI0
							WHERE SI0.IdSubscricaoMultipla = SI.IdSubscricaoMultipla
								AND SI0.NumeroUPs <= 0.00
						) MultiLinha
					GROUP BY SI.IdSubscricaoMultipla,MultiLinha.Num)
				UPDATE SubscricoesMultiplas
				SET 
					ValorUPs = CTE.SomaValorUP,
					Comissoes = CTE.SomaComissoes,
					ValorTotal = CTE.SomaValorTotal,
					Despesas = CTE.SomaDespesas
				FROM SubscricoesMultiplas AS SM
					INNER JOIN SomaSubscricoes_CTE AS CTE 
						ON SM.IdSubscricaoMultipla = CTE.IdSubscricaoMultipla;
			END;
        END;

		--
		
		BEGIN ----- Transferências Internas ------


			BEGIN ----- Obter Lista dos Movimentos de Subscrição a serem Recalculados -----

			CREATE TABLE #TransferenciasARecalcular
			(
				RowNumber             INT, 
				SequenceNumber			INT, 
				IdSubscricaoIndividual NUMERIC(18, 0), 
				IdSubscricaoMultipla   NUMERIC(18, 0), 
				IdContrato				NUMERIC(18, 0), 
				SM_DataMovimento		DATE, 
				IdFundo				INT,
				Contas				VARCHAR(500),
				PlanoPensoes		   NVARCHAR(10)
			);

			INSERT INTO #TransferenciasARecalcular
			(
				RowNumber, 
				SequenceNumber,
				IdSubscricaoIndividual, 
				IdSubscricaoMultipla, 
				IdContrato, 
				SM_DataMovimento, 
				IdFundo,
				Contas,
				PlanoPensoes
			)
			SELECT 
				ROW_NUMBER() OVER(ORDER BY SI.IdSubscricaoIndividual DESC) AS RowNumber,
				ROW_NUMBER() OVER(PARTITION BY SI.IdSubscricaoMultipla ORDER BY SI.IdSubscricaoMultipla DESC) AS SequenceNumber,
				SI.IdSubscricaoIndividual,
				SI.IdSubscricaoMultipla,
				C.IdContrato,
				SM.DataMovimento,
				F.IdFundo,
				SI.Conta,
				ISNULL(MI.Valor, '')
			FROM dbo.SubscricoesMultiplas AS SM
					INNER JOIN dbo.SubscricoesIndividuais AS SI ON SI.IdSubscricaoMultipla = SM.IdSubscricaoMultipla
					INNER JOIN dbo.Contratos AS C ON C.IdContrato = SI.IdContrato
					INNER JOIN dbo.Cotacoes AS C0 ON C0.DataCotacao = SM.DataMovimento
													AND C0.IdFundo = C.IdFundo
					INNER JOIN CfgClt.Fundos AS F ON F.IdFundo = C.IdFundo
					LEFT JOIN dbo.MovimentosInformacoes AS MI 
							ON MI.IdMovimentoIndividual = SI.IdSubscricaoIndividual
							AND MI.TipoMovimento = 'S'
							AND MI.Info = 2000
					INNER JOIN dbo.TransferenciasInternas AS TI -- Subscrições pertencentes a transferências
						ON TI.IdSubscricaoMultipla = SM.IdSubscricaoMultipla
					INNER JOIN @p_ListaFundosUpdate AS LFU
						ON LFU.DataCotacao = SM.DataMovimento
					INNER JOIN dbo.ReembolsosMultiplos AS RM
						ON RM.IdReembolsoMultiplo = TI.IdReembolsoMultiplo
						AND RM.IdEstado = 'A'
			WHERE F.SuporteCotacaoDesconhecida = 1
					AND SI.Estado = 'M'
			GROUP BY SI.IdSubscricaoIndividual,
						SI.IdSubscricaoMultipla,
						C.IdContrato,
						SM.DataMovimento,
						F.IdFundo,
						SI.Conta,
						MI.Valor;

			END;


			BEGIN -- Atualizar valor total da subscrição da transferência com base no reembolso -----

			DECLARE @tblMultiSubscriptions TABLE
			(
				RowNumber INT IDENTITY(1, 1),
				IdSubscricaoMultipla NUMERIC(18, 0)
			);

			INSERT INTO @tblMultiSubscriptions (IdSubscricaoMultipla)
			SELECT DISTINCT(IdSubscricaoMultipla)
			FROM #TransferenciasARecalcular;

			DECLARE @numMovimentos INT,
					@movCounter INT;

			SET @movCounter = 0;
			SET @numMovimentos =
			(
				SELECT MAX(RowNumber)
				FROM @tblMultiSubscriptions
			);

			-- Percorrer subscrições múltiplas
			WHILE (@numMovimentos > @movCounter)
			BEGIN
				
				SET @movCounter = @movCounter + 1;

				DECLARE @numFundos INT,
						@fundoCounter INT,
						@valorRestante numeric(15, 2),
						@percentagemRestante numeric(5, 2);

				-- Quantidade de detalhes por fundo para calcular
				SET @fundoCounter = 0;
				SET @numFundos =
				(
					SELECT MAX(TAR.SequenceNumber)
					FROM #TransferenciasARecalcular AS TAR
					INNER JOIN @tblMultiSubscriptions AS MS
						ON MS.IdSubscricaoMultipla = TAR.IdSubscricaoMultipla
					WHERE MS.RowNumber = @movCounter
				);

				-- Percentagem máxima a distribuir
				SET @percentagemRestante = 100;
				-- Valor máximo a distribuir = valor do reembolso múltiplo
				SET @valorRestante =
				(
					SELECT TOP 1 RM.ValorTotal
					FROM #TransferenciasARecalcular AS TAR
					INNER JOIN @tblMultiSubscriptions AS MS
						ON MS.IdSubscricaoMultipla = TAR.IdSubscricaoMultipla
					INNER JOIN dbo.TransferenciasInternas AS TI
						ON TI.IdSubscricaoMultipla = TAR.IdSubscricaoMultipla
					INNER JOIN dbo.ReembolsosMultiplos AS RM
						ON RM.IdReembolsoMultiplo = TI.IdReembolsoMultiplo
						AND RM.IdEstado = 'A'
					WHERE MS.RowNumber = @movCounter
				);

				-- Retirar valores já unitizados (aplicável quando o recálculo é feito um fundo de cada vez)
				SELECT
					@percentagemRestante = @percentagemRestante - ISNULL(SUM(SI.PercentagemDistribuicao), 0),
					@valorRestante = @valorRestante - ISNULL(SUM(SI.ValorTotal), 0)
				FROM #TransferenciasARecalcular AS TAR
				INNER JOIN @tblMultiSubscriptions AS MS
					ON MS.IdSubscricaoMultipla = TAR.IdSubscricaoMultipla
				INNER JOIN dbo.TransferenciasInternas AS TI
					ON TI.IdSubscricaoMultipla = TAR.IdSubscricaoMultipla
				INNER JOIN dbo.ReembolsosMultiplos AS RM
					ON RM.IdReembolsoMultiplo = TI.IdReembolsoMultiplo
					AND RM.IdEstado = 'A'
				INNER JOIN dbo.SubscricoesIndividuais AS SI
					ON SI.IdSubscricaoMultipla = TAR.IdSubscricaoMultipla
					AND SI.Estado = ''
				WHERE MS.RowNumber = @movCounter;

				-- Percorrer subscrições individuais da subscrição múltipla
				WHILE (@numFundos > @fundoCounter)
				BEGIN

					SET @fundoCounter = @fundoCounter + 1;

					DECLARE @valorASubscrever numeric(15, 2),
							@percentagemDistribuicao numeric(5, 2),
							@idSubscricaoIndividualTransferencia numeric(18, 0);

					-- Utilizar somatório do que já foi distribuído para evitar excessos por arredondamento
					-- ValorASubscrever = ValorRestante x PercentagemFundo / PercentagemRestante
					SELECT
						@idSubscricaoIndividualTransferencia = SI.IdSubscricaoIndividual,
						@percentagemDistribuicao = SI.PercentagemDistribuicao,
						@valorASubscrever = CASE WHEN @percentagemRestante = 0
												THEN 0.00
												ELSE ROUND(@valorRestante * (SI.PercentagemDistribuicao / 100) / (@percentagemRestante / 100), 2)
											END
					FROM #TransferenciasARecalcular AS TAR
					INNER JOIN @tblMultiSubscriptions AS MS
						ON MS.IdSubscricaoMultipla = TAR.IdSubscricaoMultipla
					INNER JOIN dbo.SubscricoesIndividuais AS SI 
						ON SI.IdSubscricaoIndividual = TAR.IdSubscricaoIndividual
					WHERE MS.RowNumber = @movCounter
						AND TAR.SequenceNumber = @fundoCounter;
					
					UPDATE dbo.SubscricoesIndividuais
					SET
						ValorTotal = @valorASubscrever
					WHERE IdSubscricaoIndividual = @idSubscricaoIndividualTransferencia;

					-- Esgotar valores já aplicados
					SET @percentagemRestante = @percentagemRestante - @percentagemDistribuicao;
					SET	@valorRestante = @valorRestante - @valorASubscrever;

				END

			END

			END;

			
			BEGIN -- Recalcular valores da subscrição (transferencia) -----

			DECLARE @xmlTransferenciasImpostosXml XML,
					@decValorTotalAuxiliar decimal(15,2);
			
			SET @MaxNumber =
			(
				SELECT COUNT(IdContrato)
				FROM #TransferenciasARecalcular
			);
			SET @MinNumber = 0;

			-- Percorrer cada subscrição para recalcular os valores todos.
			WHILE @MaxNumber > @MinNumber
			BEGIN
				SET @MinNumber = @MinNumber + 1;

				SELECT
					@IdSubscricaoindividual = TAR.IdSubscricaoIndividual,
					@decValorTotalIndividual = SI.ValorTotal,
					@IdFundo = TAR.IdFundo,
					@IdProduto = CP.IdProduto,
					@strMensagem = '',
					@Contas = SI.Conta,
					@PlanoPensoes = TAR.PlanoPensoes,
					@DataMovimento = SM.DataMovimento,
					@TipoContrato = CP.IdTipoContrato,
					@TipoContribuinte = SM.IdTipoActividadeContribuinte,
					@IdContribuinte = CP.IdEntidadeContribuinte,
					@IdContrato = SI.IdContrato,
					@decTaxaComissaoIndividual = SI.TaxaComissao,
					@decComissaoIndividual = SI.Comissao,
					@decValorUPsIndividual = SI.ValorUPs,
					@decNumeroUPsIndividual = SI.NumeroUPs,
					@xmlTransferenciasImpostosXml = NULL,
					@IdEntidadePartipante = CPP.IdEntidadeParticipante,
					@p_Despesas = SI.Despesas,
					@idContratoProdutoParticipante = SM.IdContratoProdutoParticipante
				FROM #TransferenciasARecalcular AS TAR
					INNER JOIN dbo.SubscricoesIndividuais AS SI 
						ON SI.IdSubscricaoIndividual = TAR.IdSubscricaoIndividual
					INNER JOIN dbo.SubscricoesMultiplas AS SM
						ON SM.IdSubscricaoMultipla = SI.IdSubscricaoMultipla
					INNER JOIN dbo.ContratosProdutoParticipantes AS CPP
						ON CPP.IdContratoProdutoParticipante = SM.IdContratoProdutoParticipante
					INNER JOIN dbo.ContratosProduto AS CP
						ON CP.IdContratoProduto = CPP.IdContratoProduto
				WHERE TAR.RowNumber = @MinNumber;


				SET @strUniqueIdentifier = left(newid(),24);
				

				-- Calcular por valor total
				EXEC dbo.pr_SubscricoesIndividuais_CalcularValoresPorValorTotal
					@p_IdFundo = @IdFundo,
					@p_IdProduto = @IdProduto,
					@p_IdContribuinte = @IdContribuinte,
					@p_TipoContribuinte =  @TipoContribuinte,
					@p_TipoContrato = @TipoContrato,
					@p_TipoMovimento = 'I',
					@p_DataMovimento = @DataMovimento,
					@p_IdContrato = @IdContrato,
					@p_PlanoPensoes = @PlanoPensoes,
					@p_Conta = @Contas,
					@p_CalcularComissoes = 1, -- Se 1, não calcular, apenas validar
					@p_EstadoSubscricao = 'A',
					@p_Despesas = @p_Despesas OUTPUT,
					@p_TaxaComissao = @decTaxaComissaoIndividual OUTPUT,
					@p_Comissao = @decComissaoIndividual OUTPUT,
					@p_ValorUPs = @decValorUPsIndividual OUTPUT,
					@p_ValorTotal = @decValorTotalIndividual OUTPUT,
					@p_NumeroUPs = @decNumeroUPsIndividual OUTPUT,
					@p_MovimentosImpostosXml = @xmlTransferenciasImpostosXml OUTPUT,
					@p_ValorValido = @blnValorValido OUTPUT,
					@p_Mensagem = @strMensagem OUTPUT,
					@p_TipoValidacaoComissao = 'P';


				SET @decValorTotalAuxiliar = @decValorTotalIndividual;


				-- Calcular Impostos
				EXEC dbo.pr_Fiscalidade_CalcularImpostos
					@p_Produto = @IdProduto,
					@p_Fundo = @IdFundo,
					@p_IdTipoMovimento = 'S',
					@p_IdMovimentoIndividual = 0,
					@p_IdEntidadeParticipante = @IdEntidadePartipante,
					@p_IdMotivoReembolso = NULL,
					@p_DataMovimento = @DataMovimento,
					@p_NumeroUPs = @decNumeroUPsIndividual,
					@p_ValorUPs = @decValorUPsIndividual,
					@p_Comissao = @decComissaoIndividual, 
					@p_Despesas = @p_Despesas,
					@p_Moeda = '',
					@p_TotalInvestido = @decValorTotalIndividual,
					@p_Rendimento = NULL,
					@p_Contas = @Contas,
					@p_PercentagemCapital = NULL,
					@p_TipoContribuicao = @TipoContribuicao,
					-- Contrato
					@p_IdContratoProdutoParticipante = @idContratoProdutoParticipante,
					@p_IdContrato = @IdContrato,
					-- Rendimento Empresa
					@p_RendimentoEmpresa = NULL,
					-- Total investido Empresa
					@p_TotalInvestidoEmpresa = NULL,
					@p_IdTipoReembolso = NULL,
					@p_RecalcularImpostos = 1,
					@p_ValorTotalMovimentoMultiplo = @decValorTotalIndividual,
					@p_UniqueIdentifier = @strUniqueIdentifier,
					-- User Job
					@p_UserJob = @p_UserJob,
					-- Valor de IRS calculado
					@p_tblMovimentosIndividuaisImpostos = @tblMovimentosIndividuaisImpostos, -- esta informação é enviada a nulo, recalculada no SP e retornam o xml abaixo.
					@p_ImpostosResultados = @xmlTransferenciasImpostosXml OUTPUT,
					@p_TotalImpostos = @decTotalImpostos OUTPUT,
					@p_ValorTotal = @decValorTotalAuxiliar OUTPUT;


				SET @decValorUPsIndividual = @decValorTotalIndividual - @decComissaoIndividual - @decTotalImpostos - @p_Despesas;


				IF(@decTotalImpostos <> 0)
				BEGIN
						
					DELETE FROM SubscricoesIndividuaisImpostos WHERE IdSubscricaoIndividual = @IdSubscricaoindividual

					--Inserir novos Impostos para subscrição Individual
					INSERT INTO dbo.SubscricoesIndividuaisImpostos 
					(
						IdSubscricaoIndividual,
						IdCodigoImposto,
						IdOrdem,
						IdTabelasTaxas,
						ValorImposto,
						TaxaAplicada,
						ValorCalculado,
						TaxaCalculada,
						ValorManual
					)
					SELECT
						@IdSubscricaoindividual,
						TXML.IdCodigoImposto,
						TXML.IdOrdem,
						TXML.IdTabelasTaxas,
						TXML.ValorImposto,
						TXML.TaxaAplicada,
						TXML.ValorCalculado,
						TXML.TaxaCalculada,
						TXML.ValorManual
					FROM dbo.[udf_MovimentosIndividuaisImpostos_GetRecordsFromXml](@xmlTransferenciasImpostosXml) AS TXML;
				END;


				UPDATE SubscricoesIndividuais 
				SET
					TaxaComissao = @decTaxaComissaoIndividual,
					Comissao = @decComissaoIndividual,
					ValorUPs = @decValorUPsIndividual,
					ValorTotal = @decValorTotalIndividual,
					NumeroUPs = @decNumeroUPsIndividual,
					Estado = CASE
									WHEN(@decNumeroUPsIndividual IS NOT NULL
										AND @decNumeroUPsIndividual > 0)
									THEN ' '
									ELSE 'M'
								END
				WHERE IdSubscricaoIndividual = @IdSubscricaoindividual;

			END; -- fim ciclo
			END;


			BEGIN -- Atualizar totais da subscrição -----

			WITH CTE_SubsMulti AS
			(
				SELECT
					DISTINCT(TAR.IdSubscricaoMultipla)
				FROM #TransferenciasARecalcular AS TAR
			),
			SomaSubscricoes_CTE(
					IdSubscricaoMultipla, 
					SomaValorUP, 
					SomaComissoes, 
					SomaValorTotal,
					SomaDespesas) AS
			(
				SELECT	SI.IdSubscricaoMultipla, 
						SUM(SI.ValorUPs), 
						SUM(SI.Comissao), 
						SUM(SI.ValorTotal),
						SUM(SI.Despesas)
				FROM SubscricoesIndividuais AS SI
				INNER JOIN dbo.SubscricoesMultiplas AS SM
					ON SM.IdSubscricaoMultipla = SI.IdSubscricaoMultipla
				INNER JOIN CTE_SubsMulti AS CTE
					ON CTE.IdSubscricaoMultipla = SM.IdSubscricaoMultipla
				GROUP BY SI.IdSubscricaoMultipla
			)
			UPDATE SM
			SET 
				ValorUPs = CTE.SomaValorUP,
				Comissoes = CTE.SomaComissoes,
				ValorTotal = CTE.SomaValorTotal,
				Despesas = CTE.SomaDespesas
			FROM SubscricoesMultiplas AS SM
			INNER JOIN SomaSubscricoes_CTE AS CTE 
				ON SM.IdSubscricaoMultipla = CTE.IdSubscricaoMultipla;

			END;


			BEGIN -- Copiar histórico do reembolso para a subscrição --

			DECLARE @counterRowNumber int = 0,
					@maxRowNumber int = 0,
					@subscricaoHistorico numeric(18,0),
					@reembolsoHistorico numeric(18,0);

			DECLARE @transferenciasAtualizarHistorico TABLE
			(
				RowNumber INT IDENTITY(1,1) NOT NULL,
				IdSubscricaoMultipla NUMERIC(18,0) NOT NULL,
				IdReembolsoMultiplo NUMERIC(18,0) NOT NULL
			);

			-- Filtrar subscrições totalmente recalculadas
			INSERT INTO @transferenciasAtualizarHistorico
			(
				IdSubscricaoMultipla,
				IdReembolsoMultiplo
			)
			SELECT
				TAR.IdSubscricaoMultipla,
				RM.IdReembolsoMultiplo
			FROM #TransferenciasARecalcular AS TAR
			INNER JOIN dbo.SubscricoesMultiplas AS SM
				ON SM.IdSubscricaoMultipla = TAR.IdSubscricaoMultipla
			INNER JOIN dbo.TransferenciasInternas AS TI
				ON TI.IdSubscricaoMultipla = SM.IdSubscricaoMultipla
			INNER JOIN dbo.ReembolsosMultiplos AS RM
				ON RM.IdReembolsoMultiplo = TI.IdReembolsoMultiplo
			INNER JOIN dbo.SubscricoesIndividuais AS SI
				ON SI.IdSubscricaoMultipla = SM.IdSubscricaoMultipla
			WHERE RM.IdEstado = 'A' -- Ativo
				AND SI.Estado = ' ' -- Ativo
			GROUP BY TAR.IdSubscricaoMultipla,
						RM.IdReembolsoMultiplo;

			DELETE TAH
			FROM @transferenciasAtualizarHistorico AS TAH
			INNER JOIN SubscricoesIndividuais AS SI
				ON SI.IdSubscricaoMultipla = TAH.IdSubscricaoMultipla
			WHERE SI.Estado <> ' ';
			
			SET @maxRowNumber =
			(
				SELECT
					MAX(RowNumber)
				FROM @transferenciasAtualizarHistorico
			);

			WHILE(@maxRowNumber > @counterRowNumber)
			BEGIN

				SET @counterRowNumber = @counterRowNumber + 1;

				SELECT
					@reembolsoHistorico = IdReembolsoMultiplo,
					@subscricaoHistorico = IdSubscricaoMultipla
				FROM @transferenciasAtualizarHistorico
				WHERE RowNumber = @counterRowNumber;

				EXEC pr_Transferencias_CopiarHistoricoReembolsoParaSubscricao
					@p_IdReembolsoMultiplo = @reembolsoHistorico,
					@p_IdSubscricaoMultipla = @subscricaoHistorico;

			END

			END


		END;

		--

		BEGIN ----- Subscrições Saída Direitos Adquiridos -----

			BEGIN ----- Obter Lista dos Movimentos de Subscrição SDA a serem Recalculados -----
				CREATE TABLE #SubscricoesDireitosAdquiridosARecalcular
				(
					RowNumber             INT, 
					SequenceNumber			INT, 
					IdSubscricaoIndividual NUMERIC(18, 0), 
					IdSubscricaoMultipla   NUMERIC(18, 0), 
					IdContrato				NUMERIC(18, 0), 
					SM_DataMovimento		DATE, 
					IdFundo				INT,
					Contas				VARCHAR(500),
					PlanoPensoes		   NVARCHAR(10)
				);

				INSERT INTO #SubscricoesDireitosAdquiridosARecalcular
				(
					RowNumber, 
					SequenceNumber,
					IdSubscricaoIndividual, 
					IdSubscricaoMultipla, 
					IdContrato, 
					SM_DataMovimento, 
					IdFundo,
					Contas,
					PlanoPensoes
				)
				SELECT 
					ROW_NUMBER() OVER(ORDER BY SI.IdSubscricaoIndividual DESC) AS RowNumber,
					ROW_NUMBER() OVER(PARTITION BY SI.IdSubscricaoMultipla ORDER BY SI.IdSubscricaoMultipla DESC) AS SequenceNumber,
					SI.IdSubscricaoIndividual,
					SI.IdSubscricaoMultipla,
					C.IdContrato,
					SM.DataMovimento,
					F.IdFundo,
					SI.Conta,
					ISNULL(MI.Valor, '')
				FROM dbo.SubscricoesMultiplas AS SM
					INNER JOIN dbo.SubscricoesIndividuais AS SI ON SI.IdSubscricaoMultipla = SM.IdSubscricaoMultipla
					INNER JOIN dbo.Contratos AS C ON C.IdContrato = SI.IdContrato
					INNER JOIN dbo.Cotacoes AS C0 ON C0.DataCotacao = SM.DataMovimento
													AND C0.IdFundo = C.IdFundo
					INNER JOIN CfgClt.Fundos AS F ON F.IdFundo = C.IdFundo
					LEFT JOIN dbo.MovimentosInformacoes AS MI 
							ON MI.IdMovimentoIndividual = SI.IdSubscricaoIndividual
							AND MI.TipoMovimento = 'S'
							AND MI.Info = 2000
					INNER JOIN dbo.ContaReservaMovimentosRelacao AS CRMR -- Subscrições relacionadas com relacao à Conta reserva
						ON CRMR.IdSubscricaoMultipla = SM.IdSubscricaoMultipla
					INNER JOIN @p_ListaFundosUpdate AS LFU
						ON LFU.DataCotacao = SM.DataMovimento
					INNER JOIN dbo.ReembolsosMultiplos AS RM
						ON RM.IdReembolsoMultiplo = CRMR.IdReembolsoMultiplo
						AND RM.IdEstado = 'A'
				WHERE F.SuporteCotacaoDesconhecida = 1
						AND SI.Estado = 'M'
				GROUP BY SI.IdSubscricaoIndividual,
							SI.IdSubscricaoMultipla,
							C.IdContrato,
							SM.DataMovimento,
							F.IdFundo,
							SI.Conta,
							MI.Valor;
			END;

			--

			BEGIN -- Atualizar valor total da subscrição SDA com base no reembolso -----
				
				-- Reinicializar varáveis do processo das Transferências
				DECLARE @EntidadeReserva bit;
				
				SET @numFundos = 0;
				SET	@fundoCounter = 0;
				SET	@valorRestante = 0;
				SET	@percentagemRestante = 0;
				SET @valorASubscrever = 0;
				SET @percentagemDistribuicao = 0;
				DELETE FROM @tblMultiSubscriptions; -- reutilizar tabela do processo das Transferências

				INSERT INTO @tblMultiSubscriptions (IdSubscricaoMultipla)
				SELECT DISTINCT(IdSubscricaoMultipla)
				FROM #SubscricoesDireitosAdquiridosARecalcular;

				SET @movCounter = 0;
				SET @numMovimentos =
				(
					SELECT MAX(RowNumber)
					FROM @tblMultiSubscriptions
				);

				-- Percorrer subscrições múltiplas
				WHILE (@numMovimentos > @movCounter)
				BEGIN
				
					SET @movCounter = @movCounter + 1;

					-- Quantidade de detalhes por fundo para calcular
					SET @fundoCounter = 0;
					SET @numFundos =
					(
						SELECT MAX(TAR.SequenceNumber)
						FROM #SubscricoesDireitosAdquiridosARecalcular AS TAR
						INNER JOIN @tblMultiSubscriptions AS MS
							ON MS.IdSubscricaoMultipla = TAR.IdSubscricaoMultipla
						WHERE MS.RowNumber = @movCounter
					);

					SET @EntidadeReserva = 
					(
						SELECT
							TOP 1 E.EntidadeReserva
						FROM #SubscricoesDireitosAdquiridosARecalcular AS SDA
						INNER JOIN @tblMultiSubscriptions AS MS
							ON MS.IdSubscricaoMultipla = SDA.IdSubscricaoMultipla
						INNER JOIN dbo.SubscricoesMultiplas AS SM
							ON SM.IdSubscricaoMultipla = MS.IdSubscricaoMultipla
						INNER JOIN dbo.ContratosProdutoParticipantes AS CPP
							ON CPP.IdContratoProdutoParticipante = SM.IdContratoProdutoParticipante
						INNER JOIN dbo.Entidades AS E
							ON E.IdEntidade = CPP.IdEntidadeParticipante
						WHERE MS.RowNumber = @movCounter
					);

					-- Subscrição de entrada na conta reserva
					IF(@EntidadeReserva=1)
					BEGIN
						
						-- Espelhar valores do reembolso na subscrição
						UPDATE SI
						SET SI.NumeroUPs = RI.NumeroUPs,
							SI.PercentagemDistribuicao = RI.PercentagemDistribuicao,
							SI.ValorTotal = RI.ValorTotal
						FROM #SubscricoesDireitosAdquiridosARecalcular AS SDA
						INNER JOIN @tblMultiSubscriptions AS MS
							ON MS.IdSubscricaoMultipla = SDA.IdSubscricaoMultipla
							AND MS.RowNumber = @movCounter
						INNER JOIN dbo.SubscricoesIndividuais AS SI
							ON SI.IdSubscricaoMultipla = MS.IdSubscricaoMultipla
						INNER JOIN dbo.Contratos AS CSUB
							ON CSUB.IdContrato = SI.IdContrato
						INNER JOIN ContaReservaMovimentosRelacao AS CRMR
							ON CRMR.IdSubscricaoMultipla = SDA.IdSubscricaoMultipla
						INNER JOIN dbo.ReembolsosIndividuais AS RI
							ON RI.IdReembolsoMultiplo = CRMR.IdReembolsoMultiplo
						INNER JOIN dbo.Contratos AS CREMB
							ON CREMB.IdContrato = RI.IdContrato
						WHERE CSUB.IdFundo = CREMB.IdFundo;
							

					END
					ELSE
					BEGIN

						-- Percentagem máxima a distribuir
						SET @percentagemRestante = 100;
						-- Valor máximo a distribuir = valor do reembolso múltiplo
						SELECT TOP 1
							@valorRestante = RM.ValorTotal
						FROM #SubscricoesDireitosAdquiridosARecalcular AS SDA
						INNER JOIN @tblMultiSubscriptions AS MS
							ON MS.IdSubscricaoMultipla = SDA.IdSubscricaoMultipla
						INNER JOIN ContaReservaMovimentosRelacao AS CRMR
							ON CRMR.IdSubscricaoMultipla = SDA.IdSubscricaoMultipla
						INNER JOIN dbo.ReembolsosMultiplos AS RM
							ON RM.IdReembolsoMultiplo = CRMR.IdReembolsoMultiplo
							AND RM.IdEstado = 'A'
						WHERE MS.RowNumber = @movCounter;		

						-- Retirar valores já unitizados (aplicável quando o recálculo é feito um fundo de cada vez)
						SELECT
							@percentagemRestante = @percentagemRestante - ISNULL(SUM(SI.PercentagemDistribuicao), 0),
							@valorRestante = @valorRestante - ISNULL(SUM(SI.ValorTotal), 0)
						FROM #SubscricoesDireitosAdquiridosARecalcular AS SDA
						INNER JOIN @tblMultiSubscriptions AS MS
							ON MS.IdSubscricaoMultipla = SDA.IdSubscricaoMultipla
						INNER JOIN dbo.ContaReservaMovimentosRelacao AS CRMR
							ON CRMR.IdSubscricaoMultipla = SDA.IdSubscricaoMultipla
						INNER JOIN dbo.ReembolsosMultiplos AS RM
							ON RM.IdReembolsoMultiplo = CRMR.IdReembolsoMultiplo
							AND RM.IdEstado = 'A'
						INNER JOIN dbo.SubscricoesIndividuais AS SI
							ON SI.IdSubscricaoMultipla = SDA.IdSubscricaoMultipla
							AND SI.Estado = ''
						WHERE MS.RowNumber = @movCounter;

						-- Percorrer subscrições individuais da subscrição múltipla
						WHILE (@numFundos > @fundoCounter)
						BEGIN

							SET @fundoCounter = @fundoCounter + 1;

							DECLARE @idSubscricaoIndividualSaidaDireitos numeric(18,0);

							-- Utilizar somatório do que já foi distribuído para evitar excessos por arredondamento
							-- ValorASubscrever = ValorRestante x PercentagemFundo / PercentagemRestante
							SELECT
								@idSubscricaoIndividualSaidaDireitos = SI.IdSubscricaoIndividual,
								@percentagemDistribuicao = SI.PercentagemDistribuicao,
								@valorASubscrever = CASE WHEN @percentagemRestante = 0
														THEN 0
														ELSE ROUND(@valorRestante * (SI.PercentagemDistribuicao / 100) / (@percentagemRestante / 100), 2)
													END
							FROM #SubscricoesDireitosAdquiridosARecalcular AS TAR
							INNER JOIN @tblMultiSubscriptions AS MS
								ON MS.IdSubscricaoMultipla = TAR.IdSubscricaoMultipla
							INNER JOIN dbo.SubscricoesIndividuais AS SI 
								ON SI.IdSubscricaoIndividual = TAR.IdSubscricaoIndividual
							WHERE MS.RowNumber = @movCounter
								AND TAR.SequenceNumber = @fundoCounter;
				
							UPDATE dbo.SubscricoesIndividuais
							SET
								ValorTotal = @valorASubscrever
							WHERE IdSubscricaoIndividual = @idSubscricaoIndividualSaidaDireitos;

							-- Esgotar valores já aplicados
							SET @percentagemRestante = @percentagemRestante - @percentagemDistribuicao;
							SET	@valorRestante = @valorRestante - @valorASubscrever;
						END -- fim ciclo fundos
					END
				END -- fim ciclo Subs Multiplas
			END;

			--

			BEGIN -- Recalcular valores da subscrição -----
				DECLARE @bitValidaComissao bit;
				SET @xmlSubscricoesImpostosXml = null;
				SET @decValorTotalAuxiliar = 0;
			
				SET @MaxNumber =
				(
					SELECT COUNT(IdContrato)
					FROM #SubscricoesDireitosAdquiridosARecalcular
				);
				SET @MinNumber = 0;

				-- Percorrer cada subscrição para recalcular os valores todos.
				WHILE @MaxNumber > @MinNumber
				BEGIN
					SET @MinNumber = @MinNumber + 1;

					SELECT
						@IdSubscricaoindividual = SDA.IdSubscricaoIndividual,
						@decValorTotalIndividual = SI.ValorTotal,
						@IdFundo = SDA.IdFundo,
						@IdProduto = CP.IdProduto,
						@strMensagem = '',
						@Contas = SI.Conta,
						@PlanoPensoes = SDA.PlanoPensoes,
						@DataMovimento = SM.DataMovimento,
						@TipoContrato = CP.IdTipoContrato,
						@TipoContribuinte = SM.IdTipoActividadeContribuinte,
						@IdContribuinte = CP.IdEntidadeContribuinte,
						@IdContrato = SI.IdContrato,
						@decTaxaComissaoIndividual = SI.TaxaComissao,
						@decComissaoIndividual = SI.Comissao,
						@decValorUPsIndividual = SI.ValorUPs,
						@decNumeroUPsIndividual = SI.NumeroUPs,
						@xmlSubscricoesImpostosXml = NULL,
						@IdEntidadePartipante = CPP.IdEntidadeParticipante,
						@p_Despesas = SI.Despesas,
						@idContratoProdutoParticipante = SM.IdContratoProdutoParticipante,
						@bitValidaComissao = CASE WHEN SM.IdTipoSubscricao = 'J'
												THEN 0
												ELSE 1
											END,
						@EntidadeReserva = E.EntidadeReserva
					FROM #SubscricoesDireitosAdquiridosARecalcular AS SDA
					INNER JOIN dbo.SubscricoesIndividuais AS SI 
						ON SI.IdSubscricaoIndividual = SDA.IdSubscricaoIndividual
					INNER JOIN dbo.SubscricoesMultiplas AS SM
						ON SM.IdSubscricaoMultipla = SI.IdSubscricaoMultipla
					INNER JOIN dbo.ContratosProdutoParticipantes AS CPP
						ON CPP.IdContratoProdutoParticipante = SM.IdContratoProdutoParticipante
					INNER JOIN dbo.ContratosProduto AS CP
						ON CP.IdContratoProduto = CPP.IdContratoProduto
					INNER JOIN dbo.Entidades AS E
						ON E.IdEntidade = CPP.IdEntidadeParticipante
					WHERE SDA.RowNumber = @MinNumber;

					IF(@EntidadeReserva=1)
					BEGIN

						-- Calcular por número de UPs
						EXEC dbo.pr_SubscricoesIndividuais_CalcularValoresPorNumeroUP
							@p_IdFundo = @IdFundo,
							@p_IdProduto = @IdProduto,
							@p_IdContribuinte = @IdContribuinte,
							@p_TipoContribuinte =  @TipoContribuinte,
							@p_TipoContrato = @TipoContrato,
							@p_TipoMovimento = 'I',
							@p_DataMovimento = @DataMovimento,
							@p_IdContrato = @IdContrato,
							@p_Conta = @Contas,
							@p_PlanoPensoes = @PlanoPensoes,
							@p_ManterComissao = 1,
							@p_ManterValorTotal = 0,
							@p_Despesas = @p_Despesas OUTPUT,
							@p_TaxaComissao = @decTaxaComissaoIndividual OUTPUT,
							@p_Comissao = @decComissaoIndividual OUTPUT,
							@p_ValorUPs = @decValorUPsIndividual OUTPUT,
							@p_ValorTotal = @decValorTotalIndividual OUTPUT,
							@p_NumeroUPs = @decNumeroUPsIndividual OUTPUT,
							@p_MovimentosImpostosXml = @xmlSubscricoesImpostosXml OUTPUT,
							@p_ValorValido = @blnValorValido OUTPUT,
							@p_Mensagem = @strMensagem OUTPUT,
							@p_ValidaComissao = @bitValidaComissao; -- se o movimento for de entrada na conta reserva não deverá ter comissão.

					END
					ELSE
					BEGIN

						-- Calcular por valor total
						EXEC dbo.pr_SubscricoesIndividuais_CalcularValoresPorValorTotal
							@p_IdFundo = @IdFundo,
							@p_IdProduto = @IdProduto,
							@p_IdContribuinte = @IdContribuinte,
							@p_TipoContribuinte =  @TipoContribuinte,
							@p_TipoContrato = @TipoContrato,
							@p_TipoMovimento = 'I',
							@p_DataMovimento = @DataMovimento,
							@p_IdContrato = @IdContrato,
							@p_PlanoPensoes = @PlanoPensoes,
							@p_Conta = @Contas,
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
							@p_TipoValidacaoComissao = 'P',
							@p_ValidaComissao = @bitValidaComissao; -- se o movimento for de entrada na conta reserva não deverá ter comissão.

						SET @decValorTotalAuxiliar = @decValorTotalIndividual;

					END

					SET @strUniqueIdentifier = left(newid(),24);

					-- Calcular Impostos
					EXEC dbo.pr_Fiscalidade_CalcularImpostos
						@p_Produto = @IdProduto,
						@p_Fundo = @IdFundo,
						@p_IdTipoMovimento = 'S',
						@p_IdMovimentoIndividual = 0,
						@p_IdEntidadeParticipante = @IdEntidadePartipante,
						@p_IdMotivoReembolso = NULL,
						@p_DataMovimento = @DataMovimento,
						@p_NumeroUPs = @decNumeroUPsIndividual,
						@p_ValorUPs = @decValorUPsIndividual,
						@p_Comissao = @decComissaoIndividual, 
						@p_Despesas = @p_Despesas,
						@p_Moeda = '',
						@p_TotalInvestido = @decValorTotalIndividual,
						@p_Rendimento = NULL,
						@p_Contas = @Contas,
						@p_PercentagemCapital = NULL,
						@p_TipoContribuicao = @TipoContribuicao,
						-- Contrato
						@p_IdContratoProdutoParticipante = @idContratoProdutoParticipante,
						@p_IdContrato = @IdContrato,
						-- Rendimento Empresa
						@p_RendimentoEmpresa = NULL,
						-- Total investido Empresa
						@p_TotalInvestidoEmpresa = NULL,
						@p_IdTipoReembolso = NULL,
						@p_RecalcularImpostos = 1,
						@p_ValorTotalMovimentoMultiplo = @decValorTotalIndividual,
						@p_UniqueIdentifier = @strUniqueIdentifier,
						-- User Job
						@p_UserJob = @p_UserJob,
						-- Valor de IRS calculado
						@p_tblMovimentosIndividuaisImpostos = @tblMovimentosIndividuaisImpostos,
						@p_ImpostosResultados = @xmlSubscricoesImpostosXml OUTPUT,
						@p_TotalImpostos = @decTotalImpostos OUTPUT,
						@p_ValorTotal = @decValorTotalAuxiliar OUTPUT;

					SET @decValorUPsIndividual = @decValorTotalIndividual - @decComissaoIndividual - @decTotalImpostos - @p_Despesas;

					IF(@decTotalImpostos <> 0)
					BEGIN
						
						DELETE FROM SubscricoesIndividuaisImpostos WHERE IdSubscricaoIndividual = @IdSubscricaoindividual

						--Inserir novos Impostos para subscrição Individual
						INSERT INTO dbo.SubscricoesIndividuaisImpostos 
						(
							IdSubscricaoIndividual,
							IdCodigoImposto,
							IdOrdem,
							IdTabelasTaxas,
							ValorImposto,
							TaxaAplicada,
							ValorCalculado,
							TaxaCalculada,
							ValorManual
						)
						SELECT
							@IdSubscricaoindividual,
							TXML.IdCodigoImposto,
							TXML.IdOrdem,
							TXML.IdTabelasTaxas,
							TXML.ValorImposto,
							TXML.TaxaAplicada,
							TXML.ValorCalculado,
							TXML.TaxaCalculada,
							TXML.ValorManual
						FROM dbo.[udf_MovimentosIndividuaisImpostos_GetRecordsFromXml](@xmlSubscricoesImpostosXml) AS TXML;
					END;


					UPDATE SubscricoesIndividuais 
					SET
						TaxaComissao = @decTaxaComissaoIndividual,
						Comissao = @decComissaoIndividual,
						ValorUPs = @decValorUPsIndividual,
						ValorTotal = @decValorTotalIndividual,
						NumeroUPs = @decNumeroUPsIndividual,
						Estado = CASE
										WHEN(@decNumeroUPsIndividual IS NOT NULL
											OR @decNumeroUPsIndividual > 0)
										THEN ' '
										ELSE 'M'
									END
					WHERE IdSubscricaoIndividual = @IdSubscricaoindividual;
				END; -- fim ciclo
			END;

			--

			BEGIN -- Atualizar totais da subscrição -----
				WITH CTE_SubsMulti AS
				(
					SELECT
						DISTINCT(TAR.IdSubscricaoMultipla)
					FROM #SubscricoesDireitosAdquiridosARecalcular AS TAR
				),
				SomaSubscricoes_CTE(
						IdSubscricaoMultipla, 
						SomaValorUP, 
						SomaComissoes, 
						SomaValorTotal,
						SomaDespesas) AS
				(
					SELECT	SI.IdSubscricaoMultipla, 
							SUM(SI.ValorUPs), 
							SUM(SI.Comissao), 
							SUM(SI.ValorTotal),
							SUM(SI.Despesas)
					FROM SubscricoesIndividuais AS SI
					INNER JOIN dbo.SubscricoesMultiplas AS SM
						ON SM.IdSubscricaoMultipla = SI.IdSubscricaoMultipla
					INNER JOIN CTE_SubsMulti AS CTE
						ON CTE.IdSubscricaoMultipla = SM.IdSubscricaoMultipla
					GROUP BY SI.IdSubscricaoMultipla
				)
				UPDATE SM
				SET 
					ValorUPs = CTE.SomaValorUP,
					Comissoes = CTE.SomaComissoes,
					ValorTotal = CTE.SomaValorTotal,
					Despesas = CTE.SomaDespesas
				FROM SubscricoesMultiplas AS SM
				INNER JOIN SomaSubscricoes_CTE AS CTE 
					ON SM.IdSubscricaoMultipla = CTE.IdSubscricaoMultipla;
			END;

			--

			BEGIN -- Copiar histórico do reembolso para a subscrição --

			DECLARE @counterRow int = 0,
					@maxRow int = 0,
					@subHistorico numeric(18,0),
					@rembHistorico numeric(18,0);

			DECLARE @subsParticipanteAtualizarHistorico TABLE
			(
				RowNumber INT IDENTITY(1,1) NOT NULL,
				IdSubscricaoMultipla NUMERIC(18,0) NOT NULL,
				IdReembolsoMultiplo NUMERIC(18,0) NOT NULL
			);

			-- Filtrar subscrições totalmente recalculadas
			INSERT INTO @subsParticipanteAtualizarHistorico
			(
				IdSubscricaoMultipla,
				IdReembolsoMultiplo
			)
			SELECT
				TAR.IdSubscricaoMultipla,
				RM.IdReembolsoMultiplo
			FROM #SubscricoesDireitosAdquiridosARecalcular AS TAR
			INNER JOIN dbo.SubscricoesMultiplas AS SM
				ON SM.IdSubscricaoMultipla = TAR.IdSubscricaoMultipla
			INNER JOIN dbo.SubscricoesIndividuais AS SI
				ON SI.IdSubscricaoMultipla = SM.IdSubscricaoMultipla
			INNER JOIN dbo.ContaReservaMovimentosRelacao AS CRMR
				ON CRMR.IdSubscricaoMultipla = SM.IdSubscricaoMultipla
			INNER JOIN dbo.ReembolsosMultiplos AS RM
				ON RM.IdReembolsoMultiplo = CRMR.IdReembolsoMultiplo
			WHERE RM.IdEstado = 'A' -- Ativo
				AND SI.Estado = ' ' -- Ativo
				AND CRMR.IdReembolsoMultiplo_RelacaoCR > 0 -- Participante
			GROUP BY TAR.IdSubscricaoMultipla,
						RM.IdReembolsoMultiplo;

			DELETE TAH
			FROM @subsParticipanteAtualizarHistorico AS TAH
			INNER JOIN SubscricoesIndividuais AS SI
				ON SI.IdSubscricaoMultipla = TAH.IdSubscricaoMultipla
			WHERE SI.Estado <> ' ';
			
			SET @maxRow =
			(
				SELECT
					MAX(RowNumber)
				FROM @subsParticipanteAtualizarHistorico
			);

			WHILE(@maxRow > @counterRow)
			BEGIN

				SET @counterRow = @counterRow + 1;

				SELECT
					@rembHistorico = IdReembolsoMultiplo,
					@subHistorico = IdSubscricaoMultipla
				FROM @subsParticipanteAtualizarHistorico
				WHERE RowNumber = @counterRow;

				EXEC pr_Transferencias_CopiarHistoricoReembolsoParaSubscricao
					@p_IdReembolsoMultiplo = @rembHistorico,
					@p_IdSubscricaoMultipla = @subHistorico;

			END

			END

		END;

		--

		BEGIN ----- Update Estado dos Contratos afetados (Ativo/anulado) -----
			Declare @IdContrato_update Numeric(18,0),
					@NumeroContrato Numeric(18,0),
					@IdSituacao Varchar(1);

			CREATE TABLE #AllContractsAfected
							(RowNumber			int not null IDENTITY (1,1),
							 IdContrato			NUMERIC(18, 0), 
							 DataMovimento		datetime,
							 Contas				varchar(500),
							);

			INSERT INTO #AllContractsAfected 
				(IdContrato, DataMovimento, Contas)
			SELECT 
				RAR.IdContrato, 
				RAR.RM_DataReembolso, 
				RAR.Contas
			FROM #ReembolsosARecalcular AS RAR
			INNER JOIN dbo.ReembolsosMultiplosExtensao AS RME
				ON RME.IdReembolsoMultiplo = RAR.IdReembolsoMultiplo
			WHERE RME.AnularContratosTotalmenteReembolsados = 1;
			
			INSERT INTO #AllContractsAfected
				(IdContrato, DataMovimento, Contas)
			SELECT 
				SAR.IdContrato,
				SAR.SM_DataMovimento,
				SAR.Contas
			FROM #SubscricoesARecalcular AS SAR
			WHERE SAR.IdContrato not in (SELECT idContrato FROM #AllContractsAfected)

			INSERT INTO #AllContractsAfected
				(IdContrato, DataMovimento, Contas)
			SELECT 
				TAR.IdContrato,
				TAR.SM_DataMovimento,
				TAR.Contas
			FROM #TransferenciasARecalcular AS TAR
			WHERE TAR.IdContrato NOT IN (SELECT idContrato FROM #AllContractsAfected)

			INSERT INTO #AllContractsAfected
				(IdContrato, DataMovimento, Contas)
			SELECT 
				SDA.IdContrato,
				SDA.SM_DataMovimento,
				SDA.Contas
			FROM #SubscricoesDireitosAdquiridosARecalcular AS SDA
			WHERE SDA.IdContrato NOT IN (SELECT idContrato FROM #AllContractsAfected)

			-- Varáveis de apoio
			SET @MaxNumber = (SELECT COUNT(IdContrato) FROM #AllContractsAfected)
			SET @MinNumber = 0;

			-- percorrer os contratos e atualizar estado dos contratos
			WHILE @MaxNumber > @MinNumber
			BEGIN
				SET @MinNumber = @MinNumber + 1;

				SELECT 
					@IdContrato_update = ACA.IdContrato,
					@IdSituacao = CASE
										WHEN Contrato.UPsContrato <= 0
										THEN 'N'
										ELSE 'A'
									END,
					@NumeroContrato = ISNULL(C.NumeroContrato,0)
				FROM #AllContractsAfected AS ACA
				INNER JOIN Contratos AS C
						ON C.IdContrato = ACA.IdContrato
				OUTER APPLY
					(
						SELECT ISNULL(SaldoNUP, 0)
					FROM dbo.udf_Contratos_ObterSaldoAData('',ACA.DataMovimento, 'A', C.IdContrato, default)
					) Contrato(UPsContrato)
				WHERE ACA.RowNumber = @MinNumber;

				-- Se variável for != 0 significa que é necessário atualizar estado
				IF(@IdContrato_update != 0)
				BEGIN
					-- Evoluir Contratos provisórios -- falta saber se envio o evolve Parent ou não
					IF(@NumeroContrato = 0)
					BEGIN
						EXEC	[dbo].[pr_Contratos_EvolveProvisoryContract]
									@p_IdContrato = @IdContrato_update,
									@p_EvolveParentContract = 1,
									@p_Username = @p_Username
					END;

					--chamar SP change Situatiuon
					EXEC [dbo].[pr_Contratos_ChangeSituation]
							@p_IdContrato = @IdContrato_update,
							@p_IdSituacao = @IdSituacao,
							@p_Username = @p_Username	
				END;
				SET @IdContrato_update = 0;
				SET @NumeroContrato = 0;
			END;
		END;

		--

        DROP TABLE #ReembolsosARecalcular;
		DROP TABLE #SubscricoesARecalcular;
		DROP TABLE #TransferenciasARecalcular;
		DROP TABLE #SubscricoesDireitosAdquiridosARecalcular;
		DROP TABLE #AllContractsAfected;
		DROP TABLE #tblSubscricoesIndividuaisTotais;

    END;