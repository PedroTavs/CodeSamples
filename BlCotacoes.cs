using System;
using System.Collections.Generic;
using System.Data;
using System.Text;

using FileHelpers;

// I2S
using i2S.PEF.ML.BusinessConfigurations.Fundos;
using i2S.PEF.BL.Framework.Security;
using i2S.PEF.DL.Movimentos.Cotacoes;
using i2S.PEF.ML.Movimentos.Cotacoes;
using i2S.PEF.ML.Framework.Models;
using _nsMlApplicationConfigurationsClasses = i2S.PEF.ML.ApplicationConfigurations.Classes;
using _nsMlMovimentosCotacoesClasses = i2S.PEF.ML.Movimentos.Cotacoes.Classes;
using i2S.PEF.BL.BusinessConfigurations.Fundos;
using i2S.PEF.ML.Movimentos.Classes;
using i2S.PEF.Common.Utilities;
using i2S.PEF.Common.Utilities.Logs;
using i2S.PEF.Common.Utilities.Office.Excel;
using i2S.PEF.BL.BusinessCalculations.Mathematical;
using System.Linq;

namespace i2S.PEF.BL.Movimentos.Cotacoes
{
    /// <summary>
    /// Classe			: BlCotacoes.cs
    /// Tabela			: Cotacoes
    /// Autor			: Rodrigo Paiva
    /// Data de geração : 28-02-2014
    /// </summary>
    public class BlCotacoes
    {
        #region ----- Delegates -----

        // Evento delegate para notificar que foi sincronizado um registo (para actualizar UI)
        public delegate void EventoDelegateProgresso(Int32 prmIndexRegisto, String Texto, Int32 prmValorMaximo);

        #endregion

        #region ----- Variáveis de instância -----

        // Objecto DlCotacoes
        private DlCotacoes _objDlCotacoes;

        // Objecto BlWrkCotacoesImportar
        private BlWrkCotacoesImportar _objBlWrkCotacoesImportar;

        // Objecto BlFundos
        private BlFundos _objBlFundos;

        // Objecto BlMath
        private BlMath _objBlMath;

        // Lista de Cotações
        private List<MlWrkCotacoesImportar> _lstMlWrkCotacoesImportar;

        // Sheet do excel a ser usada para importação
        private String _strSheetExcel = String.Empty;

        private Dictionary<String, Int16> _dctFundoFundoISP = new Dictionary<String, Int16>();

        #endregion

        #region ----- Propriedades ------

        #region ----- pObjDlCotacoes -----

        /// <summary>
        /// Objecto DlCotacoes
        /// </summary>
        private DlCotacoes pObjDlCotacoes
        {
            get
            {
                if (_objDlCotacoes == null)
                {
                    _objDlCotacoes = new DlCotacoes();
                }
                return _objDlCotacoes;
            }
        }

        #endregion

        #region ----- pObjBlFundos -----

        /// <summary>
        /// Objecto BlFundos
        /// </summary>
        private BlFundos pObjBlFundos
        {
            get
            {
                if (_objBlFundos == null)
                {
                    _objBlFundos = new BlFundos();
                }
                return _objBlFundos;
            }
        }

        #endregion

        #region ----- pObjBlMath -----

        /// <summary>
        /// Objecto BlMath
        /// </summary>
        private BlMath pObjBlMath
        {
            get
            {
                if (_objBlMath == null)
                {
                    _objBlMath = new BlMath();
                }
                return _objBlMath;
            }
        }

        #endregion

        #region ----- pObjBlWrkCotacoesImportar -----

        /// <summary>
        /// Objecto BlWrkCotacoesImportar
        /// </summary>
        private BlWrkCotacoesImportar pObjBlWrkCotacoesImportar
        {
            get
            {
                if (_objBlWrkCotacoesImportar == null)
                {
                    _objBlWrkCotacoesImportar = new BlWrkCotacoesImportar();
                }
                return _objBlWrkCotacoesImportar;
            }
        }

        #endregion

        #region ----- pLstMlWrkCotacoesImportar -----

        /// <summary>
        /// pLstMlWrkCotacoesImportar
        /// </summary>
        private List<MlWrkCotacoesImportar> pLstMlWrkCotacoesImportar
        {
            get
            {
                if (_lstMlWrkCotacoesImportar == null)
                {
                    _lstMlWrkCotacoesImportar = new List<MlWrkCotacoesImportar>();
                }
                return _lstMlWrkCotacoesImportar;
            }
            set
            {
                _lstMlWrkCotacoesImportar = value;
            }
        }

        #endregion

        #endregion

        #region ----- Construtor -----

        /// <summary>
        /// Construtor
        /// </summary>
        public BlCotacoes()
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
            // Obter registo
            return pObjDlCotacoes.select(prmIdFundo,
                                            prmDataCotacao,
                                            out prmMlCotacoes);
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
            // Inserir registo
            return pObjDlCotacoes.insert(prmMlCotacoes, prmUserJob);
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
            return pObjDlCotacoes.update(prmMlCotacoes);
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
            // Eliminar registo
            return pObjDlCotacoes.delete(prmMlCotacoes);
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
            return pObjDlCotacoes.corrigirUnidadesParticipacao();
        }

