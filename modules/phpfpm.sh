# ── PHP-FPM ─────────────────────────────────────────────────────────────────
_fpm_versao_atual(){
  php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null
}

_fpm_servico(){
  echo "php${1}-fpm"
}

_fpm_pool(){
  echo "/etc/php/${1}/fpm/pool.d/www.conf"
}

_fpm_ini(){
  echo "/etc/php/${1}/fpm/php.ini"
}

_fpm_log(){
  local v="$1"
  if [[ -f "/var/log/php${v}-fpm.log" ]]; then
    echo "/var/log/php${v}-fpm.log"
  elif [[ -f "/var/log/php-fpm.log" ]]; then
    echo "/var/log/php-fpm.log"
  else
    echo "/var/log/php${v}-fpm.log"
  fi
}

_fpm_sock(){
  local v="$1"
  if [[ -S "/run/php/php${v}-fpm.sock" ]]; then
    echo "/run/php/php${v}-fpm.sock"
  elif [[ -S "/var/run/php/php${v}-fpm.sock" ]]; then
    echo "/var/run/php/php${v}-fpm.sock"
  else
    echo "/run/php/php${v}-fpm.sock"
  fi
}

_fpm_versoes_instaladas(){
  local d
  for d in /etc/php/*/fpm; do
    [[ -d "$d" ]] || continue
    basename "$(dirname "$d")"
  done
}

_fpm_escolher_versao(){
  local prompt="${1:-Versão do PHP-FPM}"
  local -a versoes=()
  local v
  while IFS= read -r v; do
    [[ -n "$v" ]] && versoes+=("$v")
  done < <(_fpm_versoes_instaladas)

  if [[ ${#versoes[@]} -eq 0 ]]; then
    local atual
    atual=$(_fpm_versao_atual)
    if [[ -n "$atual" ]]; then
      _FPM_VER="$atual"
      return 0
    fi
    erro "Nenhuma versão do PHP-FPM encontrada."
    _FPM_VER=""
    return 1
  fi

  if [[ ${#versoes[@]} -eq 1 ]]; then
    _FPM_VER="${versoes[0]}"
    info "Usando PHP-FPM ${_FPM_VER}"
    return 0
  fi

  _selecionar "$prompt" "${versoes[@]}" || return 1
  _FPM_VER="$_SELECIONADO"
}

_fpm_atualizar_nginx(){
  local v="$1"
  [[ -d /etc/nginx/sites-available ]] || return 0
  local sock
  sock=$(_fpm_sock "$v")
  sudo sed -i "s|fastcgi_pass unix:/run/php/php[0-9.]*-fpm.sock;|fastcgi_pass unix:${sock};|g" /etc/nginx/sites-available/* 2>/dev/null || true
  sudo sed -i "s|fastcgi_pass unix:/var/run/php/php[0-9.]*-fpm.sock;|fastcgi_pass unix:${sock};|g" /etc/nginx/sites-available/* 2>/dev/null || true
}

InstalarPhpFpm(){
  titulo "Instalar PHP-FPM"
  entrada "Versão do PHP (Ex: 8.3 — deixe vazio para a mais recente):"
  read vPHP
  echo

  local TOTAL=3
  local inicio=$SECONDS

  passo 1 $TOTAL "Atualizar repositórios"
  sudo apt update
  ok "Repositórios atualizados!"

  passo 2 $TOTAL "Instalar PHP-FPM"
  if [[ -z "$vPHP" ]]; then
    sudo apt install -y php-fpm
    vPHP=$(_fpm_versao_atual)
  else
    sudo apt install -y "php${vPHP}-fpm"
  fi
  if [[ -z "$vPHP" ]]; then
    erro "Não foi possível detectar a versão do PHP-FPM."
    pausar
    MenuPhpFpm
    return
  fi
  sudo systemctl enable "$(_fpm_servico "$vPHP")"
  sudo systemctl start "$(_fpm_servico "$vPHP")"
  ok "PHP-FPM $vPHP instalado!"

  passo 3 $TOTAL "Finalizar"
  if ja_instalado nginx; then
    _fpm_atualizar_nginx "$vPHP"
    sudo systemctl reload nginx 2>/dev/null || true
  fi

  local duracao=$((SECONDS - inicio))
  linha
  ok "PHP-FPM $vPHP instalado em ${duracao}s!"
  item "Serviço: $(_fpm_servico "$vPHP")"
  item "Socket:  $(_fpm_sock "$vPHP")"
  item "Pool:    $(_fpm_pool "$vPHP")"
  linha
  pausar
  MenuPhpFpm
}

DesinstalarPhpFpm(){
  titulo "Desinstalar PHP-FPM"
  if ! _fpm_escolher_versao "Versão a desinstalar"; then
    pausar
    MenuPhpFpm
    return
  fi
  local v="$_FPM_VER"
  aviso "Isso removerá o serviço php${v}-fpm."
  entrada "Confirmar? (y/n):"
  read confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    aviso "Operação cancelada."
    pausar
    MenuPhpFpm
    return
  fi
  sep
  info "Parando e removendo PHP-FPM $v..."
  sudo systemctl stop "$(_fpm_servico "$v")" 2>/dev/null || true
  sudo apt remove -y "php${v}-fpm"
  sudo apt purge -y "php${v}-fpm"
  ok "PHP-FPM $v removido!"
  linha
  pausar
  MenuPhpFpm
}

IniciarPhpFpm(){
  titulo "Iniciar PHP-FPM"
  _fpm_escolher_versao "Versão a iniciar" || { pausar; MenuPhpFpm; return; }
  info "Iniciando $(_fpm_servico "$_FPM_VER")..."
  sudo systemctl start "$(_fpm_servico "$_FPM_VER")"
  ok "PHP-FPM $_FPM_VER iniciado!"
  linha
  pausar
  MenuPhpFpm
}

PararPhpFpm(){
  titulo "Parar PHP-FPM"
  _fpm_escolher_versao "Versão a parar" || { pausar; MenuPhpFpm; return; }
  info "Parando $(_fpm_servico "$_FPM_VER")..."
  sudo systemctl stop "$(_fpm_servico "$_FPM_VER")"
  ok "PHP-FPM $_FPM_VER parado!"
  linha
  pausar
  MenuPhpFpm
}

ReiniciarPhpFpm(){
  titulo "Reiniciar PHP-FPM"
  _fpm_escolher_versao "Versão a reiniciar" || { pausar; MenuPhpFpm; return; }
  info "Reiniciando $(_fpm_servico "$_FPM_VER")..."
  sudo systemctl restart "$(_fpm_servico "$_FPM_VER")"
  ok "PHP-FPM $_FPM_VER reiniciado!"
  linha
  pausar
  MenuPhpFpm
}

StatusPhpFpm(){
  titulo "Status do PHP-FPM"
  _fpm_escolher_versao "Versão" || { pausar; MenuPhpFpm; return; }
  sudo systemctl status "$(_fpm_servico "$_FPM_VER")" --no-pager -l
  linha
  pausar
  MenuPhpFpm
}

ListarVersoesPhpFpm(){
  titulo "Versões do PHP-FPM Instaladas"
  local v status sock
  local achou=0
  while IFS= read -r v; do
    [[ -z "$v" ]] && continue
    achou=1
    status=$(sudo systemctl is-active "$(_fpm_servico "$v")" 2>/dev/null)
    sock=$(_fpm_sock "$v")
    if [[ "$status" == "active" ]]; then
      ok "PHP-FPM $v  —  ATIVO  —  $sock"
    else
      erro "PHP-FPM $v  —  INATIVO  —  $sock"
    fi
  done < <(_fpm_versoes_instaladas)
  if [[ $achou -eq 0 ]]; then
    aviso "Nenhuma versão do PHP-FPM instalada."
  fi
  linha
  pausar
  MenuPhpFpm
}

HabilitarVersaoPhpFpm(){
  titulo "Habilitar Versão do PHP-FPM"
  _fpm_escolher_versao "Versão a habilitar" || { pausar; MenuPhpFpm; return; }
  local v="$_FPM_VER"
  info "Habilitando PHP-FPM $v..."
  sudo systemctl enable "$(_fpm_servico "$v")"
  sudo systemctl start "$(_fpm_servico "$v")"
  if ja_instalado nginx; then
    info "Atualizando sockets nos sites do Nginx..."
    _fpm_atualizar_nginx "$v"
    sudo nginx -t && sudo systemctl reload nginx
  fi
  ok "PHP-FPM $v habilitado!"
  item "Socket: $(_fpm_sock "$v")"
  linha
  pausar
  MenuPhpFpm
}

InfoPhpFpm(){
  titulo "Informações do PHP-FPM"
  _fpm_escolher_versao "Versão" || { pausar; MenuPhpFpm; return; }
  local v="$_FPM_VER"
  local pool ini sock
  pool=$(_fpm_pool "$v")
  ini=$(_fpm_ini "$v")
  sock=$(_fpm_sock "$v")

  item "Versão:   $v"
  item "Serviço:  $(_fpm_servico "$v")  ($(sudo systemctl is-active "$(_fpm_servico "$v")" 2>/dev/null))"
  item "Socket:   $sock"
  item "php.ini:  $ini"
  item "Pool:     $pool"
  sep
  if [[ -f "$pool" ]]; then
    info "Pool www.conf:"
    item "user:               $(grep -E '^user\s*=' "$pool" | awk -F= '{print $2}' | xargs)"
    item "group:              $(grep -E '^group\s*=' "$pool" | awk -F= '{print $2}' | xargs)"
    item "listen:             $(grep -E '^listen\s*=' "$pool" | awk -F= '{print $2}' | xargs)"
    item "pm:                 $(grep -E '^pm\s*=' "$pool" | awk -F= '{print $2}' | xargs)"
    item "pm.max_children:    $(grep -E '^pm.max_children\s*=' "$pool" | awk -F= '{print $2}' | xargs)"
    item "pm.start_servers:   $(grep -E '^pm.start_servers\s*=' "$pool" | awk -F= '{print $2}' | xargs)"
    item "pm.min_spare:       $(grep -E '^pm.min_spare_servers\s*=' "$pool" | awk -F= '{print $2}' | xargs)"
    item "pm.max_spare:       $(grep -E '^pm.max_spare_servers\s*=' "$pool" | awk -F= '{print $2}' | xargs)"
  else
    aviso "Arquivo de pool não encontrado."
  fi
  linha
  pausar
  MenuPhpFpm
}

TestarConfigPhpFpm(){
  titulo "Testar Configuração do PHP-FPM"
  _fpm_escolher_versao "Versão" || { pausar; MenuPhpFpm; return; }
  local v="$_FPM_VER"
  info "Validando configuração do PHP-FPM $v..."
  if command -v "php-fpm${v}" &>/dev/null; then
    sudo "php-fpm${v}" -t
  elif command -v php-fpm &>/dev/null; then
    sudo php-fpm -t
  else
    sudo systemctl reload "$(_fpm_servico "$v")" && ok "Reload enviado ao serviço."
  fi
  linha
  pausar
  MenuPhpFpm
}

ConfigurarPhpFpmIni(){
  titulo "Configurar php.ini do PHP-FPM"
  _fpm_escolher_versao "Versão" || { pausar; MenuPhpFpm; return; }
  local v="$_FPM_VER"
  local phpini
  phpini=$(_fpm_ini "$v")
  if [[ ! -f "$phpini" ]]; then
    erro "Arquivo não encontrado: $phpini"
    pausar
    MenuPhpFpm
    return
  fi
  item "Arquivo: $phpini"
  sep
  info "Valores atuais:"
  item "memory_limit:         $(grep "^memory_limit" "$phpini" 2>/dev/null | awk '{print $3}')"
  item "upload_max_filesize:  $(grep "^upload_max_filesize" "$phpini" 2>/dev/null | awk '{print $3}')"
  item "post_max_size:        $(grep "^post_max_size" "$phpini" 2>/dev/null | awk '{print $3}')"
  item "max_execution_time:   $(grep "^max_execution_time" "$phpini" 2>/dev/null | awk '{print $3}')"
  sep
  entrada "memory_limit (ex: 256M) [ENTER para manter]:"
  read val_memory
  entrada "upload_max_filesize (ex: 64M) [ENTER para manter]:"
  read val_upload
  entrada "post_max_size (ex: 64M) [ENTER para manter]:"
  read val_post
  entrada "max_execution_time (ex: 300) [ENTER para manter]:"
  read val_exec
  sep
  [[ -n "$val_memory" ]] && sudo sed -i "s/^memory_limit.*/memory_limit = $val_memory/" "$phpini" && ok "memory_limit → $val_memory"
  [[ -n "$val_upload" ]] && sudo sed -i "s/^upload_max_filesize.*/upload_max_filesize = $val_upload/" "$phpini" && ok "upload_max_filesize → $val_upload"
  [[ -n "$val_post"   ]] && sudo sed -i "s/^post_max_size.*/post_max_size = $val_post/" "$phpini" && ok "post_max_size → $val_post"
  [[ -n "$val_exec"   ]] && sudo sed -i "s/^max_execution_time.*/max_execution_time = $val_exec/" "$phpini" && ok "max_execution_time → $val_exec"
  sep
  info "Reiniciando PHP-FPM $v..."
  sudo systemctl restart "$(_fpm_servico "$v")"
  ok "Configurações aplicadas."
  linha
  pausar
  MenuPhpFpm
}

