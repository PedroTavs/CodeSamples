using System;
using System.Collections.Generic;
using System.Data;
using System.Text;

// I2S
using i2S.PEF.BL.Framework.Security;
using i2S.PEF.DL.Movimentos.Cotacoes;
using _nsMlApplicationConfigurationsClasses = i2S.PEF.ML.ApplicationConfigurations.Classes;
using i2S.PEF.ML.Movimentos.Cotacoes;
using i2S.PEF.ML.Framework.Models;
using i2S.PEF.ML.Movimentos.Classes;
using i2S.PEF.Common.Utilities.Office.Excel;
using i2S.PEF.Common.Utilities;

namespace i2S.PEF.BL.Movimentos.Cotacoes
{
	/// <summary>
	/// Classe			: BlWrkCotacoesImportar.cs
	/// Tabela			: WRKCOTACOESIMPORTAR
	/// Autor			: Hélder Ferreira
	/// Data de geração : 31-03-2014
	/// </summary>
	public class BlWrkCotacoesImportar
	{

		#region ----- Variáveis de instância -----

		private DlWrkCotacoesImportar _objDlWrkCotacoesImportar;

		#endregion

		#region ----- Propriedades ------

		#region ----- pObjDlWrkCotacoesImportar -----

		/// <summary>
		/// Objecto DlWrkCotacoesImportar
		/// </summary>
		private DlWrkCotacoesImportar pObjDlWrkCotacoesImportar
		{
			get
			{
				if(_objDlWrkCotacoesImportar == null)
				{
					_objDlWrkCotacoesImportar = new DlWrkCotacoesImportar();
				}
				return _objDlWrkCotacoesImportar;
			}
		}

		#endregion

		#endregion

		#region ----- Insert -----

		/// <summary>
		/// Insert
		/// </summary>
		/// <param name="prmCotacoes">Cotacoes</param>
		/// <returns>Result model</returns>
		public MlResult insert(List<MlWrkCotacoesImportar> prmCotacoes)
		{
			return pObjDlWrkCotacoesImportar.insert(prmCotacoes);
		}

		#endregion

		#region ----- Delete -----

		/// <summary>
		/// Apaga registos por UserJob
		/// </summary>
		/// <param name="prmUserJob"></param>
		/// <returns>Result model</returns>
		public MlResult apagaRegistosUtilizador(String prmUserJob)
		{
			return pObjDlWrkCotacoesImportar.apagaRegistosUtilizador(prmUserJob);
		}

		#endregion

		#region ----- Obter Cotações Grid -----

		/// <summary>
		/// Obter linhas de uma Emissão
		/// </summary>
		/// <param name="prmPageNumber">Numero de página</param>
		/// <param name="prmPageRows">Quantidade de linhas por página</param>
		/// <param name="prmMlQueryFields">Query Fields</param>
		/// <param name="prmRecords">Result records DataTable (output)</param>
		/// <returns>Result model</returns>
		public MlResult obterCotacoesGrid(Int32 prmPageNumber,
											Int32 prmPageRows,
											List<MlQueryFields> prmMlQueryFields,
											out DataTable prmRecords)
		{
			return pObjDlWrkCotacoesImportar.obterCotacoesGrid(prmPageNumber,
																prmPageRows,
																prmMlQueryFields,
																out prmRecords);
		}

		#endregion

		#region ----- Submeter Cotações -----

		/// <summary>
		/// Submeter cotações da tabela WrkCotacoesImportar na tabela de Cotações
		/// </summary>
		/// <param name="prmBlPrincipal">BlPrincipal object</param>
		/// <param name="prmDataInputType">Data Input type</param>
		/// <returns>Result model</returns>
		public MlResult submeterCotacoes(BlPrincipal prmBlPrincipal,
											_nsMlApplicationConfigurationsClasses.ClEnumerations.DataInputTypes prmDataInputType)
		{
			return pObjDlWrkCotacoesImportar.submeterCotacoes(prmBlPrincipal.pUserJob,
																prmDataInputType.getCodigoCharToString(),
																prmBlPrincipal.pUsername);
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
			return _objDlWrkCotacoesImportar.verificaExistenciaCotacoesComErros(prmUserJob);
		}