        #endregion

        #region ----- Inicia Processo importação ficheiro -----
        /// <summary>
        /// Inicia processo de importação do ficheiro
        /// </summary>
        /// <param name="prmCaminhoFicheiroCotacoes">Caminho do ficheiro de configuração</param>
        /// <param name="prmTipoFicheiro">Enumeração com o tipo de importação usada</param>
        /// <param name="prmMlWrkCotacoesImportarMapeamentoCampos">Model com as configurações de mapeamentos das colunas e se usa codigo ASF</param>
        /// <param name="prmUserJob">UserJob</param>
        /// <param name="prmEventoDelegateProgresso">EventoDelegateProgresso</param>
        /// <returns>Result model</returns>
        public MlResult iniciaLeituraFicheiro(String prmCaminhoFicheiroCotacoes,
                                                _nsMlMovimentosCotacoesClasses.ClEnumerations.ImportacaoCotacoesTiposFicheiro prmTipoFicheiro,
                                                MlWrkCotacoesImportarMapeamentoCampos prmMlWrkCotacoesImportarMapeamentoCampos,
                                                String prmUserJob,
                                                EventoDelegateProgresso prmEventoDelegateProgresso)
        {
            MlResult _objMlResult = new MlResult();

            // Elimina registos anteriores da tabela WRK
            _objMlResult = pObjBlWrkCotacoesImportar.apagaRegistosUtilizador(prmUserJob);

            // Se for para usar o codigo ASF vai carregar o dicionario com os códigos
            if ((_objMlResult.pSuccess) && (prmMlWrkCotacoesImportarMapeamentoCampos.pUsarCodigoFundoISP))
            {
                obtemCodigosFundosComCodigosISP();
            }

            if (_objMlResult.pSuccess)
            {
                // executa a importação pelo tipo de ficheiro
                switch (prmTipoFicheiro)
                {
                    case _nsMlMovimentosCotacoesClasses.ClEnumerations.ImportacaoCotacoesTiposFicheiro.Excel:
                        {
                            // Importa ficheiro normal (Excel)
                            _objMlResult = importarCotacoesExcelParaLista(prmCaminhoFicheiroCotacoes,
                                                                            prmMlWrkCotacoesImportarMapeamentoCampos,
                                                                            prmUserJob,
                                                                            prmEventoDelegateProgresso);

                            break;
                        }

                    case _nsMlMovimentosCotacoesClasses.ClEnumerations.ImportacaoCotacoesTiposFicheiro.SGC:
                        {
                            // Processa ficheiro SGC
                            _objMlResult = importarCotacoesSGCParaLista(prmCaminhoFicheiroCotacoes,
                                                                        prmMlWrkCotacoesImportarMapeamentoCampos,
                                                                        prmUserJob);

                            break;
                        }

                    default:
                        {
                            _objMlResult.pSuccess = false;
                            _objMlResult.addError(ClConstants.ClMessagesCotacoes.NaoFoiPossivelDetetarTipoFicheiro);

                            break;
                        }
                }
            }


            // Se existirem cotações para enviar para a tabela work
            if (pLstMlWrkCotacoesImportar.Count > 0)
            {
                // Importa cotações para a tabela WRK
                guardaCotacoesTemporarias(prmEventoDelegateProgresso);

                // Informa o utilizador que está a ser feita a validação das cotações
                prmEventoDelegateProgresso?.Invoke(0,
                                            "A validar as cotações...",
                                      0);

                // Valida e calcula as cotações importadas
                pObjBlWrkCotacoesImportar.validaCalculaCotacoes(prmUserJob);
            }

            return _objMlResult;
        }

        #endregion

        #region ----- Importação Normal (Excel)-----

        #region ----- Obter Colunas Excel -----

        /// <summary>
        /// Obter Colunas do excel
        /// </summary>
        /// <param name="prmCaminhoFicheiroCotacoes">Excel File path</param>
        /// <param name="prmWorksheetColumns">List of first Worksheet columns</param>
        /// <returns>Result</returns>
        public MlResult obterColunasExcel(String prmCaminhoFicheiroCotacoes,
                                            out List<MlChave<String>> prmWorksheetColumns)
        {
            MlResult _objMlResult = new MlResult();
            List<String> _lstWorksheetNames;
            List<String> _lstWorksheetColumns;
            String _strErros;

            // Initialize output parameters
            prmWorksheetColumns = new List<MlChave<String>>();

            // Obter o nome da primeira Sheet do excel
            if (ClExcel.getWorksheetNames(prmCaminhoFicheiroCotacoes,
                                            out _lstWorksheetNames,
                                            out _strErros))
            {
                // Check if has Worksheets
                if (_lstWorksheetNames.Count > 0)
                {
                    // Get name of first Sheet
                    _strSheetExcel = _lstWorksheetNames[0];

                    // Get Columns list
                    if (ClExcel.getWorksheetColumns(prmCaminhoFicheiroCotacoes,
                                                    _strSheetExcel,
                                                    out _lstWorksheetColumns,
                                                    out _strErros))
                    {
                        // List of Columns
                        prmWorksheetColumns = _lstWorksheetColumns.ConvertAll<MlChave<String>>(delegate (String _strColuna)
                                                                                               {
                                                                                                   return new MlChave<String>(_strColuna);
                                                                                               });
                    }
                    else
                    {
                        // Error
                        _objMlResult.addError(_strErros);
                    }
                }
                else
                {
                    // Error
                    _objMlResult.addError(ClConstants.ClMessagesCotacoes.ExcelFileWithoutWorksheets);
                }
            }
            else
            {
                // Error
                _objMlResult.addError(_strErros);
            }

            return _objMlResult;
        }

