//------------------------------------------------------------------------------------------------------------------------
// MODEL
//------------------------------------------------------------------------------------------------------------------------
using System;
using System.Data;

// I2S
using i2S.PEF.ML.Framework.Models;
using i2S.PEF.Common.Utilities;

namespace i2S.PEF.ML.Movimentos.Cotacoes
{
	/// <summary>
	/// Classe			: MlWrkCotacoesImportar.cs
	/// Tabela			: WRKCOTACOESIMPORTAR
	/// Autor			: Hélder Ferreira
	/// Data de geração : 31-03-2014
	/// </summary>
	[Serializable]
	public class MlWrkCotacoesImportar : MlBase<MlWrkCotacoesImportar>
	{

		#region ----- Variaveis de Instância -----
	
		// Utilizador
		String _strUserJob;
		
		// Data trabalho
		DateTime _dtJobDate;
		
		//Id Cotação
		Int64 _intIdCotacao;
		
		// Fundo
		Int16 _intFundo;
		
		// DataCotacao
		DateTime _dtDataCotacao;
		
		// Numero de Ups
		Double _dblNumeroUP;
		
		// Valor do Fundo
		Double _dblValorFundo;
		
		// Valor da cotação
		Decimal _dblValorCotacao;

		// Erros
		String _strDadosComErros;

		#endregion

		#region ----- Propriedades -----

		#region ----- pUserJob -----

		/// <summary>
		/// UserJob
		/// </summary>
		[CampoDB("USERJOB", Parametro = "p_USERJOB", Chave = true)]
		public string pUserJob
		{			
			get
			{
				return _strUserJob;
			}
			set
			{
				_strUserJob = value;
			}
		}

		#endregion

		#region ----- pJobDate -----

		/// <summary>
		/// JobDate
		/// </summary>
		[CampoDB("JOBDATE", Parametro = "p_JOBDATE", Chave = false)]
		public DateTime pJobDate
		{
			get
			{
				return _dtJobDate;
			}
			set
			{
				_dtJobDate = value;
			}
		}

		#endregion

		#region ----- pIdCotacao -----

		/// <summary>
		/// IdCotacao
		/// </summary>
		[CampoDB("IDCOTACAO", Parametro = "p_IDCOTACAO", Chave = true)]
		public long pIdCotacao
		{
			get
			{
				return _intIdCotacao;
			}
			set
			{
				_intIdCotacao = value;
			}
		}

		#endregion

		#region ----- pFundo -----

		/// <summary>
		/// Fundo
		/// </summary>
		[CampoDB("Fundo", Parametro = "p_FUNDO", Chave = true)]
		public short pFundo
		{
			get
			{
				return _intFundo;
			}
			set
			{
				_intFundo = value;
			}
		}

		#endregion

		#region ----- pDataCotacao -----

		/// <summary>
		/// DataCotacao
		/// </summary>
		[CampoDB("DATACOTACAO", Parametro = "p_DATACOTACAO", Chave = true)]
		public DateTime pDataCotacao
		{
			get
			{
				return _dtDataCotacao;
			}
			set
			{
				_dtDataCotacao = value;
			}
		}

		#endregion

		#region ----- pNumeroUP -----

		/// <summary>
		/// NumeroUP
		/// </summary>
		[CampoDB("NUMEROUP", Parametro = "p_NUMEROUP", Chave = false)]
		public double pNumeroUP
		{
			get
			{
				return _dblNumeroUP;
			}
			set
			{
				_dblNumeroUP = value;
			}
		}

		#endregion

		#region ----- pValorFundo -----

		/// <summary>
		/// ValorFundo
		/// </summary>
		[CampoDB("VALORFUNDO", Parametro = "p_VALORFUNDO", Chave = false)]
		public double pValorFundo
		{
			get
			{
				return _dblValorFundo;
			}
			set
			{
				_dblValorFundo = value;
			}
		}

		#endregion

		#region ----- pValorCotacao -----

		/// <summary>
		/// ValorCotacao
		/// </summary>
		[CampoDB("VALORCOTACAO", Parametro = "p_VALORCOTACAO", Chave = false)]
		public Decimal pValorCotacao
		{
			get
			{
				return _dblValorCotacao;
			}
			set
			{
				_dblValorCotacao = value;
			}
		}

		#endregion

		#region ----- p_DadosComErros -----

		/// <summary>
		/// DadosComErros
		/// </summary>
		[CampoDB("DadosComErros", Parametro = "p_DadosComErros", Chave = true)]
		public string p_DadosComErros
		{
			get
			{
				return _strDadosComErros;
			}
			set
			{
				_strDadosComErros = value;
			}
		}

		#endregion
		
		#endregion

		#region ----- Construtores -----

		/// <summary>
		/// Construtor padrão
		/// </summary>
		public MlWrkCotacoesImportar()
		{
		}

		/// <summary>
		/// Construtor que inicializa a instância com a chave do registo
		/// </summary>
		/// <param name="prmUserJob">UserJob</param>
		/// <param name="prmIdCotacao">IdCotacao</param>
		/// <param name="prmFundo">Fundo</param>
		/// <param name="prmDataCotacao">DataCotacao</param>
		public MlWrkCotacoesImportar(string prmUserJob, long prmIdCotacao, short prmFundo, DateTime prmDataCotacao)
		{
			pUserJob = prmUserJob;
			pIdCotacao = prmIdCotacao;
			pFundo = prmFundo;
			pDataCotacao = prmDataCotacao;
		}

		#endregion

		#region ----- Gerador da Estrutura -----

		#region ----- getSchemaDataTable -----

