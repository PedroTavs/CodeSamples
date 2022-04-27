using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;

// Third-party
using LinqToExcel;

// I2S
using i2S.PEF.DL.Framework.Databases;
using i2S.PEF.ML.Movimentos.Cotacoes;
using i2S.PEF.ML.Framework.Models;
using i2S.PEF.Common.Utilities;
using i2S.PEF.Common.Utilities.Office.Excel;

namespace i2S.PEF.DL.Movimentos.Cotacoes
{
    /// <summary>
    /// Classe			: DlCotacoes.cs
    /// Tabela			: CfgApp.Cotacoes
    /// Autor			: Rodrigo Paiva
    /// Data de geração : 28-02-2014
    /// </summary>
    public class DlCotacoes : DlBase
    {

        #region ----- Construtor -----

        /// <summary>
        /// Construtor
        /// </summary>
        public DlCotacoes()
        {
        }

        #endregion

        #region ----- Procedimentos CRUD -----

        #region ----- Select -----

        /// <summary>
        /// Seleccionar um registo devolvendo um objecto do modelo
        /// </summary>
        /// <param name="prmIdFundo">IdFundo</param>
        /// <param name="prmDataCotacao">Data Cotação</param>
        /// <param name="prmMlCotacoes">Model do registo</param>
        /// <returns>MlResult</returns>
        public MlResult select(Int16 prmIdFundo,
                                DateTime prmDataCotacao,
                                out MlCotacoes prmMlCotacoes)
        {
            List<SqlParameter> _lstParameters = new List<SqlParameter>();
            DataTable _dtRegistos = null;
            MlResult _objMlResult;

            prmMlCotacoes = null;

            // Fundo
            addInSqlParameter(ref _lstParameters,
                                "p_IdFundo",
                                prmIdFundo);

            // Data da Cotação
            addInSqlParameter(ref _lstParameters,
                                "p_DataCotacao",
                                prmDataCotacao);

            // Execute Stored Procedure
            _objMlResult = executeStoredProcedure("pr_Cotacoes_Select",
                                                    out _dtRegistos,
                                                    _lstParameters);

            // Verificar se DataSet tem dados
            if (_dtRegistos.verificarDataTableTemDados())
            {
                prmMlCotacoes = MlCotacoes.dataRowToModel(_dtRegistos.Rows[0]);
            }

            return _objMlResult;
        }

        #endregion

        #region ----- Insert -----

        /// <summary>
        /// Inserir um registo
        /// </summary>
        /// <param name="prmMlCotacoes">Instância do modelo do registo a inserir</param>
        /// <param name="prmUserJob"></param>
        /// <returns>Result model</returns>
        public MlResult insert(MlCotacoes prmMlCotacoes, string prmUserJob)
        {
            // Lista de Parâmetros
            List<SqlParameter> _lstParametros = getSqlParameterListFromModel(prmMlCotacoes, false);

            // UserJob
            addInSqlParameter(ref _lstParametros, 
                                "p_UserJob", 
                                prmUserJob);

            // Executar procedimento
            return executeStoredProcedure("pr_Cotacoes_Insert",
                                            _lstParametros);
        }

        #endregion

        #region ----- Update -----

        /// <summary>
        /// Update de um registo
        /// </summary>
        /// <param name="prmMlCotacoes">Instância do modelo do registo a inserir</param>
        /// <returns>Result model</returns>
        public MlResult update(MlCotacoes prmMlCotacoes)
        {
            // Lista de Parâmetros
            List<SqlParameter> _lstParametros = getSqlParameterListFromModel(prmMlCotacoes, false);

            // Execute Stored Procedure
            return executeStoredProcedure("pr_Cotacoes_Update", _lstParametros);
        }

        #endregion

        #region ----- Delete -----

        /// <summary>
        /// Eliminar um registo
        /// </summary>
        /// <param name="prmMlCotacoes">Instância do modelo do registo a eliminar</param>
        /// <returns>Result model</returns>
        public MlResult delete(MlCotacoes prmMlCotacoes)
        {
            // Lista de Parametros
            List<SqlParameter> _lstParametros = getSqlParameterListFromModel(prmMlCotacoes, true);

            // Executar procedimento
            return executeStoredProcedure("pr_Cotacoes_Delete",
                                            _lstParametros);
        }

