# ── PHP ─────────────────────────────────────────────────────────────────────
adicionarRepoPhp(){
  titulo "Repositório PHP (ondrej/php)"
  info "Instalando software-properties-common..."
  sudo apt install -y software-properties-common
  sep
  info "Adicionando PPA ondrej/php..."
  sudo apt install -y ppa-purge
  sudo add-apt-repository ppa:ondrej/php -y
  ok "Repositório adicionado com sucesso!"
  linha
  MenuPHP
}

InstalarVersaoPhp(){
  titulo "Instalar Versão Específica do PHP"
  entrada "Versão do PHP desejada (Ex: 8.3):"
  read vPHP
  echo

  if [[ -z "$vPHP" ]]; then
    erro "Versão não informada."
    pausar; MenuPHP; return
  fi

  local TOTAL=4
  local inicio=$SECONDS

  passo 1 $TOTAL "Atualizar repositórios"
  sudo apt update
  ok "Repositórios atualizados!"

  passo 2 $TOTAL "Instalar PHP $vPHP"
  if ja_instalado "php$vPHP"; then
    aviso "PHP $vPHP já está instalado — reinstalando módulos."
  fi
  sudo apt install -y php$vPHP
  ok "PHP $vPHP instalado!"

  passo 3 $TOTAL "Instalar módulos do PHP $vPHP"
  sudo apt install -y \
    php${vPHP}-common php${vPHP}-cli php${vPHP}-cgi \
    php${vPHP}-curl php${vPHP}-gd php${vPHP}-mbstring \
    php${vPHP}-intl php${vPHP}-imap php${vPHP}-sqlite3 \
    php${vPHP}-tidy php${vPHP}-xmlrpc php${vPHP}-xsl \
    php${vPHP}-opcache php${vPHP}-zip php${vPHP}-pgsql 2>/dev/null
  sudo phpenmod pdo_pgsql 2>/dev/null || true
  ok "Módulos instalados!"

  passo 4 $TOTAL "Finalizar"
  info "Limpando resíduos..."
  sudo apt autoclean -y && sudo apt --purge autoremove -y
  info "Reiniciando Apache..."
  sudo systemctl restart apache2

  local duracao=$((SECONDS - inicio))
  linha
  ok "PHP $vPHP instalado com sucesso em ${duracao}s!"
  item "Versão: $(php -v 2>/dev/null | head -1)"
  linha
  pausar
  MenuPHP
}
InstalarVersaoPhpLamp(){
  passo 6 7 "Instalar PHP"
  entrada "Versão do PHP (Ex: 8.3 — deixe vazio para a mais recente):"
  read vPHP
  echo
  if [[ -z "$vPHP" ]]; then
    info "Instalando versão mais recente do PHP..."
    sudo apt install -y php
    vPHP=$(php -v 2>/dev/null | grep -oP '^\S+\s+\K\d+\.\d+' | head -1)
  else
    info "Instalando PHP $vPHP..."
    sudo apt install -y php$vPHP
  fi
  sep
  info "Instalando módulos do PHP $vPHP..."
  sudo apt install -y \
    php${vPHP}-common php${vPHP}-cli php${vPHP}-cgi \
    php${vPHP}-curl php${vPHP}-gd php${vPHP}-mbstring \
    php${vPHP}-intl php${vPHP}-imap php${vPHP}-sqlite3 \
    php${vPHP}-tidy php${vPHP}-xmlrpc php${vPHP}-xsl \
    php${vPHP}-opcache php${vPHP}-zip php${vPHP}-pgsql 2>/dev/null
  sudo phpenmod pdo_pgsql 2>/dev/null || true
  ok "PHP $vPHP e módulos instalados!"
}