		#endregion

		#region ----- Exportar cotações com Erros -----

		/// <summary>
		/// Exportar cotações da tabela work das cotações
		/// </summary>
		/// <param name="prmTodasCotacoes">True - Obter Todas as cotações | False - Obter só as que apresentam erros</param>
		/// <returns>DataTable com as cotações e erros</returns>
		public MlResult exportarCotacoesWorkTable(String prmUserJob, Boolean prmTodasCotacoes, String prmCaminhoExportacao)
		{
			MlResult _objMlResult = new MlResult();

			// Obtem dados da Base de dados
			DataSet _dsErrosExcel = pObjDlWrkCotacoesImportar.obterCotacoesWorkTable(prmUserJob, prmTodasCotacoes);

			StringBuilder _sbErrosExportacaoExcel = new StringBuilder();

			// Verifica se obteve dados para fazer o excel
			if(!ClDataTables.verificarDataSetTemDados(_dsErrosExcel))
			{
				_objMlResult.pSuccess = false;
				_objMlResult.addError(ClConstants.ClMessagesWrkCotacoesImportar.NaoFoiPossivelObterCotacoesDaBaseDados);
			}
			else
			{
				// Cria ficheiro Excel
				_objMlResult.pSuccess = ClExcelInterop.createExcelFileFromDataSet(_dsErrosExcel, prmCaminhoExportacao, ref _sbErrosExportacaoExcel);
				_objMlResult.addError(_sbErrosExportacaoExcel.ToString());
			}

			
			return _objMlResult;
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
			return pObjDlWrkCotacoesImportar.validaCalculaCotacoes(prmUserJob);
		}

		#endregion

		#region ----- Verificar se é possivel submeter cotações -----

		/// <summary>
		/// Verifica se é possível submeter alguma das cotações
		/// </summary>
		/// <param name="prmUserJob">UserJob</param>
		/// <returns>Flag a informar se e possível submeter as cotações. True - É possivél | False - Não é.</returns>
		public Boolean verificaSePossivelSubmeterCotacoes(String prmUserJob)
		{
			return pObjDlWrkCotacoesImportar.verificaSePossivelSubmeterCotacoes(prmUserJob);
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
            return pObjDlWrkCotacoesImportar.verificaObterCotacoesComErro(prmUserJob, out prmRecords);
        }

        /// <summary>
        /// Obter mensagens de erro por fundo
        /// </summary>
        /// <param name="prmUserJob">UserJob</param>
        /// <returns></returns>
        public string obterFundosMensagensErro(string prmUserJob)
        {
            // Auxiliary object
            DataTable prmRecords;

            // Get message
            return verificaObterCotacoesComErro(prmUserJob, out prmRecords).pSuccess ? obterFundosMensagensErro(prmRecords) : string.Empty;
        }

        /// <summary>
        /// Obter mensagens de erro por fundo
        /// </summary>
        /// <param name="prmRecords"></param>
        /// <returns></returns>
        public string obterFundosMensagensErro(DataTable prmRecords)
        {
            // Validate if datatabe is not empty
            if (prmRecords.verificarDataTableTemDados())
            {
                // Auxiliary string builder
                StringBuilder sb = new StringBuilder();

                // Iterate data table rows
                for (int i = 0; i < prmRecords.Rows.Count; i++)
                {
                    // Build and append message
                    sb.AppendFormat("{0} {1} {2}", "Fundo", prmRecords.Rows[i].getFieldValue<string>("Fundo"), prmRecords.Rows[i].getFieldValue<string>("DadosComErros"));

                    // Append line break
                    sb.AppendLine();
                }

                // Return built message
                return sb.ToString();
            }

            // Return empty message
            return string.Empty;
        }

        #endregion

    }
}
