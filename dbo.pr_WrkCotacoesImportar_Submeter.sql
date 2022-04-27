
-----------------------------------------------------------------
-- Autor:		Helder Ferreira
-- Data:		2014-05-09
-- Reviewer:		Pedro Tavares
-- Review Date:		2021-02-01
-- Descrição:		Submeter cotações da tabela WrkCotacoesImportar na tabela Cotacoes
-----------------------------------------------------------------
CREATE PROCEDURE [dbo].[pr_WrkCotacoesImportar_Submeter] 
	@p_UserJob         VARCHAR(10), 
    @p_IdDataInputType NVARCHAR(1), 
    @p_Username        VARCHAR(50)
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @MaxRowNumber NUMERIC(18, 0) = 0, 
				@RowNumber NUMERIC(18, 0) = 0, 
				@RowNumberMovimento NUMERIC(18, 0) = 0, 
				@MaxRowNumberMovimento NUMERIC(18, 0) = 0, 
				@p_IdProduto NUMERIC(18, 0), 
				@p_IdFundo SMALLINT, 
				@p_DataCotacao DATETIME, 
				@p_NumeroUnidadesParticipacao DECIMAL(22, 12), 
				@p_Cotacao DECIMAL(19, 12), 
				@p_IdContribuinte INT, 
				@p_IdEntidadeParticipante INT, 
				@p_TipoContribuinte VARCHAR(1), 
				@p_TipoContrato VARCHAR(1), 
				@p_TipoMovimento VARCHAR(1), 
				@p_DataMovimento DATETIME, 
				@p_IdContrato NUMERIC(18, 0), 
				@p_Conta VARCHAR(400), 
				@p_ManterComissao BIT, 
				@p_ManterValorTotal BIT, 
				@p_EstadoSubscricao VARCHAR(1), 
				@p_Despesas DECIMAL(10, 2), -- out
				@p_TaxaComissao DECIMAL(5, 2), -- out
				@p_Comissao DECIMAL(10, 2), -- out
				@p_ValorUPs DECIMAL(15, 2), -- out
				@p_ValorTotal DECIMAL(15, 2), -- out
				@p_NumeroUPs DECIMAL(19, 12), -- out
				@p_MovimentosImpostosXml XML, 
				@p_ValorValido BIT, -- out
				@p_Mensagem VARCHAR(400), -- out;
				@p_Estado VARCHAR(1), 
				@p_IdEntidadeBalcao INT, 
				@p_Observacoes NVARCHAR(200), 
				@p_Moeda NVARCHAR(3)= 'EUR', 
				@p_DataPrimeiraSubscricao DATETIME, 
				@p_Rendimento DECIMAL(15, 2), 
				@p_IdTipoContrato NVARCHAR(1), 
				@p_DataDevida DATETIME, 
				@p_IdEntidadeNib NUMERIC(18, 0), 
				@p_MetodoPagamento NVARCHAR(1), 
				@p_Utilizador VARCHAR(50), 
				@p_IdEntidadeContratoEmpresa INT, 
				@p_SubscricoesIndividuais dbo.typ_SubscricoesIndividuais, 
				@p_MovimentosImpostos dbo.typ_MovimentosIndividuaisImpostos, 
				@p_IdContratoProduto NUMERIC(18, 0), 
				@p_IdContratoProdutoParticipante NUMERIC(18, 0), 
				@p_IdMovimentoExterno1 NVARCHAR(200) = NULL, 
				@p_IdMovimentoExterno2 NVARCHAR(200) = NULL, 
				@p_IdSubscricaoMultipla NUMERIC(18, 0), 
				@p_IdEntidadeContribuinteContrato INT, 
				@p_MlResultDatabaseOutput XML= NULL;
        
		CREATE TABLE #tbl_CotacoesFundos
        (
			IdWrkCotacao NUMERIC(18, 0), 
			IdFundo      SMALLINT, 
			DataCotacao  DATETIME
			PRIMARY KEY(IdWrkCotacao)
        );

        DECLARE @tbl_ListaFundosUpdate dbo.typ_ListaFundosUpdate;

        CREATE TABLE #tbl_ListaProdutos
        (
			RowNumber NUMERIC(18, 0), 
			IdProduto SMALLINT, 
			IdFundo   SMALLINT
        );

        INSERT INTO #tbl_CotacoesFundos
        SELECT WCI.IdCotacao, 
                C.IdFundo, 
                MAX(C.DataCotacao)
        FROM WORK.WrkCotacoesImportar AS WCI
        INNER JOIN dbo.Cotacoes AS C 
			ON C.DataCotacao <= WCI.DataCotacao
            AND C.IdFundo = WCI.Fundo
        WHERE WCI.UserJob = @p_UserJob
        GROUP BY WCI.IdCotacao, 
                C.IdFundo;

        INSERT INTO dbo.Cotacoes
        (
			IdFundo, 
			DataCotacao, 
			NumeroUnidadesParticipacao, 
			Cotacao, 
			IdDataInputType, 
			Username, 
			DataHora
        )
        SELECT WCI.Fundo, 
                WCI.DataCotacao, 
                NumeroUP.RoundValue, 
                WCI.ValorCotacao, 
                @p_IdDataInputType, 
                @p_Username, 
                SYSDATETIME()
        FROM WORK.WrkCotacoesImportar AS WCI
        INNER JOIN #tbl_CotacoesFundos AS TCF 
			ON TCF.IdWrkCotacao = WCI.IdCotacao
        INNER JOIN dbo.Cotacoes AS C 
			ON C.DataCotacao = TCF.DataCotacao
			AND C.IdFundo = TCF.IdFundo
        CROSS APPLY
		(
			SELECT RoundValue
			FROM dbo.udf_Math_RoundUPs(WCI.Fundo, C.NumeroUnidadesParticipacao)
		) AS NumeroUP
        WHERE UserJob = @p_UserJob
                AND Estado = 0
                AND DadosComErros = ''
                AND UserJob = @p_UserJob;

        -- Obter cotações que devem ser atualizadas 
        INSERT INTO @tbl_ListaFundosUpdate
        (
			IdFundo, 
			DataCotacao, 
			NumeroUnidadesParticipacao, 
			Cotacao
        )
        SELECT WCI.Fundo, 
                WCI.DataCotacao, 
                WCI.NumeroUP, 
                WCI.ValorCotacao
        FROM WORK.WrkCotacoesImportar AS WCI
        WHERE WCI.Estado = 2
                AND WCI.DadosComErros = ''
                AND WCI.UserJob = @p_UserJob;

        -- Obter numero de cotações a alterar 
        SET @MaxRowNumber =
        (
            SELECT MAX(RowNumber)
            FROM @tbl_ListaFundosUpdate
        );

        -- Ciclo para atualizar valores de cotações 
        WHILE @MaxRowNumber > @RowNumber
        BEGIN 
            -- Incrementar contador do ciclo
            SET @RowNumber+=1;

            -- Obter parametros dos fundos 
            SELECT @p_IdFundo = LFU.IdFundo, 
                    @p_DataCotacao = LFU.DataCotacao, 
                    @p_NumeroUnidadesParticipacao = LFU.NumeroUnidadesParticipacao, 
                    @p_Cotacao = LFU.Cotacao
            FROM @tbl_ListaFundosUpdate AS LFU
            WHERE RowNumber = @RowNumber;

            -- Atualizar cotações 
            EXEC dbo.pr_Cotacoes_Update 
                    @p_IdFundo = @p_IdFundo, 
                    @p_DataCotacao = @p_DataCotacao, 
                    @p_NumeroUnidadesParticipacao = @p_NumeroUnidadesParticipacao, 
                    @p_Cotacao = @p_Cotacao, 
                    @p_IdDataInputType = @p_IdDataInputType, 
                    @p_Username = @p_Username;
        END;


		BEGIN ----- Recalcular Movimentos Ativos (se existirem) -----
			DECLARE @MinNumber int;
			DECLARE @Fundo_Individual dbo.typ_ListaFundosUpdate;

			SET @MinNumber = 0;
			SET @MaxRowNumber =
						(
							SELECT COUNT(IdFundo)
							FROM @tbl_ListaFundosUpdate
						);

			-- Chamar o método de recalculo para cada fundo
			WHILE @MaxRowNumber > @MinNumber
			BEGIN
				SET @MinNumber = @MinNumber + 1;

				INSERT INTO @Fundo_Individual (	
					Cotacao,
					DataCotacao, 
					IdFundo, 
					NumeroUnidadesParticipacao
				)
				SELECT 
					Cotacao,
					DataCotacao,
					IdFundo,
					NumeroUnidadesParticipacao
				FROM @tbl_ListaFundosUpdate AS LF 
				WHERE LF.RowNumber = @MinNumber

				-- Este SP recebe uma lista de fundos mas devido a um desenvolvimento específico 
				-- é conveniente enviar 1 fundo de cada vez.
				EXEC dbo.pr_WrkCotacoesImportar_RecalculoMovimentosAtivos
					@p_userjob = @p_UserJob,
					@p_ListaFundosUpdate = @Fundo_Individual,
					@p_Username = @p_Username;

				DELETE FROM @Fundo_Individual;
			END;
	END;

        -- Recálculo Movimentos Temporários
		DELETE FROM @tbl_ListaFundosUpdate;
		INSERT INTO @tbl_ListaFundosUpdate
        (
			IdFundo, 
			DataCotacao, 
			NumeroUnidadesParticipacao, 
			Cotacao
        )
        SELECT WCI.Fundo, 
                WCI.DataCotacao, 
                WCI.NumeroUP, 
                WCI.ValorCotacao
        FROM WORK.WrkCotacoesImportar AS WCI
        WHERE WCI.Estado <> 1
                AND WCI.DadosComErros = ''
                AND WCI.UserJob = @p_UserJob;

		BEGIN ----- Recalcular Movimentos Temporários -----
			SET @MinNumber = 0;
			SET @MaxRowNumber =
						(
							SELECT COUNT(IdFundo)
							FROM @tbl_ListaFundosUpdate
						);

			-- Chamar o método de recalculo para cada fundo
			WHILE @MaxRowNumber > @MinNumber
			BEGIN
				SET @MinNumber = @MinNumber + 1;

				INSERT INTO @Fundo_Individual (	
					Cotacao,
					DataCotacao, 
					IdFundo, 
					NumeroUnidadesParticipacao
				)
				SELECT 
					Cotacao,
					DataCotacao,
					IdFundo,
					NumeroUnidadesParticipacao
				FROM @tbl_ListaFundosUpdate AS LF 
				WHERE LF.RowNumber = @MinNumber

				-- Este SP recebe uma lista de fundos mas devido a um desenvolvimento específico 
				-- é conveniente enviar 1 fundo de cada vez.
				EXEC dbo.pr_WrkCotacoesImportar_RecalculoMovimentostemporarios 
					@p_userjob = @p_UserJob,
					@p_ListaFundosUpdate = @Fundo_Individual,
					@p_Username = @p_Username;

				DELETE FROM @Fundo_Individual;
			END;
		END;
    END;