# ── Apache / LAMP ───────────────────────────────────────────────────────────
InstalarLamp(){
  cabecalho "INSTALAÇÃO DO LAMP" "Apache + PHP + Ferramentas"

  # ── Pré-verificações ──────────────────────────────────────────────────────
  info "Verificando pré-requisitos..."
  echo

  local erros=0

  if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
    erro "Sem permissão sudo. Execute o script com um usuário que tenha sudo."
    erros=$((erros+1))
  else
    ok "Permissão sudo disponível"
  fi

  if verificar_internet; then
    ok "Conexão com a internet OK"
  else
    erro "Sem acesso à internet. Verifique sua conexão."
    erros=$((erros+1))
  fi

  if verificar_espaco; then
    livre=$(df / | awk 'NR==2 {printf "%dMB", $4/1024}')
    ok "Espaço em disco disponível ($livre livres)"
  else
    erro "Espaço insuficiente em disco (mínimo recomendado: 500MB)."
    erros=$((erros+1))
  fi

  if [[ $erros -gt 0 ]]; then
    linha
    aviso "$erros problema(s) encontrado(s). A instalação pode falhar."
    entrada "Deseja continuar mesmo assim? (y/n):"
    read continuar
    [[ "$continuar" != "y" && "$continuar" != "Y" ]] && MenuApache && return
  fi

  # ── Resumo do que será instalado ──────────────────────────────────────────
  linha
  echo "  ${NEGRITO}${BRANCO}O seguinte será instalado:${RESET}"
  echo
  item "Apache2 + módulos (headers, rewrite, expires)"
  item "Certbot + python3-certbot-apache"
  item "Curl, Wget, NMAP, net-tools"
  item "Repositório PPA ondrej/php"
  item "PHP (versão a escolher) + módulos essenciais"
  echo
  entrada "Confirmar instalação? (y/n):"
  read confirmar
  [[ "$confirmar" != "y" && "$confirmar" != "Y" ]] && aviso "Instalação cancelada." && pausar && MenuApache && return

  local TOTAL=7
  local inicio=$SECONDS

  # ── Passo 1 ───────────────────────────────────────────────────────────────
  passo 1 $TOTAL "Atualizar repositórios"
  sudo apt update
  ok "Repositórios atualizados!"

  # ── Passo 2 ───────────────────────────────────────────────────────────────
  passo 2 $TOTAL "Instalar Apache2"
  if ja_instalado apache2; then
    aviso "Apache2 já está instalado — pulando."
  else
    sudo apt install -y apache2
    ok "Apache2 instalado!"
  fi
  dirConf="
  <IfModule mod_dir.c>\n
       DirectoryIndex index.php index.html index.cgi index.pl index.php index.xhtml index.htm\n
  </IfModule>\n
   # vim: syntax=apache ts=4 sw=4 sts=4 sr noet\n"
  sudo echo -e $dirConf > /etc/apache2/mods-enabled/dir.conf
  sudo chown -R www-data:www-data /var/www
  info "Ativando módulos Apache (headers, rewrite, expires)..."
  sudo a2enmod headers rewrite expires
  info "Aplicando regras UFW..."
  sudo ufw app info "Apache Full" &>/dev/null && sudo ufw allow "Apache Full" &>/dev/null
  ok "Apache configurado!"

  # ── Passo 3 ───────────────────────────────────────────────────────────────
  passo 3 $TOTAL "Instalar ferramentas essenciais (Curl, Wget, net-tools, NMAP)"
  sudo apt install -y curl wget net-tools nmap
  ok "Ferramentas instaladas!"

  # ── Passo 4 ───────────────────────────────────────────────────────────────
  passo 4 $TOTAL "Instalar Certbot"
  if ja_instalado certbot; then
    aviso "Certbot já está instalado — pulando."
  else
    sudo apt install -y certbot python3-certbot-apache
    ok "Certbot instalado!"
  fi

  # ── Passo 5 ───────────────────────────────────────────────────────────────
  passo 5 $TOTAL "Adicionar repositório PHP (ondrej/php)"
  if grep -r "ondrej/php" /etc/apt/sources.list.d/ &>/dev/null; then
    aviso "Repositório ondrej/php já existe — pulando."
  else
    sudo apt install -y software-properties-common ppa-purge
    sudo add-apt-repository ppa:ondrej/php -y
    sudo apt update
    ok "Repositório PHP adicionado!"
  fi

  # ── Passo 6 ───────────────────────────────────────────────────────────────
  passo 6 $TOTAL "Instalar PHP"
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

  # ── Passo 7 ───────────────────────────────────────────────────────────────
  passo 7 $TOTAL "Finalizar e reiniciar serviços"
  info "Limpando resíduos..."
  sudo apt autoclean -y && sudo apt --purge autoremove -y
  info "Reiniciando Apache..."
  sudo systemctl restart apache2
  ok "Apache reiniciado!"

  # ── Sumário ───────────────────────────────────────────────────────────────
  local duracao=$((SECONDS - inicio))
  local ip=$(hostname -I | awk '{print $1}')
  local v_apache=$(apache2 -v 2>/dev/null | grep "Server version" | awk '{print $3}')
  local v_php=$(php -v 2>/dev/null | head -1 | awk '{print $2}')

  linha
  echo "  ${NEGRITO}${VERDE_CLARO}✔  Instalação concluída em ${duracao}s!${RESET}"
  echo
  item "Apache:   ${v_apache:-instalado}"
  item "PHP:      ${v_php:-instalado}"
  item "Certbot:  $(certbot --version 2>/dev/null || echo 'instalado')"
  sep
  echo "  ${NEGRITO}${BRANCO}Acesse:${RESET}"
  echo "  ${CIANO}http://${ip}${RESET}"
  linha
  pausar
  MenuApache
}
DesinstalarLamp(){
  titulo "Desinstalar LAMP"
  aviso "Esta operação removerá Apache, PHP, Certbot, NMAP, Curl e Wget."
  entrada "Confirmar desinstalação? (y/n):"
  read confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    aviso "Operação cancelada."
    pausar
    MenuApache
    return
  fi
  sep
  info "Parando e removendo Apache..."
  sudo systemctl stop apache2
  sudo apt remove -y apache2.* && sudo apt purge -y apache2.*
  sudo apt remove --purge -y apache2
  sudo rm -rf /etc/apache2
  ok "Apache removido!"
  sep
  info "Bloqueando regras UFW..."
  sudo ufw deny "Apache Full"
  sep
  info "Removendo net-tools..."
  sudo apt remove -y net-tools && sudo apt purge -y net-tools
  sep
  info "Removendo PHP..."
  sudo apt remove -y php* && sudo apt purge -y php*
  ok "PHP removido!"
  sep
  info "Removendo Certbot..."
  sudo apt remove -y certbot && sudo apt purge -y certbot
  sep
  info "Removendo NMAP..."
  sudo apt remove -y nmap && sudo apt purge -y nmap
  sep
  info "Removendo Curl e Wget..."
  sudo apt remove -y curl && sudo apt purge -y curl
  sudo apt remove -y wget && sudo apt purge -y wget
  sep
  info "Removendo software-properties-common..."
  sudo apt remove -y software-properties-common && sudo apt purge -y software-properties-common
  sep
  info "Removendo repositório PHP (ondrej/php)..."
  sudo apt remove -y ppa-purge
  sudo add-apt-repository --remove -y ppa:ondrej/php
  sudo ppa-purge -y ppa:ondrej/php
  sep
  info "Limpando resíduos..."
  sudo apt autoclean -y && apt --purge autoremove -y
  ok "LAMP desinstalado com sucesso!"
  linha
  pausar
  MenuApache
}
AdicionarDominioOnline(){
  titulo "Adicionar Domínio Online (com SSL)"
  entrada "Nome do domínio (ex: meusite.com):"
  read dominio
  sep
  entrada "Pasta root dentro do projeto (ex: /public ou deixe vazio):"
  read path
  sep
  vhostconf="
  <VirtualHost *:80>\n
      <Directory /var/www/$dominio$path>\n
          Options Indexes FollowSymLinks\n
          AllowOverride All\n
          Require all granted\n
      </Directory>\n

       ServerAdmin webmaster@$dominio\n
       ServerName $dominio\n
       ServerAlias www.$dominio\n
       DocumentRoot /var/www/$dominio$path\n
       ErrorLog ${APACHE_LOG_DIR}/error.log\n
       CustomLog ${APACHE_LOG_DIR}/access.log combined\n
  </VirtualHost>"


  info "Criando pasta /var/www/$dominio..."
  sudo mkdir -p /var/www/$dominio
  sudo chown -R www-data:www-data /var/www/$dominio
  sudo chmod -R 755 /var/www/$dominio
  sudo echo "Site $dominio – OK!" > /var/www/$dominio/index.html
  ok "Pasta criada!"
  sep
  info "Criando VirtualHost..."
  sudo echo -e $vhostconf > /etc/apache2/sites-available/$dominio.conf
  ln -s /etc/apache2/sites-available/$dominio.conf /etc/apache2/sites-enabled/ 2>/dev/null
  sudo a2ensite $dominio.conf
  sudo a2dissite 000-default.conf
  ok "VirtualHost criado!"
  sep
  info "Reiniciando Apache..."
  sudo systemctl restart apache2
  ok "Apache reiniciado!"
  sep
  ipserver="$(hostname -I | awk '{print $1}')"
  info "Configurando /etc/hosts  (IP: $ipserver)..."
  sudo echo -e "127.0.0.1         $dominio www.$dominio" >> /etc/hosts
  ok "Hosts configurado!"
  sep
  info "Executando ConfigTest..."
  sudo apache2ctl configtest
  sep
  info "Recarregando Apache..."
  sudo systemctl reload apache2
  sep
  info "Aplicando regras UFW..."
  sudo ufw allow 'Apache Full'
  sudo ufw delete allow 'Apache'
  sep
  info "Obtendo certificado SSL via Certbot..."
  sudo certbot run -n --apache --agree-tos -d $dominio,www.$dominio -m $email --redirect
  sep
  info "Verificando renovação automática..."
  sudo systemctl status certbot.timer
  sudo certbot renew --dry-run
  sep
  info "Reiniciando Apache..."
  sudo systemctl restart apache2
  linha
  ok "Domínio adicionado e SSL ativo!"
  echo
  echo "  ${NEGRITO}${VERDE_CLARO}  HTTP  ${RESET}  http://$dominio"
  echo "  ${NEGRITO}${VERDE_CLARO}  HTTPS ${RESET}  https://$dominio"
  linha
  pausar
  MenuApache
}