        #endregion

        #endregion

        #region ----- Corrigir valor de Unidades de Participação -----

        /// <summary>
        /// Corrigir valor de Unidades de Participação
        /// </summary>
        /// <returns>Result model</returns>
        public MlResult corrigirUnidadesParticipacao()
        {
            // Execução longa - Timeout 0
            return executeStoredProcedure("pr_Cotacoes_CorrigirUnidadesParticipacao",
                                            null,
                                            true,
                                            0);
        }

        #endregion

        #region ----- Obter Cotações por Produto -----

        /// <summary>
        /// Obter Cotações por Produto
        /// </summary>
        /// <param name="prmIdProduto">IdProduto</param>
        /// <param name="prmData">Data</param>
        /// <param name="prmCotacoes">Datatable com Cotações</param>
        /// <returns>Result model</returns>
        public MlResult obterCotacoesPorProduto(Int16 prmIdProduto,
                                                    DateTime prmData,
                                                    out DataTable prmCotacoes)
        {
            List<SqlParameter> _lstParameters = new List<SqlParameter>();

            // IdProduto
            addInSqlParameter(ref _lstParameters,
                                "p_IdProduto",
                                prmIdProduto);

            // Data
            addInSqlParameter(ref _lstParameters,
                                "p_Data",
                                prmData);

            // Execute Stored Procedure
            MlResult _objMlResult = executeStoredProcedure("pr_Cotacoes_ObterCotacoesPorProduto",
                                                            out prmCotacoes,
                                                            _lstParameters);

            return _objMlResult;
        }

        #endregion

        #region ----- Obter Cotações por Fundo -----

        /// <summary>
        /// Obter Cotações por Fundo
        /// </summary>
        /// <param name="prmIdFundo">IdFundo</param>
        /// <param name="prmData">Data</param>
        /// <param name="prmCotacoes">Datatable com Cotações</param>
        /// <returns>Result model</returns>
        public MlResult obterCotacoesPorFundo(Int16 prmIdFundo,
                                                DateTime prmData,
                                                out DataTable prmCotacoes)
        {
            List<SqlParameter> _lstParameters = new List<SqlParameter>();
            prmCotacoes = new DataTable();

            // Fundo
            addInSqlParameter(ref _lstParameters,
                                "p_IdFundo",
                                prmIdFundo);

            // Data
            addInSqlParameter(ref _lstParameters,
                                "p_Data",
                                prmData);

            // Execute Stored Procedure
            return executeStoredProcedure("pr_Cotacoes_ObterCotacoesPorFundo",
                                            out prmCotacoes,
                                            _lstParameters);
        }

        #endregion

        #region ----- Obter Cotações por Data -----

        /// <summary>
        /// Obter Cotações por Data
        /// </summary>
        /// <param name="prmData">Data</param>
        /// <returns>Result model</returns>
        public DataTable obterCotacoesPorData(DateTime prmData)
        {
            DataTable _dtResultados;
            List<SqlParameter> _lstParameters = new List<SqlParameter>();

            // Data
            addInSqlParameter(ref _lstParameters,
                                "p_Data",
                                prmData);

            // Execute Stored Procedure
            executeStoredProcedure("pr_Cotacoes_ObterCotacoesPorData",
                                    out _dtResultados,
                                    _lstParameters);

            return _dtResultados;
        }

        #endregion

        #region ----- Obter todas as Cotações do Fundo -----

        /// <summary>
        /// Obter todas as Cotações do Fundo
        /// </summary>
        /// <param name="prmFundo">Fundo</param>
        /// <returns>Result model</returns>
        public MlResult obterTodasCotacoesDoFundo(Int32 prmPageNumber,
                                                    Int32 prmPageRows,
                                                    List<MlQueryFields> prmMlQueryFields,
                                                    out DataTable prmRecords)
        {
            return executeDynamicSearchStoredProcedure("pr_Cotacoes_ObterTodasCotacoesDoFundo",
                                                        prmPageNumber,
                                                        prmPageRows,
                                                        prmMlQueryFields,
                                                        out prmRecords);
        }