        #endregion

        #region ----- Importa Cotações do Excel -----

        /// <summary>
        /// Importar dados do Excel
        /// </summary>
        /// <param name="prmCaminhoFicheiroCotacoes">Caminho do ficheiro</param>
        /// <param name="prmMlWrkCotacoesImportarMapeamentoCampos">Mapeamentos</param>
        /// <param name="prmUserJob">UserJob</param>
        /// <param name="prmEventoDelegateProgresso">EventoDelegateProgresso</param>
        /// <returns>Result model</returns>
        private MlResult importarCotacoesExcelParaLista(String prmCaminhoFicheiroCotacoes,
                                                        MlWrkCotacoesImportarMapeamentoCampos prmMlWrkCotacoesImportarMapeamentoCampos,
                                                        String prmUserJob,
                                                        EventoDelegateProgresso prmEventoDelegateProgresso)
        {
            MlResult _objMlResult = new MlResult();
            DataTable _dtCotacoesImportadas;

            // Identificação do Fundo
            Int16 _intFundo = 0;

            // String Erros de dados por Linha
            String _strErrosLinha = string.Empty;

            // Limpa a lista existente de cotações
            limpaListaCotacoes();

            // Obtem datatable com as cotações
            _objMlResult = pObjDlCotacoes.getImportExcelFileData(prmCaminhoFicheiroCotacoes,
                                                                    prmMlWrkCotacoesImportarMapeamentoCampos,
                                                                    out _dtCotacoesImportadas);

            // Check success
            if (_objMlResult.pSuccess)
            {
                // Index do registo da linha
                Int32 _intIndexLinha = 1;

                if (ClDataTables.verificarDataTableTemDados(_dtCotacoesImportadas))
                {
                    // Actualiza informação utilizador

                    if (prmEventoDelegateProgresso != null)
                    {
                        prmEventoDelegateProgresso(0, "A analisar as cotações...", 0);
                    }
                    foreach (DataRow drAux in _dtCotacoesImportadas.Rows)
                    {
                        // Obtém codigo do fundo para ser tratado
                        string _srtFundoTemporario = drAux.getFieldValue<string>(MlCotacoesExcel.DbFields.Fundo);

                        // Data Cotação
                        DateTime _datDataCotacao = drAux.getFieldValue<DateTime>(MlCotacoesExcel.DbFields.Data);

                        // Valor Cotação
                        decimal _decValorCotacao = drAux.getFieldValue<decimal>(MlCotacoesExcel.DbFields.Valor);

                        // Número de unidades de participação
                        double _decUnidadesParticipacao = drAux.getFieldValue<double>(MlCotacoesExcel.DbFields.Numero_Ups);

                        // Obtém o codigo do fundo tratado
                        _intFundo = obterCodigoFundo(prmMlWrkCotacoesImportarMapeamentoCampos.pUsarCodigoFundoISP, _srtFundoTemporario);

                        // Valida e converte Data e valor da cotação
                        _objMlResult = validaDadosLinha(_intFundo,
                                                            prmMlWrkCotacoesImportarMapeamentoCampos.pUsarCodigoFundoISP,
                                                            _datDataCotacao,
                                                            _decValorCotacao,
                                                            _decUnidadesParticipacao);

                        // Adiciona a lista de cotações
                        constroiListaMlWrkCotacoesImportar(prmUserJob,
                                                                _intFundo,
                                                                _datDataCotacao,
                                                                _decValorCotacao,
                                                                _decUnidadesParticipacao,
                                                                _objMlResult.getResultDetailAsText());
                        // Incrementa index da leitura
                        _intIndexLinha++;
                    }
                }
                else
                {
                    _objMlResult.pSuccess = false;
                    _objMlResult.addError(ClConstants.ClMessagesCotacoes.NaoFoiPossivelImportarDadosFicheiro);
                }
            }

            return _objMlResult;
        }


        #endregion

        #endregion