ConfigurarPoolPhpFpm(){
  titulo "Configurar Pool www.conf"
  _fpm_escolher_versao "Versão" || { pausar; MenuPhpFpm; return; }
  local v="$_FPM_VER"
  local pool
  pool=$(_fpm_pool "$v")
  if [[ ! -f "$pool" ]]; then
    erro "Arquivo não encontrado: $pool"
    pausar
    MenuPhpFpm
    return
  fi
  item "Arquivo: $pool"
  sep
  info "Valores atuais:"
  item "pm:                 $(grep -E '^pm\s*=' "$pool" | awk -F= '{print $2}' | xargs)"
  item "pm.max_children:    $(grep -E '^pm.max_children\s*=' "$pool" | awk -F= '{print $2}' | xargs)"
  item "pm.start_servers:   $(grep -E '^pm.start_servers\s*=' "$pool" | awk -F= '{print $2}' | xargs)"
  item "pm.min_spare:       $(grep -E '^pm.min_spare_servers\s*=' "$pool" | awk -F= '{print $2}' | xargs)"
  item "pm.max_spare:       $(grep -E '^pm.max_spare_servers\s*=' "$pool" | awk -F= '{print $2}' | xargs)"
  sep
  entrada "pm (static|dynamic|ondemand) [ENTER para manter]:"
  read val_pm
  entrada "pm.max_children [ENTER para manter]:"
  read val_max
  entrada "pm.start_servers [ENTER para manter]:"
  read val_start
  entrada "pm.min_spare_servers [ENTER para manter]:"
  read val_min
  entrada "pm.max_spare_servers [ENTER para manter]:"
  read val_spare
  sep
  if [[ -n "$val_pm" ]]; then
    if [[ "$val_pm" != "static" && "$val_pm" != "dynamic" && "$val_pm" != "ondemand" ]]; then
      erro "Valor inválido para pm. Use static, dynamic ou ondemand."
    else
      sudo sed -i "s/^pm\s*=.*/pm = $val_pm/" "$pool" && ok "pm → $val_pm"
    fi
  fi
  [[ -n "$val_max"   ]] && sudo sed -i "s/^pm.max_children\s*=.*/pm.max_children = $val_max/" "$pool" && ok "pm.max_children → $val_max"
  [[ -n "$val_start" ]] && sudo sed -i "s/^pm.start_servers\s*=.*/pm.start_servers = $val_start/" "$pool" && ok "pm.start_servers → $val_start"
  [[ -n "$val_min"   ]] && sudo sed -i "s/^pm.min_spare_servers\s*=.*/pm.min_spare_servers = $val_min/" "$pool" && ok "pm.min_spare_servers → $val_min"
  [[ -n "$val_spare" ]] && sudo sed -i "s/^pm.max_spare_servers\s*=.*/pm.max_spare_servers = $val_spare/" "$pool" && ok "pm.max_spare_servers → $val_spare"
  sep
  info "Reiniciando PHP-FPM $v..."
  sudo systemctl restart "$(_fpm_servico "$v")"
  ok "Pool atualizado!"
  linha
  pausar
  MenuPhpFpm
}

