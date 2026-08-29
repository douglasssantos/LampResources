# ── Sistema ─────────────────────────────────────────────────────────────────
InformacoesServidor(){
  titulo "Informações do Servidor"
  info "Sistema Operacional:"
  lsb_release -a 2>/dev/null || cat /etc/os-release
  sep
  info "Uptime:"
  uptime
  sep
  info "Uso de Memória:"
  free -h
  sep
  info "Uso de Disco:"
  df -h
  sep
  info "Endereços IP:"
  hostname -I
  sep
  info "CPU:"
  lscpu | grep -E "^(Model name|CPU\(s\)|Thread|Architecture)" 2>/dev/null || cat /proc/cpuinfo | grep "model name" | head -1
  sep
  info "Versões Instaladas:"
  item "Apache:     $(apache2 -v 2>/dev/null | head -1 || echo 'não instalado')"
  item "Nginx:      $(nginx -v 2>&1 || echo 'não instalado')"
  item "PHP:        $(php -v 2>/dev/null | head -1 || echo 'não instalado')"
  item "PHP-FPM:    $(php-fpm$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null) -v 2>/dev/null | head -1 || echo 'não instalado')"
  item "Node:       $(node -v 2>/dev/null || echo 'não instalado')"
  item "NPM:        $(npm -v 2>/dev/null || echo 'não instalado')"
  item "Composer:   $(composer --version 2>/dev/null | head -1 || echo 'não instalado')"
  item "PostgreSQL: $(psql --version 2>/dev/null || echo 'não instalado')"
  item "MySQL:      $(mysql --version 2>/dev/null || echo 'não instalado')"
  item "MongoDB:    $(mongod --version 2>/dev/null | head -1 || echo 'não instalado')"
  item "Redis:      $(redis-server --version 2>/dev/null || echo 'não instalado')"
  linha
  pausar
  MenuSistema
}
AtualizarSistema(){
  titulo "Atualizar Sistema"
  info "Atualizando pacotes..."
  sudo apt update
  sep
  sudo apt upgrade -y
  sep
  info "Limpando resíduos..."
  sudo apt autoclean -y && sudo apt --purge autoremove -y
  ok "Sistema atualizado com sucesso!"
  linha
  pausar
  MenuSistema
}
VerPortasEmUso(){
  titulo "Portas em Uso"
  sudo ss -tlnp 2>/dev/null || sudo netstat -tlnp 2>/dev/null
  linha
  pausar
  MenuSistema
}
VerServicosAtivos(){
  titulo "Status dos Serviços do Stack"
  echo
  apache_status=$(sudo systemctl is-active apache2 2>/dev/null)
  nginx_status=$(sudo systemctl is-active nginx 2>/dev/null)
  fpm_ver=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null)
  fpm_status=$(sudo systemctl is-active "php${fpm_ver}-fpm" 2>/dev/null)
  pg_status=$(sudo systemctl is-active postgresql 2>/dev/null)
  my_status=$(sudo systemctl is-active mysql 2>/dev/null)
  mongo_status=$(sudo systemctl is-active mongod 2>/dev/null)
  redis_status=$(sudo systemctl is-active redis-server 2>/dev/null)

  if [[ "$apache_status" == "active" ]]; then
    ok "Apache:      ATIVO"
  else
    erro "Apache:      INATIVO"
  fi
  if [[ "$nginx_status" == "active" ]]; then
    ok "Nginx:       ATIVO"
  else
    erro "Nginx:       INATIVO"
  fi
  if [[ -n "$fpm_ver" ]]; then
    if [[ "$fpm_status" == "active" ]]; then
      ok "PHP-FPM:     ATIVO ($fpm_ver)"
    else
      erro "PHP-FPM:     INATIVO ($fpm_ver)"
    fi
  fi
  if [[ "$pg_status" == "active" ]]; then
    ok "PostgreSQL:  ATIVO"
  else
    erro "PostgreSQL:  INATIVO"
  fi
  if [[ "$my_status" == "active" ]]; then
    ok "MySQL:       ATIVO"
  else
    erro "MySQL:       INATIVO"
  fi
  if [[ "$mongo_status" == "active" ]]; then
    ok "MongoDB:     ATIVO"
  else
    erro "MongoDB:     INATIVO"
  fi
  if [[ "$redis_status" == "active" ]]; then
    ok "Redis:       ATIVO"
  else
    erro "Redis:       INATIVO"
  fi
  linha
  pausar
  MenuSistema
}
LimparLogsSistema(){
  titulo "Limpar Logs do Servidor Web"
  aviso "Os arquivos error.log e access.log do Apache e/ou Nginx serão zerados."
  entrada "Confirmar? (y/n):"
  read confirm
  sep
  if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    if [[ -f /var/log/apache2/error.log ]]; then
      sudo truncate -s 0 /var/log/apache2/error.log
      sudo truncate -s 0 /var/log/apache2/access.log
      ok "Logs do Apache limpos!"
    fi
    if [[ -f /var/log/nginx/error.log ]]; then
      sudo truncate -s 0 /var/log/nginx/error.log
      sudo truncate -s 0 /var/log/nginx/access.log
      ok "Logs do Nginx limpos!"
    fi
  else
    aviso "Operação cancelada."
  fi
  linha
  pausar
  MenuSistema
}

# ── Menu Sistema ────────────────────────────────────────────────────────────
MenuSistema(){
  cabecalho "SISTEMA" "Douglas S. Santos"
  opcao_menu 1 "Informações do Servidor"
  opcao_menu 2 "Status dos Serviços (Apache / Nginx / PHP-FPM / PostgreSQL / MySQL / MongoDB / Redis)"
  opcao_menu 3 "Atualizar Sistema"
  opcao_menu 4 "Portas em Uso"
  opcao_menu 5 "Limpar Logs do Servidor Web"
  echo
  opcao_menu 0 "Voltar ao Menu Principal"
  echo
  entrada "Escolha uma opção:"
  read opcao
  linha
  case $opcao in
    1) InformacoesServidor;;
    2) VerServicosAtivos;;
    3) AtualizarSistema;;
    4) VerPortasEmUso;;
    5) LimparLogsSistema;;
    0) Menu;;
    *) erro "Opção inválida!" ; sleep 1 ; MenuSistema ;;
  esac
}