        #region ----- Importação SGC -----
        /// <summary>
        /// Importação do ficheiro SGC para a lista de cotações WRK
        /// </summary>
        /// <param name="prmCaminhoFicheiroCotacoes">Caminho do ficheiro</param>
        /// <param name="prmUserJob">UserJob</param>
        /// <returns>Result model</returns>
        private MlResult importarCotacoesSGCParaLista(String prmCaminhoFicheiroCotacoes,
                                                        MlWrkCotacoesImportarMapeamentoCampos prmMlWrkCotacoesImportarMapeamentoCampos,
                                                        String prmUserJob)
        {
            MlResult _objMlResult = new MlResult();

            // Limpa Lista de cotações
            limpaListaCotacoes();

            try
            {
                foreach (MlCotacoesSGC _objCotacao in getCotacoes(prmCaminhoFicheiroCotacoes))
                {
                    // Obtém o codigo do fundo tratado
                    Int16 _iCodigoFundo = obterCodigoFundo(prmMlWrkCotacoesImportarMapeamentoCampos.pUsarCodigoFundoISP, _objCotacao.NomeFundo);

                    // Valida e converte os valores a serem importados
                    _objMlResult = validaDadosLinha(_iCodigoFundo,
                                                        prmMlWrkCotacoesImportarMapeamentoCampos.pUsarCodigoFundoISP,
                                                        _objCotacao.DataCotacao,
                                                        _objCotacao.ValorCotacao,
                                                        _objCotacao.UnidadesParticipacao);

                    string _strListaErros = _objMlResult.getResultDetailAsText();
                    if (_iCodigoFundo == 0 && prmMlWrkCotacoesImportarMapeamentoCampos.pUsarCodigoFundoISP) // Alteração para poder apresentar o nome ASF sem alterar o model e SPs
                        _strListaErros = _objCotacao.NomeFundo + " " + _strListaErros;

                    // Adiciona a lista de cotações
                    constroiListaMlWrkCotacoesImportar(prmUserJob,
                                                        _iCodigoFundo,
                                                        _objCotacao.DataCotacao,
                                                        _objCotacao.ValorCotacao,
                                                        _objCotacao.UnidadesParticipacao,
                                                        _strListaErros);
                }
            }
            catch (Exception ex)
            {
                GetLogHelp.Erro(false, ex);
                _objMlResult.addError(ClConstants.ClMessagesCotacoes.NaoFoiPossivelImportarDadosFicheiro);
            }

            return _objMlResult;
        }

        private IEnumerable<MlCotacoesSGC> getCotacoes(string prmFileName)
        {
            var engine = new FileHelperAsyncEngine<MlCotacoesSGC>();

            // Read
            using (engine.BeginReadFile(prmFileName))
            {
                // The engine is IEnumerable
                foreach (MlCotacoesSGC cot in engine)
                {
                    yield return cot;
                }
            }
        }

        #endregion

        #region ----- Lista Cotações-----
        /// <summary>
        /// Limpa Lista cotações
        /// </summary>
        private void limpaListaCotacoes()
        {
            // Limpa a lista cotações
            pLstMlWrkCotacoesImportar.Clear();
        }

        /// <summary>
        /// Controi lista de cotações WRK
        /// </summary>
        /// <param name="prmUserJob"></param>
        /// <param name="prmFundo"></param>
        /// <param name="prmDataCotacao"></param>
        /// <param name="prmValorCotacao"></param>
        /// <param name="prmUnidadesParticipacao"></param>
        private void constroiListaMlWrkCotacoesImportar(String prmUserJob,
                                                            Int16 prmFundo,
                                                            DateTime prmDataCotacao,
                                                            Decimal prmValorCotacao,
                                                            double prmUnidadesParticipacao,
                                                            String prmDadosComErros)
        {
            MlWrkCotacoesImportar _objMlWrkCotacoesImportar = new MlWrkCotacoesImportar();

            _objMlWrkCotacoesImportar.pUserJob = prmUserJob;
            _objMlWrkCotacoesImportar.pJobDate = DateTime.Now;
            _objMlWrkCotacoesImportar.pFundo = prmFundo;
            _objMlWrkCotacoesImportar.pDataCotacao = prmDataCotacao;
            _objMlWrkCotacoesImportar.pValorCotacao = prmValorCotacao;
            _objMlWrkCotacoesImportar.pNumeroUP = prmUnidadesParticipacao;
            _objMlWrkCotacoesImportar.p_DadosComErros = prmDadosComErros;

            pLstMlWrkCotacoesImportar.Add(_objMlWrkCotacoesImportar);
        }
        #endregion

        #region ----- Envia Cotações WRK para a base de dados -----