VerLogsPhpFpm(){
  titulo "Log do PHP-FPM (últimas 50 linhas)"
  _fpm_escolher_versao "Versão" || { pausar; MenuPhpFpm; return; }
  local logf
  logf=$(_fpm_log "$_FPM_VER")
  if [[ -f "$logf" ]]; then
    item "Arquivo: $logf"
    sep
    sudo tail -n 50 "$logf"
  else
    aviso "Arquivo de log não encontrado ($logf). Exibindo journal:"
    sep
    sudo journalctl -u "$(_fpm_servico "$_FPM_VER")" -n 50 --no-pager
  fi
  linha
  pausar
  MenuPhpFpm
}

# ── Menu PHP-FPM ────────────────────────────────────────────────────────────
MenuPhpFpm(){
  cabecalho "PHP-FPM" "Douglas S. Santos"
  opcao_menu  1 "Instalar PHP-FPM"
  opcao_menu  2 "Desinstalar PHP-FPM"
  sep
  opcao_menu  3 "Iniciar PHP-FPM"
  opcao_menu  4 "Parar PHP-FPM"
  opcao_menu  5 "Reiniciar PHP-FPM"
  opcao_menu  6 "Status do PHP-FPM"
  sep
  opcao_menu  7 "Listar versões instaladas"
  opcao_menu  8 "Habilitar versão do PHP-FPM"
  opcao_menu  9 "Informações do PHP-FPM"
  opcao_menu 10 "Testar configuração"
  sep
  opcao_menu 11 "Configurar php.ini (FPM)"
  opcao_menu 12 "Configurar pool www.conf"
  opcao_menu 13 "Ver logs do PHP-FPM"
  echo
  opcao_menu  0 "Voltar ao Menu Principal"
  echo
  entrada "Escolha uma opção:"
  read opcao
  linha
  case $opcao in
    1) InstalarPhpFpm;;
    2) DesinstalarPhpFpm;;
    3) IniciarPhpFpm;;
    4) PararPhpFpm;;
    5) ReiniciarPhpFpm;;
    6) StatusPhpFpm;;
    7) ListarVersoesPhpFpm;;
    8) HabilitarVersaoPhpFpm;;
    9) InfoPhpFpm;;
    10) TestarConfigPhpFpm;;
    11) ConfigurarPhpFpmIni;;
    12) ConfigurarPoolPhpFpm;;
    13) VerLogsPhpFpm;;
    0) Menu;;
    *) erro "Opção inválida!" ; sleep 1 ; MenuPhpFpm ;;
  esac
}
