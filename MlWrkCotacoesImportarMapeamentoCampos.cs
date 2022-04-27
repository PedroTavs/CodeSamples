using System;

// I2S
using i2S.PEF.ML.Framework.Models;

namespace i2S.PEF.ML.Movimentos.Cotacoes
{
	public class MlWrkCotacoesImportarMapeamentoCampos : MlBase<MlWrkCotacoesImportarMapeamentoCampos>
	{

		#region ----- Variáveis de instância -----
		
		// Mapeamento do Fundo
		private string _strFundo;
		
		// Mapeamento do Valor
		private string _strValor;
		
		// Mapeamento da Data
		private string _strData;

        // Mapeamento do número de unidades de participação
        private string _strUnidadesParticipacao;

        // Usar código do fundo ASF
        private bool _blnUsarCodigoFundoISP;

		#endregion

		#region ----- Propriedades ------

		/// <summary>
		/// pStrFundo
		/// </summary>
		public string pStrFundo
		{
			get
			{
				return _strFundo;
			}
			set
			{
				_strFundo = value;
			}
		}
		
		/// <summary>
		/// pStrData
		/// </summary>
		public string pStrData
		{
			get
			{
				return _strData;
			}
			set
			{
				_strData = value;
			}
		}
		
		/// <summary>
		/// pStrValor
		/// </summary>
		public string pStrValor
		{
			get
			{
				return _strValor;
			}
			set
			{
				_strValor = value;
			}
		}

        /// <summary>
        /// pUnidadesParticipacao
        /// </summary>
        public string pUnidadesParticipacao
        {
            get
            {
                return _strUnidadesParticipacao;
            }
            set
            {
                _strUnidadesParticipacao = value;
            }
        }

        /// <summary>
        /// pUsarCodigoFundoISP
        /// </summary>
        public Boolean pUsarCodigoFundoISP
		{
			get
			{
				return _blnUsarCodigoFundoISP;
			}
			set
			{
				_blnUsarCodigoFundoISP = value;
			}
		}
		
		#endregion

	}
}