		/// <summary>
		/// Método usado para estruturar uma DataTable com os dados
		/// de instâncias desta classe
		/// </summary>
		/// <param name="prmSchema">Instância de DataTable à qual se vai aplicar o esquema</param>
		public static void getSchemaDataTable(DataTable prmSchema)
		{
			prmSchema.TableName = "WRKCOTACOESIMPORTAR";
			DataColumn _dcColuna;

			_dcColuna = new DataColumn();
			_dcColuna.DataType = Type.GetType("System.String");
			_dcColuna.ColumnName = "USERJOB";
			_dcColuna.Caption = "UserJob";
			prmSchema.Columns.Add(_dcColuna);

			_dcColuna = new DataColumn();
			_dcColuna.DataType = Type.GetType("System.DateTime");
			_dcColuna.ColumnName = "JOBDATE";
			_dcColuna.Caption = "JobDate";
			prmSchema.Columns.Add(_dcColuna);

			_dcColuna = new DataColumn();
			_dcColuna.DataType = Type.GetType("System.Int64");
			_dcColuna.ColumnName = "IDCOTACAO";
			_dcColuna.Caption = "IdCotacao";
			prmSchema.Columns.Add(_dcColuna);

			_dcColuna = new DataColumn();
			_dcColuna.DataType = Type.GetType("System.Int16");
			_dcColuna.ColumnName = "Fundo";
			_dcColuna.Caption = "Fundo";
			prmSchema.Columns.Add(_dcColuna);

			_dcColuna = new DataColumn();
			_dcColuna.DataType = Type.GetType("System.DateTime");
			_dcColuna.ColumnName = "DATACOTACAO";
			_dcColuna.Caption = "DataCotacao";
			prmSchema.Columns.Add(_dcColuna);

			_dcColuna = new DataColumn();
			_dcColuna.DataType = Type.GetType("System.Double");
			_dcColuna.ColumnName = "NUMEROUP";
			_dcColuna.Caption = "NumeroUP";
			prmSchema.Columns.Add(_dcColuna);
			
			_dcColuna = new DataColumn();
			_dcColuna.DataType = Type.GetType("System.Double");
			_dcColuna.ColumnName = "VALORFUNDO";
			_dcColuna.Caption = "ValorFundo";
			prmSchema.Columns.Add(_dcColuna);

			_dcColuna = new DataColumn();
			_dcColuna.DataType = Type.GetType("System.Decimal");
			_dcColuna.ColumnName = "VALORCOTACAO";
			_dcColuna.Caption = "ValorCotacao";
			prmSchema.Columns.Add(_dcColuna);

			_dcColuna = new DataColumn();
			_dcColuna.DataType = Type.GetType("System.String");
			_dcColuna.ColumnName = "DADOSCOMERROS";
			_dcColuna.Caption = "DadosComErros";
			prmSchema.Columns.Add(_dcColuna);
		}

		#endregion

		#region ----- getSchemaTableType -----

		/// <summary>
		/// Método usado para estruturar uma DataTable
		/// para ser enviada como parâmetro Table Type para o SQL Server
		/// </summary>
		/// <param name="prmSchema">Instância de DataTable à qual se vai aplicar o esquema</param>
		public static void getSchemaTableType(ref DataTable prmSchema)
		{
			prmSchema.TableName = "WRKCOTACOESIMPORTAR";
			DataColumn _dcColuna;

			_dcColuna = new DataColumn();
			_dcColuna.DataType = Type.GetType("System.String");
			_dcColuna.ColumnName = "USERJOB";
			_dcColuna.Caption = "UserJob";
			prmSchema.Columns.Add(_dcColuna);

			_dcColuna = new DataColumn();
			_dcColuna.DataType = Type.GetType("System.DateTime");
			_dcColuna.ColumnName = "JOBDATE";
			_dcColuna.Caption = "JobDate";
			prmSchema.Columns.Add(_dcColuna);

			_dcColuna = new DataColumn();
			_dcColuna.DataType = Type.GetType("System.Int64");
			_dcColuna.ColumnName = "IDCOTACAO";
			_dcColuna.Caption = "IdCotacao";
			prmSchema.Columns.Add(_dcColuna);

			_dcColuna = new DataColumn();
			_dcColuna.DataType = Type.GetType("System.Int16");
			_dcColuna.ColumnName = "Fundo";
			_dcColuna.Caption = "Fundo";
			prmSchema.Columns.Add(_dcColuna);

			_dcColuna = new DataColumn();
			_dcColuna.DataType = Type.GetType("System.DateTime");
			_dcColuna.ColumnName = "DATACOTACAO";
			_dcColuna.Caption = "DataCotacao";
			prmSchema.Columns.Add(_dcColuna);

			_dcColuna = new DataColumn();
			_dcColuna.DataType = Type.GetType("System.Decimal");
			_dcColuna.ColumnName = "NUMEROUP";
			_dcColuna.Caption = "NumeroUP";
			prmSchema.Columns.Add(_dcColuna);

			_dcColuna = new DataColumn();
			_dcColuna.DataType = Type.GetType("System.Decimal");
			_dcColuna.ColumnName = "VALORFUNDO";
			_dcColuna.Caption = "ValorFundo";
			prmSchema.Columns.Add(_dcColuna);

			_dcColuna = new DataColumn();
			_dcColuna.DataType = Type.GetType("System.Decimal");
			_dcColuna.ColumnName = "VALORCOTACAO";
			_dcColuna.Caption = "ValorCotacao";
			prmSchema.Columns.Add(_dcColuna);

			_dcColuna = new DataColumn();
			_dcColuna.DataType = Type.GetType("System.String");
			_dcColuna.ColumnName = "DADOSCOMERROS";
			_dcColuna.Caption = "DadosComErros";
			prmSchema.Columns.Add(_dcColuna);
		}

		#endregion

		#endregion

	}
}
