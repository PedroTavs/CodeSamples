using System;

namespace i2S.PEF.ML.Movimentos.Cotacoes
{
	public class MlCotacoesExcel
	{

		#region ----- Database Table Fields -----

		/// <summary>
		/// Database Table Fields
		/// </summary>
		public static class DbFields
		{
			public const string Fundo = "Fundo";
			public const string Data = "Data";
			public const string Valor = "Valor";
            public const string Numero_Ups = "Numero_Ups";
        }

		#endregion

		#region ----- Properties -----

		#region ----- Fundo -----

		/// <summary>
		/// Fundo
		/// </summary>
		public string Fundo
		{
			get;
			set;
		}

		#endregion

		#region ----- Data -----

		/// <summary>
		/// Data
		/// </summary>
		public DateTime Data
		{
			get;
			set;
		}

		#endregion

		#region ----- Valor -----

		/// <summary>
		/// Valor
		/// </summary>
		public decimal Valor
		{
			get;
			set;
		}

        #endregion

        #region ----- Numero_Ups -----

        /// <summary>
        /// Numero_Ups
        /// </summary>
        public decimal Numero_Ups
        {
            get;
            set;
        }

        #endregion

        #endregion

    }
}