        /// <summary>
        /// Envia as cotações a importar para a tabela WrkCotacoesImportar
        /// </summary>
        /// <returns>Result model</returns>
        private MlResult guardaCotacoesTemporarias(EventoDelegateProgresso prmEventoDelegateProgresso)
        {
            MlResult _objMlResult = new MlResult();

            // Numero máximo de registos a importar de uma vez
            Int32 _intNumeroRegistosImportar = 1000;

            // Guarda o numero total de cotações a serem guardadas
            Int32 _intRegistosParaImportar = pLstMlWrkCotacoesImportar.Count;

            // Guarda o nº de cotações já guardadas
            Int32 _intRegistosJaGuardados = 0;

            // Lista de registos que vai enviar para a base de dados
            List<MlWrkCotacoesImportar> _lstRegistoParaGuardar = new List<MlWrkCotacoesImportar>();

            // Percorre lista de cotações para a base de dados 
            while (pLstMlWrkCotacoesImportar.Count != 0)
            {
                // Se o número de registos pendentes de gravação for inferior ao numero maximo de gravação
                // São importados todos os restantes
                if (pLstMlWrkCotacoesImportar.Count <= _intNumeroRegistosImportar)
                {
                    ClCollections.copiarElementos<MlWrkCotacoesImportar>(pLstMlWrkCotacoesImportar, ref _lstRegistoParaGuardar);
                    pLstMlWrkCotacoesImportar.Clear();
                }
                else
                {
                    // Copia o número máximo de registos para importação
                    _lstRegistoParaGuardar = pLstMlWrkCotacoesImportar.GetRange(0, _intNumeroRegistosImportar);
                    pLstMlWrkCotacoesImportar.RemoveRange(0, _intNumeroRegistosImportar);
                }

                // Manda para a base de dados
                _objMlResult = pObjBlWrkCotacoesImportar.insert(_lstRegistoParaGuardar);

                // Actualiza informação utilizador
                if (prmEventoDelegateProgresso != null)
                {
                    // calcula registos atuais
                    _intRegistosJaGuardados = _intRegistosJaGuardados + _lstRegistoParaGuardar.Count;

                    prmEventoDelegateProgresso(_intRegistosJaGuardados,
                                                "Cotações importadas {0} de {1}.",
                                                _intRegistosParaImportar);
                }

                // Limpa a lista de cotações para gravação
                _lstRegistoParaGuardar.Clear();
            }

            return _objMlResult;
        }

        #endregion

        #region ----- Obtem Códigos Fundos Com Códigos ASF -----

        /// <summary>
        /// Obtem Códigos Fundos Com Códigos ASF
        /// </summary>
        /// <returns>Result model</returns>
        private MlResult obtemCodigosFundosComCodigosISP()
        {
            MlResult _objMlResult = new MlResult();

            // Verificar se o dicionário ainda não tem elementos
            if (_dctFundoFundoISP.Count == 0)
            {
                // Obtém os fundos com os códigos ASF
                DataTable _dtFundos;
                _objMlResult = pObjBlFundos.getListIdFundoCodigoEntidadeReguladora(out _dtFundos);

                // Success?
                if ((_objMlResult.pSuccess) && (_dtFundos.verificarDataTableTemDados()))
                {
                    foreach (DataRow _drLinha in _dtFundos.Rows)
                    {
                        String _strCodigoEntidadeReguladora = _drLinha.getFieldValue<String>(MlFundos.DbFields.CodigoEntidadeReguladora);
                        Int16 _intIdFundo = _drLinha.getFieldValue<Int16>(MlFundos.DbFields.IdFundo);

                        if (!_dctFundoFundoISP.ContainsKey(_strCodigoEntidadeReguladora))
                        {
                            _dctFundoFundoISP.Add(_strCodigoEntidadeReguladora, _intIdFundo);
                        }
                    }
                }
            }

            return _objMlResult;
        }

        #endregion

        #region ----- Obtem Codigo do Fundo -----

        /// <summary>
        /// Obtém Codigo do Fundo
        /// </summary>
        /// <param name="prmUsaCodigoISP">Usa codigo ASF ? | True - False</param>
        /// <param name="prmCodigoFundo">Codigo do fundo, seja Interno ou ASF</param>
        /// <returns>Codigo do Fundo tratado</returns>
        private Int16 obterCodigoFundo(Boolean prmUsaCodigoISP, String prmCodigoFundo)
        {
            // Se usar o código ASF vai obter o codigo do fundo pelo dicionário
            // Se não usa o código ASF apenas converte o valor e devolve
            if (prmUsaCodigoISP)
            {
                // Se existir correspondencia no dicionario devolve o valor
                // caso contrario retorna 0
                return (_dctFundoFundoISP.ContainsKey(prmCodigoFundo) ? _dctFundoFundoISP[prmCodigoFundo] : ClObjectValues.getInt16(0));
            }
            else
            {
                return ClObjectValues.getInt16(prmCodigoFundo);
            }
        }

        #endregion

        #region ----- Valida Registos -----