InstalarUltimaVersaoPhp(){
  titulo "Instalar Versão Atual do PHP"
  local TOTAL=4
  local inicio=$SECONDS

  passo 1 $TOTAL "Atualizar repositórios"
  sudo apt update
  ok "Repositórios atualizados!"

  passo 2 $TOTAL "Instalar PHP (versão atual)"
  sudo apt install -y php
  local vPHP
  vPHP=$(php -v 2>/dev/null | grep -oP '^\S+\s+\K\d+\.\d+' | head -1)
  ok "PHP $vPHP instalado!"

  passo 3 $TOTAL "Instalar módulos do PHP"
  sudo apt install -y \
    php-common php-cli php-cgi \
    php-curl php-gd php-mbstring \
    php-intl php-imap php-sqlite3 \
    php-tidy php-xmlrpc php-xsl \
    php-opcache php-zip php-pgsql 2>/dev/null
  sudo phpenmod pdo_pgsql 2>/dev/null || true
  ok "Módulos instalados!"

  passo 4 $TOTAL "Finalizar"
  info "Limpando resíduos..."
  sudo apt autoclean -y && sudo apt --purge autoremove -y
  info "Reiniciando Apache..."
  sudo systemctl restart apache2

  local duracao=$((SECONDS - inicio))
  linha
  ok "PHP $vPHP instalado com sucesso em ${duracao}s!"
  item "Versão: $(php -v 2>/dev/null | head -1)"
  linha
  pausar
  MenuPHP
}
ListarVersoesInstaladasPHP(){
  titulo "Versões do PHP Instaladas"
  sudo update-alternatives --list php
  linha
  pausar
  MenuPHP
}
UsarOutraVersaoPHP(){
  titulo "Habilitar Versão do PHP"
  entrada "Informe a versão desejada (Ex: 8.1):"
  read vPHP
  sep
  info "Habilitando PHP $vPHP..."
  sudo update-alternatives --set php /usr/bin/php$vPHP
  ok "PHP $vPHP habilitado com sucesso!"
  linha
  pausar
  MenuPHP
}
DesinstalarPHP(){
  titulo "Desinstalar Versão do PHP"
  entrada "Informe a versão a desinstalar (Ex: 8.1):"
  read vPHP
  sep
  info "Desinstalando PHP $vPHP..."
  sudo apt remove -y php$vPHP*
  sudo apt purge -y php$vPHP*
  ok "PHP $vPHP removido com sucesso!"
  linha
  pausar
  MenuPHP
}

# ── Composer ────────────────────────────────────────────────────────────────
InstalarComposer(){
  titulo "Instalar Composer"
  info "Baixando e instalando Composer..."
  sudo curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
  sep
  if [ -e "/usr/local/bin/composer" ]; then
    ok "Composer instalado com sucesso!"
  else
    erro "Falha ao instalar o Composer!"
  fi
  linha
  pausar
  Menu
}

# ── Configurar php.ini ──────────────────────────────────────────────────────
ConfigurarPhpIni(){
  titulo "Configurar php.ini"
  vphp=$(php -v 2>/dev/null | head -1 | grep -oP '\d+\.\d+' | head -1)
  phpini="/etc/php/$vphp/apache2/php.ini"
  info "PHP detectado: $vphp"
  item "Arquivo: $phpini"
  sep
  info "Valores atuais:"
  item "memory_limit:         $(grep "^memory_limit" $phpini 2>/dev/null | awk '{print $3}')"
  item "upload_max_filesize:  $(grep "^upload_max_filesize" $phpini 2>/dev/null | awk '{print $3}')"
  item "post_max_size:        $(grep "^post_max_size" $phpini 2>/dev/null | awk '{print $3}')"
  item "max_execution_time:   $(grep "^max_execution_time" $phpini 2>/dev/null | awk '{print $3}')"
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
  [[ -n "$val_memory" ]] && sudo sed -i "s/^memory_limit.*/memory_limit = $val_memory/" $phpini && ok "memory_limit → $val_memory"
  [[ -n "$val_upload" ]] && sudo sed -i "s/^upload_max_filesize.*/upload_max_filesize = $val_upload/" $phpini && ok "upload_max_filesize → $val_upload"
  [[ -n "$val_post"   ]] && sudo sed -i "s/^post_max_size.*/post_max_size = $val_post/" $phpini && ok "post_max_size → $val_post"
  [[ -n "$val_exec"   ]] && sudo sed -i "s/^max_execution_time.*/max_execution_time = $val_exec/" $phpini && ok "max_execution_time → $val_exec"
  sep
  info "Reiniciando Apache..."
  sudo systemctl restart apache2
  ok "Apache reiniciado! Configurações aplicadas."
  linha
  pausar
  MenuPHP
}


# ── Menu PHP ────────────────────────────────────────────────────────────────
MenuPHP(){
  cabecalho "PHP" "Douglas S. Santos"
  opcao_menu 1 "Instalar versão atual do PHP"
  opcao_menu 2 "Instalar outra versão do PHP"
  sep
  opcao_menu 3 "Listar versões do PHP instaladas"
  opcao_menu 4 "Habilitar outra versão do PHP"
  sep
  opcao_menu 5 "Desinstalar versão do PHP"
  opcao_menu 6 "Adicionar repositório PPA (ondrej/php)"
  sep
  opcao_menu 7 "Configurar php.ini"
  echo
  opcao_menu 0 "Voltar ao Menu Principal"
  echo
  entrada "Escolha uma opção:"
  read opcao
  linha
  case $opcao in
    1) InstalarUltimaVersaoPhp;;
    2) InstalarVersaoPhp;;
    3) ListarVersoesInstaladasPHP;;
    4) UsarOutraVersaoPHP;;
    5) DesinstalarPHP;;
    6) adicionarRepoPhp;;
    7) ConfigurarPhpIni;;
    0) Menu;;
    *) erro "Opção inválida!" ; sleep 1 ; MenuPHP ;;
  esac
}