AdicionarDominioLocal(){
  titulo "Adicionar Domínio Local"
  entrada "Nome do domínio (ex: meusite.local):"
  read dominio
  sep
  entrada "Pasta root dentro do projeto (ex: /public ou deixe vazio):"
  read path
  sep
  vhostconf="
  <VirtualHost *:80>\n
      <Directory /var/www/$dominio$path>\n
          Options Indexes FollowSymLinks\n
          AllowOverride All\n
          Require all granted\n
      </Directory>\n

       ServerAdmin webmaster@$dominio\n
       ServerName $dominio\n
       DocumentRoot /var/www/$dominio$path\n
       ErrorLog ${APACHE_LOG_DIR}/error.log\n
       CustomLog ${APACHE_LOG_DIR}/access.log combined\n
  </VirtualHost>"


  info "Criando pasta /var/www/$dominio..."
  sudo mkdir -p /var/www/$dominio
  sudo chown -R www-data:www-data /var/www/$dominio
  sudo chmod -R 755 /var/www/$dominio
  sudo echo "Site $dominio – OK!" > /var/www/$dominio/index.html
  ok "Pasta criada!"
  sep
  info "Criando VirtualHost..."
  sudo echo -e $vhostconf > /etc/apache2/sites-available/$dominio.conf
  ln -s /etc/apache2/sites-available/$dominio.conf /etc/apache2/sites-enabled/ 2>/dev/null
  sudo a2ensite $dominio.conf
  sudo a2dissite 000-default.conf
  ok "VirtualHost criado!"
  sep
  info "Reiniciando Apache..."
  sudo systemctl restart apache2
  ok "Apache reiniciado!"
  sep
  ipserver="$(hostname -I | awk '{print $1}')"
  info "Configurando /etc/hosts  (IP: $ipserver)..."
  sudo echo -e "$ipserver         $dominio" >> /etc/hosts
  ok "Hosts configurado!"
  sep
  info "Executando ConfigTest..."
  sudo apache2ctl configtest
  sep
  info "Recarregando Apache..."
  sudo systemctl reload apache2
  sep
  info "Aplicando regras UFW..."
  sudo ufw allow 'Apache Full'
  sudo ufw delete allow 'Apache'
  sep
  entrada "Deseja instalar SSL no domínio local? (y/n):"
  read obterSSL
  sep
  if [[ "$obterSSL" == "y" || "$obterSSL" == "Y" ]]; then
    info "Obtendo certificado SSL via Certbot..."
    sudo certbot run -n --apache --agree-tos -d $dominio,www.$dominio -m $email --redirect
    sep
    info "Verificando renovação automática..."
    sudo systemctl status certbot.timer
    sudo certbot renew --dry-run
    ok "SSL ativo!"
    sep
  fi
  info "Reiniciando Apache..."
  sudo systemctl restart apache2
  linha
  ok "Domínio local adicionado com sucesso!"
  echo
  echo "  ${NEGRITO}${VERDE_CLARO}  Local ${RESET}  http://$dominio"
  linha
  pausar
  MenuApache
}
renovar_ssl(){
  titulo "Renovar Certificado SSL"
  entrada "Digite o domínio:"
  read dominio
  sep
  info "Renovando SSL para $dominio..."
  certbot certonly --force-renew -d $dominio
  ok "SSL do domínio $dominio renovado com sucesso!"
  linha
  pausar
  MenuApache
}
RemoveDominio() {
  titulo "Remover Domínio"
  info "Hosts configurados:"
  sep
  cat /etc/hosts
  linha
  entrada "Digite o domínio a remover (ex: meusite.com.br):"
  read dominio
  sep
  entrada "Deseja deletar os arquivos do site em /var/www/$dominio? (y/n):"
  read rmFileSite
  sep
  if [[ "$rmFileSite" == "y" || "$rmFileSite" == "Y" ]]; then
    info "Deletando arquivos de /var/www/$dominio..."
    rm -fr /var/www/$dominio
    ok "Arquivos deletados!"
  fi
  info "Removendo configurações do Apache..."
  rm -f /etc/apache2/sites-available/$dominio.conf
  rm -f /etc/apache2/sites-available/$dominio-le-ssl.conf
  rm -f /etc/apache2/sites-enabled/$dominio.conf
  rm -f /etc/apache2/sites-enabled/$dominio-le-ssl.conf
  sed -i "/$dominio/d" /etc/hosts
  logger - WGR MF LOG = NOVO DOMINIO $dominio REMOVIDO
  ok "Domínio $dominio removido com sucesso!"
  linha
  pausar
  MenuApache
}
AplicarPermissoes(){
  titulo "Aplicar Permissões em Domínio"
  entrada "Digite o domínio (ex: meusite.com.br):"
  read dominio
  sep
  info "Aplicando permissões em /var/www/$dominio..."
  sudo chown -R www-data:www-data /var/www
  sudo chown -R www-data:www-data /var/www/$dominio/*
  logger - WGR MF LOG = PERMISSOES APLICADA AO DOMINIO $dominio
  ok "Permissões aplicadas ao domínio $dominio!"
  linha
  pausar
  MenuApache
}
VerificaApache() {
  titulo "Status do Apache"
  info "Verificando porta 80 via NMAP..."
  result=$(nmap -A 127.0.0.1 | grep 80)
  echo "  ${BRANCO}$result${RESET}"
  logger - WGR MF LOG = Status do Apache = $result
  linha
  pausar
  MenuApache
}
RedefinirConfigApache(){
  titulo "Redefinir Configuração do Apache"
  info "Reescrevendo dir.conf..."
  dirConf="
  <IfModule mod_dir.c>\n
       DirectoryIndex index.php index.html index.cgi index.pl index.php index.xhtml index.htm\n
  </IfModule>\n
   # vim: syntax=apache ts=4 sw=4 sts=4 sr noet\n"
  sudo echo -e $dirConf > /etc/apache2/mods-enabled/dir.conf
  sudo chown -R www-data:www-data /var/www
  sep
  info "Reiniciando Apache..."
  sudo systemctl restart apache2
  ok "Apache reiniciado com sucesso!"
  linha
  pausar
  MenuApache
}
ClonarSite(){
  titulo "Clonar Site"
  cat /etc/hosts
  sep
  entrada "Domínio de origem:"
  read dominioorigem
  sep
  entrada "Domínio de destino:"
  read dominiodestino
  sep
  info "Clonando /var/www/$dominioorigem → /var/www/$dominiodestino..."
  sudo rm -rf /var/www/$dominiodestino/
  sudo cp -p -R -v /var/www/$dominioorigem/ /var/www/$dominiodestino/
  sudo chown -R www-data:www-data /var/www/$dominiodestino/*
  logger - WGR MF LOG = DOMINIO CLONADO DE $dominioorigem PARA $dominiodestino
  ok "Arquivos clonados para /var/www/$dominiodestino!"
  linha
  pausar
  MenuApache
}
LimparSite(){
  titulo "Limpar Arquivos do Site"
  cat /etc/hosts
  sep
  entrada "Domínio a ser limpo:"
  read dominio
  sep
  aviso "Todos os arquivos em /var/www/$dominio serão apagados!"
  entrada "Confirmar? (y/n):"
  read confirm
  sep
  if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    sudo rm -rf /var/www/$dominio/*
    logger - WGR MF LOG = PASTA DO DOMINIO $dominio FOI ESVAZIADA
    ok "Pasta /var/www/$dominio esvaziada!"
  else
    aviso "Operação cancelada."
  fi
  linha
  pausar
  MenuApache
}
ListarDominios(){
  titulo "Domínios Ativos (/etc/hosts)"
  cat /etc/hosts
  linha
  pausar
  MenuApache
}

# ── Logs e Backup de Sites ──────────────────────────────────────────────────
VerLogsErroApache(){
  titulo "Log de Erros do Apache (últimas 50 linhas)"
  sudo tail -n 50 /var/log/apache2/error.log
  linha
  pausar
  MenuApache
}
VerLogsAcessoApache(){
  titulo "Log de Acesso do Apache (últimas 50 linhas)"
  sudo tail -n 50 /var/log/apache2/access.log
  linha
  pausar
  MenuApache
}
VerLogsDominio(){
  titulo "Logs de Domínio"
  cat /etc/hosts
  sep
  entrada "Digite o domínio:"
  read dominio
  sep
  info "Exibindo log de erros de $dominio..."
  if [ -f "/var/log/apache2/$dominio-error.log" ]; then
    sudo tail -n 50 /var/log/apache2/$dominio-error.log
  else
    sudo tail -n 50 /var/log/apache2/error.log
  fi
  linha
  pausar
  MenuApache
}
BackupSite(){
  titulo "Backup de Site"
  cat /etc/hosts
  sep
  entrada "Domínio a salvar:"
  read dominio
  sep
  timestamp=$(date +"%Y%m%d_%H%M%S")
  backupfile="/var/backups/${dominio}_${timestamp}.tar.gz"
  info "Criando backup de /var/www/$dominio..."
  sudo mkdir -p /var/backups
  sudo tar -czf $backupfile /var/www/$dominio 2>/dev/null
  sep
  if [ -f "$backupfile" ]; then
    tamanho=$(du -sh $backupfile | awk '{print $1}')
    ok "Backup criado com sucesso!"
    item "Arquivo: $backupfile"
    item "Tamanho: $tamanho"
  else
    erro "Falha ao criar o backup!"
  fi
  linha
  pausar
  MenuApache
}
RestaurarBackupSite(){
  titulo "Restaurar Backup de Site"
  info "Backups disponíveis em /var/backups:"
  sep
  ls /var/backups/*.tar.gz 2>/dev/null || aviso "Nenhum backup encontrado."
  sep
  entrada "Caminho completo do arquivo de backup:"
  read backupfile
  sep
  entrada "Domínio de destino:"
  read dominio
  sep
  info "Restaurando backup para /var/www/$dominio..."
  sudo mkdir -p /var/www/$dominio
  sudo tar -xzf $backupfile -C /var/www/$dominio --strip-components=3 2>/dev/null
  sudo chown -R www-data:www-data /var/www/$dominio
  ok "Backup restaurado em /var/www/$dominio!"
  linha
  pausar
  MenuApache
}
ListarBackups(){
  titulo "Backups Disponíveis"
  if ls /var/backups/*.tar.gz 2>/dev/null; then
    sep
    du -sh /var/backups/*.tar.gz 2>/dev/null
  else
    aviso "Nenhum backup encontrado em /var/backups."
  fi
  linha
  pausar
  MenuApache
}

# ── Menu Apache ─────────────────────────────────────────────────────────────
MenuApache(){
  cabecalho "APACHE / LAMP" "Douglas S. Santos"
  opcao_menu  1 "Instalar o LAMP"
  opcao_menu  2 "Desinstalar o LAMP"
  sep
  opcao_menu  3 "Adicionar Domínio Online (com SSL)"
  opcao_menu  4 "Adicionar Domínio Local"
  opcao_menu  5 "Remover Domínio"
  opcao_menu  6 "Aplicar Permissões em Domínio"
  opcao_menu  7 "Renovar SSL"
  opcao_menu  8 "Verificar Status do Apache"
  opcao_menu  9 "Redefinir Config do Apache"
  sep
  opcao_menu 10 "Clonar Site"
  opcao_menu 11 "Limpar Site"
  opcao_menu 12 "Listar Domínios Ativos"
  sep
  opcao_menu 13 "Backup de Site"
  opcao_menu 14 "Restaurar Backup de Site"
  opcao_menu 15 "Listar Backups"
  sep
  opcao_menu 16 "Ver Log de Erros do Apache"
  opcao_menu 17 "Ver Log de Acesso do Apache"
  opcao_menu 18 "Ver Logs de um Domínio"
  echo
  opcao_menu  0 "Voltar ao Menu Principal"
  echo
  entrada "Escolha uma opção:"
  read opcao
  linha
  case $opcao in
    1) InstalarLamp;;
    2) DesinstalarLamp;;
    3) AdicionarDominioOnline;;
    4) AdicionarDominioLocal;;
    5) RemoveDominio;;
    6) AplicarPermissoes;;
    7) renovar_ssl;;
    8) VerificaApache;;
    9) RedefinirConfigApache;;
    10) ClonarSite;;
    11) LimparSite;;
    12) ListarDominios;;
    13) BackupSite;;
    14) RestaurarBackupSite;;
    15) ListarBackups;;
    16) VerLogsErroApache;;
    17) VerLogsAcessoApache;;
    18) VerLogsDominio;;
    0) Menu;;
    *) erro "Opção inválida!" ; sleep 1 ; MenuApache ;;
  esac
}