        /// <summary>
        /// Valida os valores da linha
        /// </summary>
        /// <param name="prmFundo">Código do fundo</param>
        /// <param name="prmUsaCodigoISP">Flag que indica se é usado o código ASF</param>
        /// <param name="prmDataCotacao">Data da cotação</param>
        /// <param name="prmValorCotacao">Valor da cotação</param>
        /// <param name="prmUnidadesParticipacao">Número de unidades de participação</param>
        /// <returns>Result model</returns>
        private MlResult validaDadosLinha(Int16 prmFundo,
                                            Boolean prmUsaCodigoISP,
                                            DateTime prmDataCotacao,
                                            Decimal prmValorCotacao,
                                            double prmUnidadesParticipacao)
        {
            MlResult _mlrMlResult = new MlResult();

            // Se não for para usar o código ASF verifica se o fundo tem um valor numerico
            if ((!prmUsaCodigoISP) && (prmFundo <= 0))
            {
                _mlrMlResult.pSuccess = false;
                _mlrMlResult.addError(ClConstants.ClMessagesCotacoes.CodigoFundoFormatoErrado);
            }

            // Validar Data da Cotação
            if ((prmDataCotacao == new DateTime()) ||
                (prmDataCotacao <= ClDatabaseValues.obterDataVaziaBaseDados()))
            {
                _mlrMlResult.pSuccess = false;
                _mlrMlResult.addError(ClConstants.ClMessagesCotacoes.ADataEstaFormatoErrado);
            }
            else if (prmDataCotacao > DateTime.Now)
            {
                _mlrMlResult.pSuccess = false;
                _mlrMlResult.addError(ClConstants.ClMessagesCotacoes.NaoPodemSerImportadasCotacoesComDataNoFuturo);
            }

            // Verifica Valor cotação
            if (prmValorCotacao == 0)
            {
                _mlrMlResult.pSuccess = false;
                _mlrMlResult.addError(ClConstants.ClMessagesCotacoes.ValorCotacaoFormatoErrado);
            }
            else if (!ClNumerics.validarDecimalNotTooLarge(prmValorCotacao, 7, 5)) // Alterar aqui o range
            {
                _mlrMlResult.pSuccess = false;
                _mlrMlResult.addError(ClConstants.ClMessagesCotacoes.OValorMaximoCotacaoE9999999);
            }

            // Verifica unidades de participação
            if (prmUnidadesParticipacao == 0)
            {
                _mlrMlResult.pSuccess = true;
            }
            else if (!ClNumerics.validarDoubleNotTooLarge(prmUnidadesParticipacao, 7, 5)) // Alterar aqui o range
            {
                _mlrMlResult.pSuccess = false;
                _mlrMlResult.addError(ClConstants.ClMessagesCotacoes.OValorMaximoCotacaoE9999999);
            }

            return _mlrMlResult;
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
            return pObjDlCotacoes.obterCotacoesPorProduto(prmIdProduto,
                                                            prmData,
                                                            out prmCotacoes);
        }

        #endregion

        #region ----- Obter Cotações por Fundo -----

        /// <summary>
        /// Obter Cotações por Fundo
        /// </summary>
        /// <param name="prmIdFundo">IdFundo</param>
        /// <param name="prmData">Data</param>
        /// <param name="prmCotacoes">DataTable registo</param>
        /// <returns>Result model</returns>
        public MlResult obterCotacoesPorFundo(Int16 prmIdFundo,
                                                DateTime prmData,
                                                out DataTable prmCotacoes)
        {
            return pObjDlCotacoes.obterCotacoesPorFundo(prmIdFundo,
                                                        prmData,
                                                        out prmCotacoes);
        }

        /// <summary>
        /// Obter Cotações por Fundo
        /// </summary>
        /// <param name="prmFundo">Fundo</param>
        /// <param name="prmData">Data</param>
        /// <param name="prmMlCotacoes">Model de Cotações</param>
        /// <returns>Result model</returns>
        public MlResult obterCotacoesPorFundo(Int16 prmFundo,
                                                DateTime prmData,
                                                out MlCotacoes prmMlCotacoes)
        {
            MlResult _objMlResult = new MlResult();
            DataTable _dtRecord;

            // Initialize output parameters
            prmMlCotacoes = null;

            // Get last Cotação of Fundo with date equal or less than parameter date
            _objMlResult = obterCotacoesPorFundo(prmFundo,
                                                    prmData,
                                                    out _dtRecord);

            // Success and has record?
            if ((_objMlResult.pSuccess) && (_dtRecord.verificarDataTableTemDados()))
            {
                // Get model
                prmMlCotacoes = MlCotacoes.dataRowToModel(_dtRecord.Rows[0]);
            }

            return _objMlResult;
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
            return pObjDlCotacoes.obterCotacoesPorData(prmData);
        }

        #endregion

        #region ----- Obter Valor Unitário do Fundo -----

        /// <summary>
        /// Obter Valor Unitário do Fundo
        /// </summary>
        /// <param name="prmFundo">Fundo</param>
        /// <param name="prmData">Data</param>
        /// <returns>Valor Unitário do Fundo</returns>
        public Decimal obterValorUnitarioFundo(Int16 prmFundo,
                                                DateTime prmData)
        {
            Decimal _decValorUnitarioFundo = 0;

            // Obter Cotações
            MlCotacoes _objMlCotacoes;

            select(prmFundo,
                      prmData,
                      out _objMlCotacoes);

            // Validar se o objecto não esta a nulo
            if (_objMlCotacoes != null)
            {
                // Obter o valor
                _decValorUnitarioFundo = _objMlCotacoes.Cotacao;
            }

            return _decValorUnitarioFundo;
        }


