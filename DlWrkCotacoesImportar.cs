//------------------------------------------------------------------------------------------------------------------------
// DATA LAYER
//------------------------------------------------------------------------------------------------------------------------
using System;
using System.Collections;
using System.Collections.Generic;
using System.Data;

// I2S
using i2S.PEF.DL.Framework.Databases;
using i2S.PEF.ML.Movimentos.Cotacoes;
using i2S.PEF.ML.Framework.Models;
using i2S.PEF.Common.Utilities;
using System.Data.SqlClient;

namespace i2S.PEF.DL.Movimentos.Cotacoes
{
	/// <summary>
	/// Classe			: DlWrkCotacoesImportar.cs
	/// Tabela			: WRKCOTACOESIMPORTAR
	/// Autor			: Hélder Ferreira
	/// Data de geração : 31-03-2014
	/// </summary>
	public class DlWrkCotacoesImportar : DlBase
	{

		#region ----- Insert -----

		/// <summary>
		/// Inserir as cotações cotações que estão a ser trabalhadas na tabela work
		/// </summary>
		/// <param name="prmMlCotacoes">Instância do modelo do registo a inserir</param>
		/// <returns>Result model</returns>
		public MlResult insert(List<MlWrkCotacoesImportar> prmCotacoes)
		{
			List<SqlParameter> _lstParameters = new List<SqlParameter>();
			DataTable _dtRecords;
			DataTable _dtCotacoes;

			// Prepare Cotacoes table
			// Convert model list to DataTable
			_dtCotacoes = MlWrkCotacoesImportar.modelToDataTable(prmCotacoes, true);
			// Apply specific schema for Table Type parameter
			_dtCotacoes = _dtCotacoes.aplicarSchema(MlWrkCotacoesImportar.getSchemaTableType);

			// Add parameter
			addInSqlTableTypeParameter(ref _lstParameters,
										"p_TabelaCotacoes",
										"typ_WrkCotacoesImportar",
										_dtCotacoes);

			// Execute Stored Procedure
			return executeStoredProcedure("pr_WrkCotacoesImportar_Insert",
											out _dtRecords,
											_lstParameters);
		}

		#endregion

		#region ----- Delete -----

		/// <summary>
		/// Apaga registos por UserJob
		/// </summary>
		/// <param name="prmUserJob">UserJob</param>
		/// <returns>Result model</returns>
		public MlResult apagaRegistosUtilizador(String prmUserJob)
		{
			// Lista de Parametros
			List<SqlParameter> _lstParametros = new List<SqlParameter>();

			// UserJob
			addInSqlParameter(ref _lstParametros,
								"p_UserJob",
								prmUserJob);

			// Executar procedimento
			return executeStoredProcedure("pr_WrkCotacoesImportar_Delete",
											_lstParametros);
		}

		#endregion

		#region ----- Obter Cotações Grid -----

		/// <summary>
		/// Obter Cotações para a Grid
		/// </summary>
		/// <param name="prmIdEmissao">prmPageNumber</param>
		/// <param name="prmPageRows">prmPageRows</param>
		/// <param name="prmRecords">Result records DataTable (output)</param>
		/// <returns>Result model</returns>
		public MlResult obterCotacoesGrid(Int32 prmPageNumber,
											Int32 prmPageRows,
											List<MlQueryFields> prmMlQueryFields,
											out DataTable prmRecords)
		{
			return executeDynamicSearchStoredProcedure("pr_WrkCotacoesImportar_Pesquisa",
														prmPageNumber,
														prmPageRows,
														prmMlQueryFields,
														out prmRecords);
		}

		#endregion

		#region ----- Submeter Cotações -----

		/// <summary>
		/// Submeter cotações da tabela WrkCotacoesImportar na tabela de Cotações
		/// </summary>
		/// <param name="prmUserJob">UserJob</param>
		/// <param name="prmIdDataInputType">Id Data Input type</param>
		/// <param name="prmUsername">Username</param>
		/// <returns>Result model</returns>
		public MlResult submeterCotacoes(String prmUserJob,
											String prmIdDataInputType,
											String prmUsername)
		{
			// Lista de Parametros
			List<SqlParameter> _lstParametros = new List<SqlParameter>();

			// UserJob
			addInSqlParameter(ref _lstParametros,
								"p_UserJob",
								prmUserJob);
			// Id Data Input type
			addInSqlParameter(ref _lstParametros,
								"p_IdDataInputType",
								prmIdDataInputType);
			// Username
			addInSqlParameter(ref _lstParametros,
								"p_Username",
								prmUsername);

			// Executar procedimento
			return executeStoredProcedure("pr_WrkCotacoesImportar_Submeter",
											_lstParametros);
		}

		#endregion

		#region ----- Select Cotações com erros -----

