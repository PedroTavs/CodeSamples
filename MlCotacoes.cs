//------------------------------------------------------------------------------------------------------------------------
// MODEL
//------------------------------------------------------------------------------------------------------------------------
using System;

// I2S
using i2S.PEF.ML.Framework.Models;
using i2S.PEF.ML.ApplicationConfigurations.Classes;
using i2S.PEF.Common.Utilities;

namespace i2S.PEF.ML.Movimentos.Cotacoes
{
	/// <summary>
	/// Classe			: MlCotacoes.cs
	/// Tabela			: CfgApp.Cotacoes
	/// Autor			: Rodrigo Paiva
	/// Data de geração : 28-02-2014
	/// </summary>
	[Serializable]
	public class MlCotacoes : MlBase<MlCotacoes>
	{

		#region ----- Database Table Fields -----

		/// <summary>
		/// Database Table Fields
		/// </summary>
		public static class DbFields
		{
			public const String IdFundo = "IdFundo";
			public const String DataCotacao = "DataCotacao";
			public const String NumeroUnidadesParticipacao = "NumeroUnidadesParticipacao";
			public const String Cotacao = "Cotacao";
			public const String ValorFundo = "ValorFundo";
			public const String IdDataInputType = "IdDataInputType";
			public const String Username = "Username";
			public const String DataHora = "DataHora";
		}

		#endregion

		#region ----- Properties -----

		#region ----- IdFundo -----

		/// <summary>
		/// IdFundo
		/// </summary>
		[CampoDB(DbFields.IdFundo, Chave = true)]
		public short IdFundo
		{
			get;
			set;
		}

		#endregion

		#region ----- DataCotacao -----

		/// <summary>
		/// DataCotacao
		/// </summary>
		[CampoDB(DbFields.DataCotacao, Chave = true)]
		public DateTime DataCotacao
		{
			get;
			set;
		}

		#endregion

		#region ----- NumeroUnidadesParticipacao -----

		/// <summary>
		/// NumeroUnidadesParticipacao
		/// </summary>
		[CampoDB(DbFields.NumeroUnidadesParticipacao, Chave = false)]
		public Decimal NumeroUnidadesParticipacao
		{
			get;
			set;
		}

		#endregion

		#region ----- Cotacao -----

		/// <summary>
		/// Cotacao
		/// </summary>
		[CampoDB(DbFields.Cotacao, Chave = false)]
		public Decimal Cotacao
		{
			get;
			set;
		}

		#endregion

		#region ----- ValorFundo -----

		/// <summary>
		/// ValorFundo
		/// </summary>
		[CampoDB(DbFields.ValorFundo, Chave = false, ReadOnly = true)]
		public Decimal ValorFundo
		{
			get;
			private set;
		}

		#endregion

		#region ----- IdDataInputType -----

		/// <summary>
		/// IdDataInputType
		/// </summary>
		[CampoDB(DbFields.IdDataInputType, Chave = false)]
		public String IdDataInputType
		{
			get;
			set;
		}

		#endregion

		#region ----- Username -----

		/// <summary>
		/// Username
		/// </summary>
		[CampoDB(DbFields.Username, Chave = false)]
		public String Username
		{
			get;
			set;
		}

		#endregion

		#region ----- DataHora -----

		/// <summary>
		/// DataHora
		/// </summary>
		[CampoDB(DbFields.DataHora, Chave = false, ReadOnly = true)]
		public String DataHora
		{
			get;
			private set;
		}

		#endregion

		#endregion


		#region ----- Virtual Properties -----

		#region ----- pvIdDataInputType -----

		/// <summary>
		/// Data Input Type enum
		/// </summary>
		public ClEnumerations.DataInputTypes pvIdDataInputType
		{
			get
			{
				ClEnumerations.DataInputTypes _enmDataInputTypes;

				ClEnumerationsBase.getItemEnumeracaoPorChaveChar(IdDataInputType.getChar(),
																ClEnumerations.DataInputTypes.Utilizador,
																out _enmDataInputTypes);

				return _enmDataInputTypes;
			}
			set
			{
				IdDataInputType = value.getCodigoCharToString();
			}
		}

		#endregion

		#endregion

		#region ----- Constructors -----

		/// <summary>
		/// Empty Constructor
		/// </summary>
		public MlCotacoes()
		{
		}

		/// <summary>
		/// Constructor that initializes an instance with key fields
		/// </summary>
		/// <param name="prmIdFundo">IdFundo</param>
		/// <param name="prmDataCotacao">DataCotacao</param>
		public MlCotacoes(short prmIdFundo, DateTime prmDataCotacao)
		{
			IdFundo = prmIdFundo;
			DataCotacao = prmDataCotacao;
		}

		#endregion

	}
}