        #endregion

        #region ----- Verificar se existe cotação para o Fundo na Data -----

        /// <summary>
        /// Verificar se existe cotação para o Fundo na Data
        /// </summary>
        /// <param name="prmFundo">Fundo</param>
        /// <param name="prmDataProcessamento">Data de Processamento</param>
        /// <returns>Existe Cotação?</returns>
        public Boolean verificarSeExisteCotacaoFundoData(Int16 prmFundo,
                                                            DateTime prmDataProcessamento)
        {
            Boolean _blnExisteCotacao = false;

            // Obter Cotação
            MlCotacoes _objMlCotacoes;

            select(prmFundo,
                      prmDataProcessamento,
                      out _objMlCotacoes);

            // Verificar se tem cotação definida
            if (_objMlCotacoes != null
                && _objMlCotacoes.Cotacao > 0)
            {
                _blnExisteCotacao = true;
            }

            return _blnExisteCotacao;
        }

        #endregion

        #region ----- Validar se o Fundo tem Cotação no Início de um Ano -----

        /// <summary>
        /// Validar se um Fundo tem Cotação no início de um Ano
        /// </summary>
        /// <param name="prmFundo">Fundo</param>
        /// <param name="prmAno">Ano</param>
        /// <returns>Indicar se o Fundo tem otação no início de um Ano</returns>
        public Boolean validarFundoTemCotacaoInicioAno(Int16 prmFundo,
                                                        Int32 prmAno)
        {
            // Data 01-01 do Ano recebido por parâmetro
            return verificarSeExisteCotacaoFundoData(prmFundo,
                                                        ClDates.getDateTimeData(prmAno, 1, 1));
        }

        #endregion

        #region ----- Verificar se existe cotação para os Fundos na Data -----

        /// <summary>
        /// Verificar se existe cotação para os Fundos na Data
        /// </summary>
        /// <param name="prmFundos">Lista de Fundos</param>
        /// <param name="prmDataProcessamento">Data de Processamento</param>
        /// <returns>MlResultado</returns>
        public MlResult verificarSeExisteCotacaoFundosData(List<Int16> prmFundos,
                                                                DateTime prmDataProcessamento)
        {
            MlResult _objMlResult = new MlResult();
            Boolean _blnExisteCotacao = true;
            StringBuilder _stbErro = new StringBuilder();

            // Percorrer todos os Fundos
            foreach (Int16 _intFundo in prmFundos)
            {
                // Verificar se não obteve cotação
                if (!verificarSeExisteCotacaoFundoData(_intFundo,
                                                        prmDataProcessamento))
                {
                    _blnExisteCotacao = false;
                    // Verificar se já tem mensagens
                    _stbErro.AppendFormat(_stbErro.Length > 0 ? ", {0}" : "{0}", _intFundo);
                }
            }

            // Verificar se não tem cotações
            if (!_blnExisteCotacao)
            {
                _objMlResult.pSuccess = _blnExisteCotacao;
                _objMlResult.addWarningTitleFormat("Erro", "Os seguintes fundos não tem cotação definida: {0}", _stbErro);
            }

            return _objMlResult;
        }

