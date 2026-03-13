# ─── Cores ────────────────────────────────────────────────────────────────────
RESET=$'\e[0m'
NEGRITO=$'\e[1m'
DIM=$'\e[2m'

PRETO=$'\e[30m'
VERMELHO=$'\e[31m'
VERDE=$'\e[32m'
AMARELO=$'\e[33m'
AZUL=$'\e[34m'
MAGENTA=$'\e[35m'
CIANO=$'\e[36m'
BRANCO=$'\e[37m'

BG_AZUL=$'\e[44m'
BG_CIANO=$'\e[46m'
BG_PRETO=$'\e[40m'

CINZA=$'\e[90m'
VERDE_CLARO=$'\e[92m'
AMARELO_CLARO=$'\e[93m'
AZUL_CLARO=$'\e[94m'
MAGENTA_CLARO=$'\e[95m'
CIANO_CLARO=$'\e[96m'

# ─── Helpers visuais ──────────────────────────────────────────────────────────
sep()    { echo "  ${CINZA}────────────────────────────────────────────────${RESET}"; }
linha()  { echo "  ${CINZA}════════════════════════════════════════════════${RESET}"; }

titulo() { echo; echo "  ${NEGRITO}${CIANO_CLARO}$1${RESET}"; sep; }

ok()     { echo "  ${VERDE_CLARO}✔  ${BRANCO}$1${RESET}"; }
erro()   { echo "  ${VERMELHO}✖  ${BRANCO}$1${RESET}"; }
info()   { echo "  ${AMARELO_CLARO}➜  ${BRANCO}$1${RESET}"; }
aviso()  { echo "  ${AMARELO}⚠   ${BRANCO}$1${RESET}"; }
item()   { echo "  ${CIANO}•  ${BRANCO}$1${RESET}"; }

entrada(){
  printf "  ${CIANO}▶  ${AMARELO_CLARO}%s${RESET} " "$1"
}

pausar() {
  echo
  printf "  ${CINZA}Pressione ENTER para voltar...${RESET}"
  read
}

passo(){
  local num="$1"
  local total="$2"
  local desc="$3"
  echo
  echo "  ${CINZA}[${AMARELO_CLARO}${num}${CINZA}/${AMARELO_CLARO}${total}${CINZA}]${RESET}  ${NEGRITO}${BRANCO}${desc}${RESET}"
  sep
}

ja_instalado(){
  dpkg -l "$1" 2>/dev/null | grep -q "^ii"
}

verificar_internet(){
  ping -c 1 -W 3 8.8.8.8 &>/dev/null
}

verificar_espaco(){
  local livre_mb
  livre_mb=$(df / | awk 'NR==2 {printf "%d", $4/1024}')
  [[ $livre_mb -ge 500 ]]
}

cabecalho(){
  local titulo="$1"
  local subtitulo="$2"
  clear
  echo
  echo "  ${NEGRITO}${BG_PRETO}${CIANO_CLARO}                                                    ${RESET}"
  echo "  ${NEGRITO}${BG_PRETO}${CIANO_CLARO}   $titulo${RESET}"
  if [[ -n "$subtitulo" ]]; then
    echo "  ${NEGRITO}${BG_PRETO}${CINZA}   $subtitulo${RESET}"
  fi
  echo "  ${NEGRITO}${BG_PRETO}${CIANO_CLARO}                                                    ${RESET}"
  echo
}

opcao_menu(){
  local num="$1"
  local desc="$2"
  printf "  ${CIANO}[${AMARELO_CLARO}%2s${CIANO}]${RESET}  %s\n" "$num" "$desc"
}

