-- =============================================
-- Author:	Pedro Tavares
-- Create date: 2019-03-27
-- Reviewer:	Pedro Tavares
-- Review Date: 2021-02-12
-- Description:	Distribuição Valores Conta Reserva
-- =============================================
CREATE PROCEDURE [dbo].[pr_IntegracoesMovimentos_DistribuirValoresContaReserva_Proporcional]
(
	@p_IdIntegracao NUMERIC(18, 0), 
	@p_IdChunk      NUMERIC(9, 0)
)
AS
    BEGIN
        SET NOCOUNT ON;
        BEGIN ----- Obter Dados Conta Reserva -----
            -- Tabela temporária para guardar o IDContrato e o Saldo Disponível.
            CREATE TABLE #ContratosValorDisponivel
            (IdEntidadeSuperiora		NUMERIC(18, 0), 
             IdContrato_ContaReserva	NUMERIC(18, 0), 
             ValorTotal_Disponivel		NUMERIC(18, 7), 
             Fundo						SMALLINT
            );

			/* INSERTS Teste - #ContratosValorDisponivel
			INSERT INTO #ContratosValorDisponivel VALUES (123,28,1000,1)
			INSERT INTO #ContratosValorDisponivel VALUES (123,28,50,3)
			INSERT INTO #ContratosValorDisponivel VALUES (123,28,350,2) 
			-- depois tentar acrescentar mais 30 ao ultimo para ver
			*/

            -- Obter os Contratos referentes às Contas Reserva que serão afetadas e obter o seu valor total disponível
            -- Como estamos a analisar várias subscrições que podem ser de fundos diferentes, temos obrigatoriamente que ir buscar os contratos para cada Conta Reserva que é 'afetada'
            INSERT INTO #ContratosValorDisponivel
            (IdEntidadeSuperiora, 
             IdContrato_ContaReserva, 
             ValorTotal_Disponivel, 
             Fundo
            )
			SELECT DISTINCT
				IM.EntidadeContribuinte,
				C.IdContrato,
				ISNULL(SaldoNUP, 0) * CotacaoDia.Cotacao,
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
			WHERE IM.IdIntegracao = @p_IdIntegracao
				AND IM.IdChunk = @p_IdChunk
				AND IM.IdTipoMovimento = 'I'
				AND IM.IdSituacao != 'E'


        END;

        BEGIN ----- Obter Subscrições da tabela IntegraçõesMovimentos -----
            -- Tabela Temporária para guardarmos a lista de subscrições

            CREATE TABLE #ListaSubscricoes
            (IdIntegrationRecord INT, 
             ValorTotal          NUMERIC(18, 7), 
             IdEntidadeSuperiora INT, 
             Fundo               INT
            );
            -- Inserir na tabela a lista com todas as subscrições que têm que ser consideradas para a distribuição
            INSERT INTO #ListaSubscricoes
            (IdIntegrationRecord, 
             ValorTotal, 
             IdEntidadeSuperiora, 
             Fundo
            )
                   SELECT DISTINCT 
                          IM.IdIntegrationRecord, 
                          IM.MovimentoValorBruto, 
                          IE.IdEntidadeSuperiora, 
                          IM.Fundo
                   FROM [Intgr].[IntegracoesMovimentos] AS IM
                        INNER JOIN Intgr.IntegracoesEntidades AS IE ON IM.IdIntegracao = IE.IdIntegracao
                   WHERE IM.IdIntegracao = @p_IdIntegracao
                         AND IM.IdChunk = @p_IdChunk
                         AND IM.IdTipoMovimento = 'I'
						 AND IM.IdSituacao != 'E'
                         AND IE.IdEntidadeSuperiora IN
                   (
                       SELECT #ContratosValorDisponivel.IdEntidadeSuperiora
                       FROM #ContratosValorDisponivel
                   ); -- esta condição garante que só vamos manipular as subscricoes que possuem uma conta reserva para distribuir

        END;

        BEGIN ----- Obter Tabela Subscrições com Valores Acumulados -----

            /*Tabela Temporária que alberga as subscrições com os valores acumulados*/

            CREATE TABLE #ListaSubscricoesValorAcumulado
            (IdIntegrationRecord INT, 
             Fundo               INT, 
             IdEntidadeSuperiora INT, 
             ValorTotal          NUMERIC(18, 7)
            );
            -- Inserir os valores na tabela
            INSERT INTO #ListaSubscricoesValorAcumulado
            (IdIntegrationRecord, 
             Fundo, 
             IdEntidadeSuperiora, 
             ValorTotal
            )
                   SELECT T1.IdIntegrationrecord, 
                          T1.Fundo, 
                          T1.IdEntidadeSuperiora, 
                          SUM(T2.ValorTotal) AS SomaAcumulada
                   FROM #ListaSubscricoes AS T1
                        INNER JOIN #ListaSubscricoes AS T2 ON T1.Fundo = T2.Fundo
                                                              AND T1.IdEntidadeSuperiora = T2.IdEntidadeSuperiora
                                                              AND T1.IdIntegrationRecord >= T2.IdIntegrationRecord
                   WHERE T1.fundo IN
                   (
                       SELECT Fundo
                       FROM #ContratosValorDisponivel
                   )
                   GROUP BY T1.IdIntegrationrecord, 
                            T1.Fundo, 
                            T1.IdEntidadeSuperiora;
           
            -- Tabela Temporária onde contempla as subscrições com Valor Acumulado
            CREATE TABLE #ListaSubscricoesExcedeContaReserva
            (IdIntegrationRecord INT, 
             Fundo               INT, 
             IdEntidadeSuperiora INT, 
             ValorTotal          NUMERIC(18, 7),
            );
            WITH SubsValorAcumulado_CTE
                 AS (SELECT *, 
                            ROW_NUMBER() OVER(PARTITION BY #ListaSubscricoesValorAcumulado.Fundo, 
                                                           #ListaSubscricoesValorAcumulado.IdEntidadeSuperiora
                            ORDER BY #ListaSubscricoesValorAcumulado.Fundo DESC) AS RowNumber  --Deste modo colocamos um RowNumber em cada linha agrupado pelo Fundo
                     FROM #ListaSubscricoesValorAcumulado
                     WHERE #ListaSubscricoesValorAcumulado.ValorTotal >
                     (
                         SELECT ValorTotal_Disponivel
                         FROM #ContratosValorDisponivel
                         WHERE #ContratosValorDisponivel.Fundo = #ListaSubscricoesValorAcumulado.Fundo
                     ))
                 INSERT INTO #ListaSubscricoesExcedeContaReserva
                 (IdIntegrationRecord, 
                  Fundo, 
                  IdEntidadeSuperiora, 
                  ValorTotal
                 )
                        SELECT IdIntegrationRecord, 
                               Fundo, 
                               IdEntidadeSuperiora, 
                               ValorTotal
                        FROM SubsValorAcumulado_CTE
                        WHERE SubsValorAcumulado_CTE.ValorTotal >=
                        (
                            SELECT ValorTotal_Disponivel
                            FROM #ContratosValorDisponivel
                            WHERE Fundo = SubsValorAcumulado_CTE.Fundo
                        )
                              AND RowNumber = 1;

		-- SELECT * FROM #ListaSubscricoesValorAcumulado

        END;

        BEGIN ----- Reembolso Total Conta Reserva + Desdobramento Subscrições -----
            DECLARE @ListaDados TYP_DESDOBRARSUBSCRICOES;
            INSERT INTO @ListaDados
            (IdIntgRecord_SubscricaoADesdobrar, 
             IdEntidadeSuperiora, 
             IdContrato, 
             ValorReembolsar, 
             AcumuladoSubscricaoDesdobrar, 
             AcumuladoAnterior, 
             Valor_SubscricaoT, 
             IdFundo
            )
                   SELECT LCR.IdIntegrationRecord AS IdIntgRecord_SubscricaoADesdobrar, 
                          cvd.IdEntidadeSuperiora, 
                          CVD.IdContrato_ContaReserva, 
                          cvd.ValorTotal_Disponivel AS ValorReembolsar, 
                          LCR.ValorTotal AS AcumuladoSubscricaoDesdobrar, 
                          LCR.ValorTotal - LS.ValorTotal AS AcumuladoAnterior, 
                          LS.ValorTotal AS Valor_Subscricao, 
                          CVD.Fundo
                   FROM #ContratosValorDisponivel AS CVD
                        INNER JOIN #ListaSubscricoesExcedeContaReserva AS LCR ON CVD.IdEntidadeSuperiora = LCR.IdEntidadeSuperiora
                                                                                 AND CVD.Fundo = LCR.Fundo
                        INNER JOIN #ListaSubscricoes AS LS ON LS.IdIntegrationRecord = LCR.IdIntegrationRecord;
            -- Variável para guardar o numero de Contas Reserva que terão que ser reembolsadas
            DECLARE @NumeroRegistos INT;
            SET @NumeroRegistos =
            (
                SELECT COUNT(IdContrato)
                FROM @ListaDados
            );
            IF @NumeroRegistos != 0
                BEGIN
                    --Chamar SP para criar as linhas de reembolso parcial na tabela IntegraçõesMovimentos
                    EXEC pr_IntegracoesMovimentos_DistribuirContaReserva_DesdobrarSubscricao 
                         @listaDados = @ListaDados, 
                         @p_IdIntegracao = @p_IdIntegracao, 
                         @p_IdChunk = @p_IdChunk;
            END;
        END;

        BEGIN ----- Reembolso Parcial da Conta Reserva -----
            DECLARE @ContaReservaAReembolsarParcialmente TYP_CONTARESERVAREEMBOLSAR;
            -- Aqui obtemos quais os dados da conta reserva que terá que ser parcialmente reembolsada e o valor a reembolsar
            WITH CTE_Contas_ReemParcialmente(IdEntidadeSuperiora, 
                                             IdContrato, 
                                             Fundo)
                 AS (SELECT CVD.IdEntidadeSuperiora, 
                            CVD.IdContrato_ContaReserva, 
                            CVD.Fundo
                     FROM #ContratosValorDisponivel AS CVD
                          LEFT JOIN #ListaSubscricoesExcedeContaReserva AS LS ON CVD.Fundo = LS.Fundo
                                                                                 AND CVD.IdEntidadeSuperiora = LS.IdEntidadeSuperiora
                     WHERE LS.Fundo IS NULL)
                 --CTE serve para ir buscar quais os dados das contas que não tiveram o seu valor excedido pelas subscricoes 
                 --(se houver algum registo significa que o valor da conta reserva não foi totalmente alocado logo terá que ser feito um reembolso parcial)
                 INSERT INTO @ContaReservaAReembolsarParcialmente
                 (IdEntidadeSuperiora, 
                  IdContrato, 
                  Valor_Reembolsar, 
                  Fundo
                 )
                        SELECT CTE_Contas_ReemParcialmente.IdEntidadeSuperiora, 
                               CTE_Contas_ReemParcialmente.IdContrato, 
                               TotaisSubscricoes.Total, 
                               CTE_Contas_ReemParcialmente.Fundo
                        FROM CTE_Contas_ReemParcialmente
                             CROSS APPLY
                        (
                            SELECT TOP 1 ValorTotal AS Total
                            FROM #ListaSubscricoesValorAcumulado
                            WHERE IdContrato = CTE_Contas_ReemParcialmente.IdContrato
                                  AND IdEntidadeSuperiora = CTE_Contas_ReemParcialmente.IdEntidadeSuperiora
                                  AND Fundo = CTE_Contas_ReemParcialmente.Fundo
                            ORDER BY ValorTotal DESC
                        ) TotaisSubscricoes;

            -- guardar o numero de registos
            SET @NumeroRegistos =
            (
                SELECT COUNT(IdContrato)
                FROM @ContaReservaAReembolsarParcialmente
            );

            IF @NumeroRegistos != 0
                BEGIN
                    --Chamar SP para criar as linhas de reembolso parcial na tabela IntegraçõesMovimentos
                    EXEC pr_IntegracoesMovimentos_ReembolsarContasReserva 
                         @listaDadosContasReserva = @ContaReservaAReembolsarParcialmente, 
                         @p_IdIntegracao = @p_IdIntegracao, 
                         @p_IdChunk = @p_IdChunk;
            END;
        END;

        BEGIN ----- Update Movimentos (UsaContaReserva e TipoSubscricao) -----
            -- UPDATE de todos os movimentos detalhe afetados pela CR
			
			UPDATE IM
            SET 
                UsaDinheiroContaReserva = 1,
				--TipoSubscricao = 'H',
				IM.MetodoPagamento = 'R',
				MovimentoValorLiquido = MovimentoValorBruto,
				TaxaComissao = null,
				ComissaoValor = 0,
				NumeroUnidadesParticipacao = Unidades.RoundValue
			FROM Intgr.IntegracoesMovimentos AS IM
			LEFT JOIN dbo.Cotacoes AS C0
				ON C0.IdFundo = IM.Fundo
				AND C0.DataCotacao = IM.DataMovimento
			OUTER APPLY
			(
				SELECT RoundValue
				FROM dbo.udf_Math_RoundUPs(IM.Fundo, CASE WHEN C0.Cotacao = 0 
															THEN 0 
															ELSE ISNULL(MovimentoValorBruto / C0.Cotacao, 0)
														END)
			) Unidades
            WHERE IdIntegrationRecord IN
            (
                SELECT IdIntegrationRecord
                FROM #ListaSubscricoesValorAcumulado
                WHERE #ListaSubscricoesValorAcumulado.ValorTotal <=
                (
                    SELECT ValorTotal_Disponivel
                    FROM #ContratosValorDisponivel
                    WHERE #ContratosValorDisponivel.Fundo = #ListaSubscricoesValorAcumulado.Fundo
                )
            )
			AND IdIntegracao = @p_IdIntegracao
			AND IdChunk = @p_IdChunk;

			-- Apagar impostos dos movimentos que usam CR
			DELETE FROM Intgr.IntegracoesMovimentosImpostos
			WHERE IdIntegrationRecord IN (
				SELECT IdIntegrationRecord
					FROM #ListaSubscricoesValorAcumulado
					WHERE #ListaSubscricoesValorAcumulado.ValorTotal <=
					(
						SELECT ValorTotal_Disponivel
						FROM #ContratosValorDisponivel
						WHERE #ContratosValorDisponivel.Fundo = #ListaSubscricoesValorAcumulado.Fundo
					)
			)

			---- Update movimentos detalhe não afetados pela CR
			UPDATE Intgr.IntegracoesMovimentos 
              SET 
                  UsaDinheiroContaReserva = 0
				 --,TipoSubscricao = '3'
            WHERE IdIntegrationRecord IN
            (
                SELECT IdIntegrationRecord
                FROM #ListaSubscricoesValorAcumulado
                WHERE #ListaSubscricoesValorAcumulado.ValorTotal >
                (
                    SELECT ValorTotal_Disponivel
                    FROM #ContratosValorDisponivel
                    WHERE #ContratosValorDisponivel.Fundo = #ListaSubscricoesValorAcumulado.Fundo
                --Aqui é feito o processo inverso ao anterior, vamos bsucar as linhas cujo valor não excede a conta reserva e assim sabemos que estas são as afetadas
                )
            );

			-- Update Movimentos de Cabeçalho (alguns valores estão NULL como default)
			WITH TotaisCabecalho_CTE AS (
				SELECT	IM.IdIntegrationRecord,
					SUM(IM2.MovimentoValorBruto) AS Sum_MovimentoValorBruto,
					SUM(IM2.MovimentoValorLiquido) AS Sum_MovimentoValorLiquido,
					SUM(IM2.ComissaoValor) AS Sum_ComissaoValor,
					SUM(IM2.DespesasValor) AS Sim_DespesasValor,
					IM2.UsaDinheiroContaReserva
				FROM Intgr.IntegracoesMovimentos AS IM
				INNER JOIN Intgr.IntegracoesMovimentos AS IM2
					ON IM.IdIntegrationRecord = IM2.IdIntegrationRecordParent
				WHERE IM.IdIntegracao = @p_IdIntegracao
					AND IM.IdChunk = @p_IdChunk
					AND IM2.IdTipoMovimento = 'I'
				GROUP BY IM.IdIntegrationRecord, IM2.UsaDinheiroContaReserva
			)
			UPDATE IM
			SET 
				MovimentoValorBruto = CTE.Sum_MovimentoValorBruto,
				MovimentoValorLiquido = CTE.Sum_MovimentoValorLiquido,
				DespesasValor = CTE.Sim_DespesasValor,
				ComissaoValor = CTE.Sum_ComissaoValor,
				UsaDinheiroContaReserva = CASE 
												WHEN CTE.UsaDinheiroContaReserva = 0
													THEN 0
													ELSE 1
											 END,
				--,TipoSubscricao = CASE 
				--						WHEN CTE.UsaDinheiroContaReserva = 0
				--							THEN '3'
				--							ELSE 'H'
				--					END
				IM.MetodoPagamento = CASE 
										WHEN CTE.UsaDinheiroContaReserva = 0
											THEN IM.MetodoPagamento
											ELSE 'R'
									END
			FROM Intgr.IntegracoesMovimentos AS IM
			INNER JOIN TotaisCabecalho_CTE AS CTE
				ON IM.IdIntegrationRecord = CTE.IdIntegrationRecord
			WHERE IM.IdIntegracao = @p_IdIntegracao
			AND IM.IdChunk = @p_IdChunk;
		END;

		BEGIN ----- Update Movimentos -----
			EXEC [dbo].[pr_IntegracoesMovimentos_ValidarSubscricoes]
					@p_IdIntegracao = @p_IdIntegracao,
					@p_IdChunk = @p_IdChunk,
					@p_IdArea = N'MS'

			UPDATE Intgr.IntegracoesMovimentos
				SET 
					IdSituacao = 'V'
			WHERE IdIntegracao = @p_IdIntegracao
				AND IdSituacao != 'E'
   		END;

        BEGIN ----- DROP TABLES -----
            DROP TABLE #ListaSubscricoes;
            DROP TABLE #ContratosValorDisponivel;
            DROP TABLE #ListaSubscricoesExcedeContaReserva;
            DROP TABLE #ListaSubscricoesValorAcumulado;
        END;

    END;