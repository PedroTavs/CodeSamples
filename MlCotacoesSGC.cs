using System;
using System.Globalization;
using FileHelpers;
using i2S.PEF.Common.Utilities;

namespace i2S.PEF.ML.Movimentos.Cotacoes
{
	[DelimitedRecord(";")]
	public sealed class MlCotacoesSGC
	{
		[FieldOrder(1)]
		public string NomeFundoString;

		[FieldOrder(2)]
		public String ValorCotacaoString;

		[FieldOrder(3)]
		// Atributo FieldConverter não suporta properties
		public String DataCotacaoString;

        [FieldOrder(4)]
        public String ValorUnidadesParticipacaoString;

        public String NomeFundo
		{
			get
			{
				return NomeFundoString.replace("\"", "");
			}
		}

		public Decimal ValorCotacao
		{
			get
			{
				return ValorCotacaoString.replace("\"", "").replace(".", CultureInfo.CurrentCulture.NumberFormat.NumberDecimalSeparator).getDecimal();
			}
		}

		public DateTime DataCotacao
		{
			get
			{
				return ClDates.getDateTime(DataCotacaoString.replace("\"", ""), "dd-MM-yyyy");
			}
		}

        public double UnidadesParticipacao
        {
            get
            {
                return ValorUnidadesParticipacaoString.replace("\"", "").replace(".", CultureInfo.CurrentCulture.NumberFormat.NumberDecimalSeparator).getDouble();
            }
        }
    }
}