        #endregion

        #region ----- Obter todas as Cotações do Produto -----

        /// <summary>
        /// Obter todas as Cotações do Produto
        /// </summary>
        /// <param name="prmProduto">Produto</param>
        /// <returns>Todas as Cotações do Produto</returns>
        public MlResult obterTodasCotacoesDoProduto(Int32 prmPageNumber,
                                                    Int32 prmPageRows,
                                                    List<MlQueryFields> prmMlQueryFields,
                                                    out DataTable prmRecords)
        {
            return executeDynamicSearchStoredProcedure("pr_Cotacoes_ObterTodasCotacoesDoProduto",
                                                        prmPageNumber,
                                                        prmPageRows,
                                                        prmMlQueryFields,
                                                        out prmRecords);
        }

        #endregion

        #region ----- Excel File to Import - Get data -----

        /// <summary>
        /// Excel File to Import - Get data
        /// </summary>
        /// <param name="prmFilePath">File Path</param>
        /// <param name="prmMlWrkCotacoesImportarMapeamentoCampos">Selected Columns</param>
        /// <param name="prmRecords">Excel file records (output)</param>
        /// <returns>Result</returns>
        public MlResult getImportExcelFileData(String prmFilePath,
                                                MlWrkCotacoesImportarMapeamentoCampos prmMlWrkCotacoesImportarMapeamentoCampos,
                                                out DataTable prmRecords)
        {
            MlResult _objMlResult = new MlResult();
            List<MlCotacoesExcel> _lstMlCotacoesExcel;
            Boolean _blnSucess;
            String _strErros;

            // Initialize output parameters
            prmRecords = null;

            // Handle exceptions
            try
            {
                // Check if File is Excel file
                if (_blnSucess = ClExcel.checkFileIsExcel(prmFilePath,
                                                            out _strErros))
                {
                    // Excel File
                    ExcelQueryFactory _excExcelFile = new ExcelQueryFactory(prmFilePath);

                    // Columns mapping
                    _excExcelFile.AddMapping(MlCotacoesExcel.DbFields.Fundo, prmMlWrkCotacoesImportarMapeamentoCampos.pStrFundo);
                    _excExcelFile.AddMapping(MlCotacoesExcel.DbFields.Data, prmMlWrkCotacoesImportarMapeamentoCampos.pStrData);
                    _excExcelFile.AddMapping(MlCotacoesExcel.DbFields.Valor, prmMlWrkCotacoesImportarMapeamentoCampos.pStrValor);
                    _excExcelFile.AddMapping(MlCotacoesExcel.DbFields.Numero_Ups, prmMlWrkCotacoesImportarMapeamentoCampos.pUnidadesParticipacao);

                    // Get list of records
                    _lstMlCotacoesExcel = (from linha in _excExcelFile.Worksheet<MlCotacoesExcel>(0)
                                           select linha).ToList();

                    // Get DataTable
                    prmRecords = ClCollections.getDataTable(_lstMlCotacoesExcel);
                }
                else
                {
                    // Error
                    _objMlResult.addError(_strErros);
                }
            }
            catch (Exception _exException)
            {
                // Error
                _objMlResult.addError(_exException);
            }

            return _objMlResult;
        }

        #endregion

        #region ----- Obter a cotação do Fundo numa data exata -----