		/// <summary>
		/// Obter cotações da tabela work das cotações
		/// </summary>
		/// <param name="prmTodasCotacoes">True - Obter Todas as cotações | False - Obter só as que apresentam erros</param>
		/// <returns>DataTable com as cotações e erros</returns>
		public DataSet obterCotacoesWorkTable(String prmUserJob, Boolean prmTodasCotacoes)
		{
			List<Object> _lstParametros = new List<Object>();
			DataSet _dsRegistos = null;

			try
			{
				// UserJob
				_lstParametros.Add(pObjSqlHelp.getParametersObj("p_UserJob",
																prmUserJob,
																ParameterDirection.Input));

				// Flag que identifica se so obtem as cotações com erros
				_lstParametros.Add(pObjSqlHelp.getParametersObj("p_ObterTodasCotacoes",
																prmTodasCotacoes,
																ParameterDirection.Input));

				// Executar procedimento
				_dsRegistos = pObjSqlHelp.GetSqlHelper().GetDataSetUsingSP("pr_WrkCotacoesImportar_ObterErros", new ArrayList(_lstParametros));

			}
			catch(Exception _exException)
			{
				handleException(_exException);
			}

			// Obter registo
			return _dsRegistos;
		}

		#endregion

		#region ----- Valida e Calcula as cotações -----

		/// <summary>
		/// Valida e Calcula as cotações
		/// </summary>
		/// <param name="prmUserJob">UserJob</param>
		/// <returns>Result model</returns>
		public MlResult validaCalculaCotacoes(String prmUserJob)
		{
			// Lista de Parametros
			List<SqlParameter> _lstParametros = new List<SqlParameter>();

			// UserJob
			addInSqlParameter(ref _lstParametros,
								"p_UserJob",
								prmUserJob);

			// Executar procedimento
			return executeStoredProcedure("pr_WrkCotacoesImportar_ValidarCalcular", 
											_lstParametros);
		}

		#endregion

		#region ----- Verificar se existe cotações com erros -----

		/// <summary>
		/// Verificar se existe cotações com erros
		/// </summary>
		/// <param name="prmUserJob">UserJob</param>
		/// <returns>Falg Com a Informação se e possiel submeter as cotações. True - É possivél | False - Não é.</returns>
		public Boolean verificaExistenciaCotacoesComErros(String prmUserJob)
		{
			List<Object> _lstParametros = new List<Object>();
			DataSet _dsRegistos = null;

			Boolean _blEpossivelSubmeter = false;

			try
			{
				// UserJob
				_lstParametros.Add(pObjSqlHelp.getParametersObj("p_UserJob",
																prmUserJob,
																ParameterDirection.Input));
				// Executar procedimento
				_dsRegistos = pObjSqlHelp.GetSqlHelper().GetDataSetUsingSP("pr_WrkCotacoesImportar_VerificaExistenciaErros", new ArrayList(_lstParametros));


				// Se for contiver dados quer dizer que tem cotações passiveis de serem submetidas
				if(ClDataTables.verificarDataSetTemDados(_dsRegistos))
				{
					_blEpossivelSubmeter = true;
				}
			}
			catch(Exception _exException)
			{
				handleException(_exException);
			}

			// Obter registo
			return _blEpossivelSubmeter;
		}

		#endregion

		#region ----- Verificar se é possivel submeter cotações -----

		/// <summary>
		/// Verifica se é possivel submeter alguma das cotações
		/// </summary>
		/// <param name="prmUserJob">UserJob</param>
		/// <returns>Flag Com a Informação se e possivel submeter as cotações. True - É possivel | False - Não é.</returns>
		public Boolean verificaSePossivelSubmeterCotacoes(String prmUserJob)
		{
			List<Object> _lstParametros = new List<Object>();
			DataSet _dsRegistos = null;

			Boolean _blEpossivelSubmeter = false;

			try
			{
				// UserJob
				_lstParametros.Add(pObjSqlHelp.getParametersObj("p_UserJob",
																prmUserJob,
																ParameterDirection.Input));
				// Executar procedimento
				_dsRegistos = pObjSqlHelp.GetSqlHelper().GetDataSetUsingSP("pr_WrkCotacoesImportar_VerificarSePossivelSubmeter", new ArrayList(_lstParametros));


				// Se for contiver dados quer dizer que tem cotações passiveis de serem submetidas
				if(ClDataTables.verificarDataSetTemDados(_dsRegistos))
				{
					_blEpossivelSubmeter = true;
				}
			}
			catch(Exception _exException)
			{
				handleException(_exException);
			}

			// Obter registo
			return _blEpossivelSubmeter;
		}

        #endregion

        #region ----- Obter cotações com erro -----

        /// <summary>
        /// Verifica e obtém cotações com erros
        /// </summary>
        /// <param name="prmUserJob">UserJob</param>
        /// <param name="prmRecords"></param>
        /// <returns></returns>
        public MlResult verificaObterCotacoesComErro(string prmUserJob, out DataTable prmRecords)
        {
            // Parameters list
            List<SqlParameter> _lstParameters = new List<SqlParameter>();

            // UserJob
            addInSqlParameter(ref _lstParameters,
                                "p_UserJob",
                                prmUserJob);

            // Execute SP
            return executeStoredProcedure("pr_WrkCotacoesImportar_ObterCotacoesErro",
                                            out prmRecords,
                                            _lstParameters);
        }

        #endregion
    }
}