        /// <summary>Verificar se todos os fundos recebidos por parâmetro estão na mesma situação relativamente à cotação (todos têm cotação ou nenhum tem)
        /// </summary>
        /// <param name="prmFundos">Lista de Fundos</param>
        /// <param name="prmDataProcessamento">Data de Processamento</param>
        /// <returns>MlResultado</returns>
        public MlResult verificarFundosMesmaSituacaoCotacao(List<Int16> prmFundos,
                                                                DateTime prmDataProcessamento)
        {
            MlResult _objMlResult = new MlResult();
            List<Boolean> ListaBoolsFundoTemCotacao = new List<Boolean>();           
            StringBuilder _stbErro = new StringBuilder();

            // Percorrer todos os Fundos
            foreach (Int16 _intFundo in prmFundos)
            {
                ListaBoolsFundoTemCotacao.Add(verificarSeExisteCotacaoFundoData(_intFundo, prmDataProcessamento));
            }

            if (ListaBoolsFundoTemCotacao.Distinct().Skip(1).Any()) {
                _objMlResult.pSuccess = false;
                _objMlResult.addWarningTitleFormat("Erro", "Existem fundos sem cotação definida", _stbErro);
            }

            return _objMlResult;
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
            return pObjDlCotacoes.obterTodasCotacoesDoFundo(prmPageNumber,
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
            return pObjDlCotacoes.obterTodasCotacoesDoProduto(prmPageNumber,
                                                                prmPageRows,
                                                                prmMlQueryFields,
                                                                out prmRecords);
        }

        #endregion

        #region ----- Update -----

        /// <summary>
        /// Update Cotacao
        /// </summary>
        /// <param name="prmBlPrincipal">BlPrincipal object</param>
        /// <param name="prmCotacao">Data row com a cotacao</param>
        public MlResult update(BlPrincipal prmBlPrincipal,
                                _nsMlApplicationConfigurationsClasses.ClEnumerations.DataInputTypes prmDataInputTypes,
                                DataRow prmCotacao)
        {
            MlResult _objMlResult;
            MlCotacoes _objMlCotacoes;

            // Get Cotacao
            _objMlResult = select(prmCotacao.getFieldValue<Int16>(MlCotacoes.DbFields.IdFundo),
                                                                    prmCotacao.getFieldValue<DateTime>(MlCotacoes.DbFields.DataCotacao),
                                                                    out _objMlCotacoes);

            if ((_objMlResult.pSuccess) && (_objMlCotacoes != null))
            {
                // Set new Quote
                _objMlCotacoes.Cotacao = ClDataTables.getFieldValue<Decimal>(prmCotacao, MlCotacoes.DbFields.Cotacao);
                _objMlCotacoes.NumeroUnidadesParticipacao = ClDataTables.getFieldValue<Decimal>(prmCotacao, MlCotacoes.DbFields.NumeroUnidadesParticipacao);
                // Username
                _objMlCotacoes.Username = prmBlPrincipal.pUsername;
                _objMlCotacoes.pvIdDataInputType = prmDataInputTypes;

                // Update
                _objMlResult = update(_objMlCotacoes);
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
                                                        out Decimal prmCotacao)
        {

            short _shDecimalPlaces = pObjBlFundos.getFundQuotationDecimalPlaces(prmIdFundo);

            if (_shDecimalPlaces == -1)
            {
                _shDecimalPlaces = (short)pObjBlMath.pDefaultQuotationDecimalPlaces;
            }

            return pObjDlCotacoes.obterCotacaoPorFundoDataExata(prmIdFundo,
                                                                prmData,
                                                                _shDecimalPlaces,
                                                                out prmCotacao);
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
            return pObjDlCotacoes.verificarSeCotacaoPodeSerAlterada(prmIdFundo,
                                                                    prmData,
                                                                    out prmPodeSerAlterado);
        }

        #endregion

        #region ----- Obter Fundos com Movimentos num Ano, mas sem Cotação no primeiro dia do Ano seguinte -----

        /// <summary>
        /// Obter Fundos com Movimentos num Ano, mas sem Cotação no primeiro dia do Ano seguinte
        /// </summary>
        /// <param name="prmAno">Ano</param>
        /// <param name="prmExcluirFundosReportesFiscais"></param>
        /// <param name="prmExcluirFundosReportesFiscais">Excluir fundos não considerados em reportes fiscais?</param>
        /// <param name="prmFundos">DataTable com Fundos</param>
        /// <returns>Result model</returns>
        public MlResult obterFundosComMovimentosAnoSemCotacaoPrimeiroDiaAnoSeguinte(Int32 prmAno,
                                                                                    Boolean prmExcluirFundosReportesFiscais,
                                                                                    out DataTable prmFundos)
        {
            return pObjDlCotacoes.obterFundosComMovimentosAnoSemCotacaoPrimeiroDiaAnoSeguinte(prmAno,
                                                                                                prmExcluirFundosReportesFiscais,
                                                                                                out prmFundos);
        }

        #endregion

        #region ----- Validar se todos os Fundos têm Cotação no primeiro dia do Ano posterior a uma Data -----

        /// <summary>
        /// Validar se todos os Fundos têm Cotação no primeiro dia do Ano posterior a uma Data
        /// </summary>
        /// <param name="prmAno">Ano</param>
        /// <param name="prmExcluirFundosReportesFiscais">Excluir fundos não considerados em reportes fiscais?</param>
        /// <returns>Result model</returns>
        public MlResult validarFundosTemCotacaoPrimeiroDiaAnoPosteriorData(Int32 prmAno,
                                                                            Boolean prmExcluirFundosReportesFiscais)
        {
            MlResult _objMlResult;
            DataTable _dtFundos;

            // Obter Fundos sem Cotação no primeiro dia do Ano posterior a uma Data
            _objMlResult = obterFundosComMovimentosAnoSemCotacaoPrimeiroDiaAnoSeguinte(prmAno,
                                                                                        prmExcluirFundosReportesFiscais,
                                                                                        out _dtFundos);

            // Sucesso?
            if (_objMlResult.pSuccess)
            {
                // Verificar se obteve registos
                if (ClDataTables.verificarDataTableTemDados(_dtFundos))
                {
                    // Erro
                    _objMlResult.addErrorFormat("Os seguintes Fundos não possuem Cotação a 1 de Janeiro de {0}:", (prmAno + 1));

                    // Percorrer os Fundos e inseri-los na mensagem de Erro
                    foreach (DataRow _drLinha in _dtFundos.Rows)
                    {
                        _objMlResult.addErrorFormat(" - {0} - {1}", _drLinha.getFieldValue<Int32>(MlFundos.DbFields.IdFundo),
                                                                    _drLinha.getFieldValue<String>(MlFundos.DbFields.DescricaoCompleta));
                    }
                }
            }

            return _objMlResult;
        }

        #endregion

    }
}