        /// <summary>
        /// Obter a cotação do Fundo numa data exata
        /// </summary>
        /// <param name="prmIdFundo">Id Fundo</param>
        /// <param name="prmData">Data</param>
        /// <param name="prmCotacao">Cotação</param>
        /// <returns>Result Model</returns>
        public MlResult obterCotacaoPorFundoDataExata(Int16 prmIdFundo,
                                                        DateTime prmData,
                                                        Int16 prmDecimalPlaces,
                                                        out Decimal prmCotacao)
        {
            List<SqlParameter> _lstParameters = new List<SqlParameter>();
            MlResult _objMlResult;

            prmCotacao = 0;

            // Id Fundo
            addInSqlParameter(ref _lstParameters,
                                "p_IdFundo",
                                prmIdFundo);

            // Data
            addInSqlParameter(ref _lstParameters,
                                "p_DataCotacao",
                                prmData);

            // Cotação
            SqlParameter _parmCotacao;
            addOutDecimalSqlParameter(ref _lstParameters,
                                        "p_Cotacao",
                                        out _parmCotacao,
                                        Convert.ToInt16(7 + prmDecimalPlaces),
                                        prmDecimalPlaces);

            // Executar procedimento
            _objMlResult = executeStoredProcedure("pr_Cotacoes_ObterCotacaoPorFundoDataExata",
                                                    _lstParameters);

            // Success?
            if (_objMlResult.pSuccess)
            {
                prmCotacao = ClObjectValues.getDecimal(_parmCotacao.Value);
            }

            return _objMlResult;
        }

        #endregion

        #region ----- Verificar se a cotação pode ser alterada -----

        /// <summary>
        /// Verificar se a cotação pode ser alterada
        /// </summary>
        /// <param name="prmIdFundo">Fund Id</param>
        /// <param name="prmData">Date</param>
        /// <param name="prmPodeSerAlterado">Can be changed?</param>
        /// <returns>Result Model</returns>
        public MlResult verificarSeCotacaoPodeSerAlterada(Int16 prmIdFundo,
                                                            DateTime prmData,
                                                            out Boolean prmPodeSerAlterado)
        {
            List<SqlParameter> _lstParameters = new List<SqlParameter>();
            MlResult _objMlResult;

            prmPodeSerAlterado = false;

            // Fund Id
            addInSqlParameter(ref _lstParameters,
                                "p_IdFundo",
                                prmIdFundo);

            // Date
            addInSqlParameter(ref _lstParameters,
                                "p_Data",
                                prmData);

            // Can be changed?
            SqlParameter _parmPodeSerAlterado;
            addOutSqlParameter(ref _lstParameters,
                                "p_PodeSerAlterado",
                                SqlDbType.Bit,
                                out _parmPodeSerAlterado);

            // Executar procedimento
            _objMlResult = executeStoredProcedure("pr_Cotacoes_VerificarSeCotacaoPodeSerAlterada",
                                                    _lstParameters);

            if (_objMlResult.pSuccess)
            {
                prmPodeSerAlterado = ClObjectValues.getBoolean(_parmPodeSerAlterado.Value);
            }

            return _objMlResult;
        }

        #endregion

        #region ----- Obter Fundos com Movimentos num Ano, mas sem Cotação no primeiro dia do Ano seguinte -----

        /// <summary>
        /// Obter Fundos com Movimentos num Ano, mas sem Cotação no primeiro dia do Ano seguinte
        /// </summary>
        /// <param name="prmAno">Ano</param>
        /// <param name="prmExcluirFundosReportesFiscais">Excluir fundos não considerados em reportes fiscais?</param>
        /// <param name="prmFundos">Datatable com Fundos</param>
        /// <returns>Result model</returns>
        public MlResult obterFundosComMovimentosAnoSemCotacaoPrimeiroDiaAnoSeguinte(Int32 prmAno,
                                                                                    Boolean prmExcluirFundosReportesFiscais,
                                                                                    out DataTable prmFundos)
        {
            List<SqlParameter> _lstParameters = new List<SqlParameter>();

            // Parameters:
            // Ano
            addInSqlParameter(ref _lstParameters,
                                "p_Ano",
                                prmAno);

            // ExcluirFundosReportesFiscais
            addInSqlParameter(ref _lstParameters,
                                "p_ExcluirFundosReportesFiscais",
                                prmExcluirFundosReportesFiscais);

            // Execute Stored Procedure
            return executeStoredProcedure("pr_Cotacoes_ObterFundosComMovimentosAnoSemCotacaoPrimeiroDiaAnoSeguinte",
                                            out prmFundos,
                                            _lstParameters);
        }

        #endregion
    }
}
