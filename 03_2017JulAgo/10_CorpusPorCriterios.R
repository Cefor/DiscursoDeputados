# pacotes
if(!require(stringr)) { install.packages('stringr') }
if(!require(stringi)) { install.packages('stringi') }

source("..\\02_2017MaiJun\\05_EncodeDecode.R")
source("..\\02_2017MaiJun\\07_CorporaRetiraQuadrosFiguras.R")

corpus_por_criterios <- function(discursos, ini, fim, partido, codigoFase = NULL){
  print(sprintf("Partido: %s (%d - %d)", partido, ini, fim))
  
  # pasta com os arquivos "discurso_AAAA_dit.rds"
  pastaorig <- "..\\CorporaRDS\\"
  
  # altera nome da primeira coluna do data.frame discursos
  names(discursos)[1] <- "seq"

  # se o vetor de c�digo das fases das sess�es for nulo, 
  # carrega com todos os c�digos da base: "AB" "BC" "CG" "EN" "GE" "HO" "OD" "PE"
  if(is.null(codigoFase)){
    codigoFase <- levels(as.factor(discursos$codigoFase))
  }

  ### Verifica frequ�ncia de [sess�es](http://www2.camara.leg.br/comunicacao/assessoria-de-imprensa/sessoes-do-plenario) por tipo e restringe �s sess�es relevantes
  # frequ�ncia por tipo de sessao
  tipo_sessao <- table(discursos$tipoSessao)
  # filtra sess�es relevantes
  tipo_sessao <- as.character(levels(as.factor(discursos$tipoSessao)))
  tipo_sessao <- tipo_sessao[tipo_sessao %in%
                              c("Comiss�o Geral", "Comiss�o Representativa",
                                "Deliberativa Extraordin�ria - CD","Deliberativa Ordin�ria - CD",
                                "Extraordin�ria - CD", "Extraordin�ria - CN",
                                "N�o Deliberativa de Debates - CD", "Ordin�ria - CD",
                                "Ordin�ria - CN", "Preparat�ria", "Reforma Previdenci�ria")
                            ]
  discursos <- discursos[discursos$tipoSessao %in% tipo_sessao, ]
  print('Tipos de sess�o')
  print(tipo_sessao)
  
  ### Aplica crit�rios iniciais de filtragem ao data.frame discursos
  pastadest <- "..\\CorpusRDS\\"
  arquivo <- paste0(pastadest, "corpus_", partido, "_", ini, "_", fim, ".rds")
  discursos <- discursos[  str_sub(discursos$dataSessao,7,10) >= ini 
                           & str_sub(discursos$dataSessao,7,10) <= fim 
                           & discursos$partidoOrador == partido
                           & discursos$codigoFase %in% codigoFase
                           , 
                           ]
  if(nrow(discursos) == 0){
    print(paste('N�o foi encontrado discurso para as condi��es informadas: ', ini, ', ', fim, ', ', partido, ', ', codigoFase ))
    return(FALSE)
  }
  print(paste('Dimens�es do arquivo de discurso:', stri_c_list(list(dim(discursos)), sep=" ")))
  
  
  ### Constroi vetor com os discursos
  pt1 <- proc.time()
  
  ano <- "0000"
  n <- nrow(discursos)
  vdisc <- vector("character", n)
  
  for(i in 1:n){
    # a cada mudan�a de ano, abre o respectivo "discurso_AAAA_dit.rds"
    if(ano != str_sub(discursos$dataSessao[i], 7, 10)){
      ano <- str_sub(discursos$dataSessao[i], 7, 10)
      arq <- paste0(pastaorig, "discurso_", ano,"_dit.rds")
      discurso_it <- readRDS(arq)
    }
    
    # monta o id com base no ano e no sequencial do discurso
    id <- paste0('00000', discursos$seq[i])
    id <- str_sub(id,str_length(id)-4,str_length(id))
    id <- paste0(ano,id)
    
    # retira discursos 'sujos' com excesso de caracteres de controle
    if( (ano == 2012) & (discursos$seq[i] %in% 6862:6879) ){
      vdisc[i] <- ""
      next
    }
    
    if(!is.na(discurso_it$Discurso[i]) & (discurso_it$Discurso[i] != "")){
      discurso <- decode_rtf(discurso_it$Discurso[i])
      
      # retira figura, tabela ou quadro
      discurso <- retira_fig(discurso, ano)
      
      # retira a apresenta��o do discurso: "SR, PRESIDENTE ..."
      ret_apre <- str_sub(discurso, str_locate(discurso, "\\)")[1]+1, str_length(discurso))
      if(!is.na(ret_apre))
        discurso <- ret_apre
      
      # adiciona ao vetor de discursos
      vdisc[i] <- discurso
    }
  }
  rm(discurso_it)
  
  vdisc <- vdisc[vdisc != ""]
  
  saveRDS(vdisc, arquivo)
  
  pt2 <- proc.time()
  
  print(paste('Tempo de processamento:', stri_c_list(list((pt2 - pt1)[3]), sep=" ")))
  
  return(TRUE)
}

# remove todas as vari�veis, menos os par�metros ini, fim e partido
# rm(list = ls(all = TRUE)[!(ls(all = TRUE) %in% c("ini", "fim", "partido"))])

