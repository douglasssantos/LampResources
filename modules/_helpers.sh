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

# ─── Seleção interativa de itens ──────────────────────────────────────────────
# Uso: _selecionar "Prompt" item1 item2 ...
# Resultado fica em $_SELECIONADO
_selecionar(){
  local prompt="$1"
  shift
  local opcoes=("$@")
  local total=${#opcoes[@]}

  if [[ $total -eq 0 ]]; then
    erro "Nenhum item disponível para seleção."
    _SELECIONADO=""
    return 1
  fi

  echo
  local i
  for (( i=0; i<total; i++ )); do
    printf "  ${CIANO}[${AMARELO_CLARO}%2d${CIANO}]${RESET}  %s\n" "$((i+1))" "${opcoes[$i]}"
  done
  echo

  local escolha
  while true; do
    entrada "$prompt [1-$total]:"
    read escolha
    if [[ "$escolha" =~ ^[0-9]+$ ]] && (( escolha >= 1 && escolha <= total )); then
      _SELECIONADO="${opcoes[$((escolha-1))]}"
      return 0
    fi
    erro "Opção inválida. Digite um número entre 1 e $total."
  done
}

# ─── Seleção múltipla com toggle ─────────────────────────────────────────────
# Uso: _selecionar_multiplo "Prompt" "PERM1,PERM2" item1 item2 ...
#   2º argumento: CSV de itens pré-selecionados (pode ser vazio "")
# Resultado fica em $_SELECIONADOS (CSV) e $_SELECIONADOS_ARR (array)
_selecionar_multiplo(){
  local prompt="$1"
  local presel="$2"
  shift 2
  local opcoes=("$@")
  local total=${#opcoes[@]}
  local -a marcados=()

  # Inicializar marcados com base em presel
  local i
  for (( i=0; i<total; i++ )); do
    if echo "$presel" | grep -qiw "${opcoes[$i]}"; then
      marcados[$i]=1
    else
      marcados[$i]=0
    fi
  done

  _render_lista(){
    echo
    for (( i=0; i<total; i++ )); do
      if [[ "${marcados[$i]}" -eq 1 ]]; then
        printf "  ${VERDE_CLARO}[${AMARELO_CLARO}%2d${VERDE_CLARO}] ✔  ${BRANCO}%s${RESET}\n" "$((i+1))" "${opcoes[$i]}"
      else
        printf "  ${CINZA}[${AMARELO_CLARO}%2d${CINZA}] ○  ${DIM}%s${RESET}\n" "$((i+1))" "${opcoes[$i]}"
      fi
    done
    echo
    item "Digite o número para marcar/desmarcar  ${CINZA}|${RESET}  ${AMARELO_CLARO}0${RESET} para confirmar"
  }

  local escolha
  while true; do
    _render_lista
    entrada "$prompt:"
    read escolha
    if [[ "$escolha" == "0" ]]; then
      break
    elif [[ "$escolha" =~ ^[0-9]+$ ]] && (( escolha >= 1 && escolha <= total )); then
      local idx=$(( escolha - 1 ))
      [[ "${marcados[$idx]}" -eq 1 ]] && marcados[$idx]=0 || marcados[$idx]=1
    else
      erro "Opção inválida."
    fi
  done

  # Montar resultado
  _SELECIONADOS=""
  _SELECIONADOS_ARR=()
  for (( i=0; i<total; i++ )); do
    if [[ "${marcados[$i]}" -eq 1 ]]; then
      _SELECIONADOS_ARR+=("${opcoes[$i]}")
      if [[ -z "$_SELECIONADOS" ]]; then
        _SELECIONADOS="${opcoes[$i]}"
      else
        _SELECIONADOS="${_SELECIONADOS},${opcoes[$i]}"
      fi
    fi
  done
}

# ─── SSL Wildcard (Let's Encrypt / DNS-01) ────────────────────────────────────
# Normaliza entrada: "veskops.com *.veskops.com" ou "*.veskops.com" → veskops.com
_ssl_normalizar_dominio(){
  local bruto="$1"
  bruto="${bruto#http://}"
  bruto="${bruto#https://}"
  bruto="${bruto%%/*}"
  bruto=$(echo "$bruto" | awk '{print $1}')
  bruto="${bruto#\*.}"
  echo "$bruto"
}

_ssl_adicionar_alias_wildcard(){
  local dominio="$1"
  local apache_conf="/etc/apache2/sites-available/${dominio}.conf"
  local nginx_conf="/etc/nginx/sites-available/${dominio}.conf"

  if [[ -f "$apache_conf" ]] && ! grep -q "\*\.${dominio}" "$apache_conf"; then
    if grep -q "ServerAlias" "$apache_conf"; then
      sudo sed -i "s/ServerAlias \(.*\)/ServerAlias \1 *.${dominio}/" "$apache_conf"
    else
      sudo sed -i "/ServerName ${dominio}/a\       ServerAlias *.${dominio}" "$apache_conf"
    fi
  fi

  if [[ -f "$nginx_conf" ]] && ! grep -q "\*\.${dominio}" "$nginx_conf"; then
    sudo sed -i "s/server_name ${dominio} www.${dominio};/server_name ${dominio} www.${dominio} *.${dominio};/" "$nginx_conf"
    sudo sed -i "s/server_name ${dominio};/server_name ${dominio} *.${dominio};/" "$nginx_conf"
  fi
}

# Uso: _ssl_gerar_wildcard <dominio> [apache|nginx]
# Emite certificado para dominio + *.dominio via desafio DNS.
_ssl_gerar_wildcard(){
  local dominio="$1"
  local instalador="${2:-}"

  dominio=$(_ssl_normalizar_dominio "$dominio")
  if [[ -z "$dominio" ]]; then
    erro "Domínio inválido."
    return 1
  fi

  if ! command -v certbot &>/dev/null; then
    erro "Certbot não está instalado. Instale o stack primeiro."
    return 1
  fi

  linha
  aviso "Certificados wildcard exigem validação DNS (Let's Encrypt)."
  echo
  item "Será emitido para:  ${NEGRITO}${dominio}${RESET}  e  ${NEGRITO}*.${dominio}${RESET}"
  item "O Certbot vai pedir um registro TXT, por exemplo:"
  echo
  echo "    ${CIANO}_acme-challenge.${dominio}${RESET}    TXT    ${AMARELO_CLARO}<valor gerado>${RESET}"
  echo
  item "Crie o registro no DNS e aguarde a propagação antes de continuar."
  aviso "A renovação automática não funciona no modo manual — será preciso repetir o TXT."
  linha
  entrada "Pressione ENTER para iniciar o Certbot..."
  read

  info "Solicitando certificado wildcard..."
  if ! sudo certbot certonly \
      --manual \
      --preferred-challenges dns \
      --agree-tos \
      -m "$email" \
      --cert-name "$dominio" \
      -d "$dominio" \
      -d "*.${dominio}" \
      --expand \
      --manual-public-ip-logging-ok; then
    erro "Falha ao gerar o certificado wildcard."
    return 1
  fi

  ok "Certificado emitido em /etc/letsencrypt/live/${dominio}/"
  _ssl_adicionar_alias_wildcard "$dominio"

  if [[ "$instalador" == "nginx" ]] && ja_instalado nginx; then
    info "Instalando certificado no Nginx..."
    sudo certbot install --nginx --cert-name "$dominio" --redirect -n 2>/dev/null \
      || aviso "Instale o certificado manualmente nos server blocks, se necessário."
    sudo nginx -t && sudo systemctl reload nginx
  elif [[ "$instalador" == "apache" ]] && ja_instalado apache2; then
    info "Instalando certificado no Apache..."
    sudo certbot install --apache --cert-name "$dominio" --redirect -n 2>/dev/null \
      || aviso "Instale o certificado manualmente nos VirtualHosts, se necessário."
    sudo apache2ctl configtest && sudo systemctl reload apache2
  fi

  ok "Wildcard ativo: ${dominio}  e  *.${dominio}"
  echo
  echo "  ${NEGRITO}${VERDE_CLARO}  HTTPS ${RESET}  https://${dominio}"
  echo "  ${NEGRITO}${VERDE_CLARO}  HTTPS ${RESET}  https://qualquer-sub.${dominio}"
  return 0
}

