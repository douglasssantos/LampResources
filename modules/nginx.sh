# ── Nginx / LEMP ────────────────────────────────────────────────────────────
_nginx_php_versao(){
  php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null
}

_nginx_fpm_sock(){
  local v
  v=$(_nginx_php_versao)
  if [[ -S "/run/php/php${v}-fpm.sock" ]]; then
    echo "/run/php/php${v}-fpm.sock"
  elif [[ -S "/var/run/php/php${v}-fpm.sock" ]]; then
    echo "/var/run/php/php${v}-fpm.sock"
  else
    echo "/run/php/php${v}-fpm.sock"
  fi
}

_nginx_escrever_site(){
  local dominio="$1"
  local path="$2"
  local root="/var/www/${dominio}${path}"
  local sock
  sock=$(_nginx_fpm_sock)

  sudo mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
  sudo tee "/etc/nginx/sites-available/${dominio}.conf" >/dev/null <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${dominio} www.${dominio};
    root ${root};
    index index.php index.html index.htm;

    access_log /var/log/nginx/${dominio}-access.log;
    error_log  /var/log/nginx/${dominio}-error.log;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        try_files \$uri =404;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_pass unix:${sock};
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF
  sudo ln -sfn "/etc/nginx/sites-available/${dominio}.conf" "/etc/nginx/sites-enabled/${dominio}.conf"
  sudo rm -f /etc/nginx/sites-enabled/default
}

InstalarLemp(){
  cabecalho "INSTALAÇÃO DO LEMP" "Nginx + PHP-FPM + Ferramentas"

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

  if systemctl is-active --quiet apache2 2>/dev/null; then
    aviso "Apache está ativo na porta 80 e será parado para o Nginx assumir."
  fi

  if [[ $erros -gt 0 ]]; then
    linha
    aviso "$erros problema(s) encontrado(s). A instalação pode falhar."
    entrada "Deseja continuar mesmo assim? (y/n):"
    read continuar
    [[ "$continuar" != "y" && "$continuar" != "Y" ]] && MenuNginx && return
  fi

  linha
  echo "  ${NEGRITO}${BRANCO}O seguinte será instalado:${RESET}"
  echo
  item "Nginx"
  item "PHP-FPM"
  item "Certbot + python3-certbot-nginx"
  item "Curl, Wget, NMAP, net-tools"
  item "Repositório PPA ondrej/php"
  item "PHP (versão a escolher) + módulos essenciais"
  echo
  entrada "Confirmar instalação? (y/n):"
  read confirmar
  [[ "$confirmar" != "y" && "$confirmar" != "Y" ]] && aviso "Instalação cancelada." && pausar && MenuNginx && return

  local TOTAL=7
  local inicio=$SECONDS

  passo 1 $TOTAL "Atualizar repositórios"
  sudo apt update
  ok "Repositórios atualizados!"

  passo 2 $TOTAL "Instalar Nginx"
  if systemctl is-active --quiet apache2 2>/dev/null; then
    sudo systemctl stop apache2
    sudo systemctl disable apache2
    ok "Apache parado e desabilitado (porta 80)."
  fi
  if ja_instalado nginx; then
    aviso "Nginx já está instalado — pulando."
  else
    sudo apt install -y nginx
    ok "Nginx instalado!"
  fi
  sudo mkdir -p /var/www /etc/nginx/sites-available /etc/nginx/sites-enabled /etc/nginx/conf.d
  sudo chown -R www-data:www-data /var/www
  sudo tee /etc/nginx/conf.d/lamp-index.conf >/dev/null <<'EOF'
index index.php index.html index.htm;
EOF
  sudo systemctl enable nginx
  sudo systemctl start nginx
  info "Aplicando regras UFW..."
  sudo ufw app info "Nginx Full" &>/dev/null && sudo ufw allow "Nginx Full" &>/dev/null
  ok "Nginx configurado!"

  passo 3 $TOTAL "Instalar ferramentas essenciais (Curl, Wget, net-tools, NMAP)"
  sudo apt install -y curl wget net-tools nmap
  ok "Ferramentas instaladas!"

  passo 4 $TOTAL "Instalar Certbot"
  if ja_instalado certbot; then
    aviso "Certbot já está instalado — instalando plugin Nginx."
    sudo apt install -y python3-certbot-nginx
  else
    sudo apt install -y certbot python3-certbot-nginx
    ok "Certbot instalado!"
  fi

  passo 5 $TOTAL "Adicionar repositório PHP (ondrej/php)"
  if grep -r "ondrej/php" /etc/apt/sources.list.d/ &>/dev/null; then
    aviso "Repositório ondrej/php já existe — pulando."
  else
    sudo apt install -y software-properties-common ppa-purge
    sudo add-apt-repository ppa:ondrej/php -y
    sudo apt update
    ok "Repositório PHP adicionado!"
  fi

  passo 6 $TOTAL "Instalar PHP + PHP-FPM"
  entrada "Versão do PHP (Ex: 8.3 — deixe vazio para a mais recente):"
  read vPHP
  echo
  if [[ -z "$vPHP" ]]; then
    info "Instalando versão mais recente do PHP..."
    sudo apt install -y php php-fpm
    vPHP=$(_nginx_php_versao)
  else
    info "Instalando PHP $vPHP e PHP-FPM..."
    sudo apt install -y php$vPHP php${vPHP}-fpm
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
  sudo systemctl enable "php${vPHP}-fpm"
  sudo systemctl start "php${vPHP}-fpm"
  ok "PHP $vPHP, PHP-FPM e módulos instalados!"

  passo 7 $TOTAL "Finalizar e reiniciar serviços"
  info "Limpando resíduos..."
  sudo apt autoclean -y && sudo apt --purge autoremove -y
  info "Reiniciando Nginx e PHP-FPM..."
  sudo systemctl restart "php${vPHP}-fpm"
  sudo systemctl restart nginx
  ok "Nginx reiniciado!"

  local duracao=$((SECONDS - inicio))
  local ip=$(hostname -I | awk '{print $1}')
  local v_nginx=$(nginx -v 2>&1 | awk -F/ '{print $2}')
  local v_php=$(php -v 2>/dev/null | head -1 | awk '{print $2}')

  linha
  echo "  ${NEGRITO}${VERDE_CLARO}✔  Instalação concluída em ${duracao}s!${RESET}"
  echo
  item "Nginx:    ${v_nginx:-instalado}"
  item "PHP:      ${v_php:-instalado}"
  item "PHP-FPM:  ${vPHP:-instalado}"
  item "Certbot:  $(certbot --version 2>/dev/null || echo 'instalado')"
  sep
  echo "  ${NEGRITO}${BRANCO}Acesse:${RESET}"
  echo "  ${CIANO}http://${ip}${RESET}"
  linha
  pausar
  MenuNginx
}

DesinstalarLemp(){
  titulo "Desinstalar LEMP"
  aviso "Esta operação removerá Nginx. PHP e ferramentas compartilhadas só saem se o Apache não estiver instalado."
  entrada "Confirmar desinstalação? (y/n):"
  read confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    aviso "Operação cancelada."
    pausar
    MenuNginx
    return
  fi
  sep
  info "Parando e removendo Nginx..."
  sudo systemctl stop nginx 2>/dev/null || true
  sudo apt remove -y nginx nginx-* && sudo apt purge -y nginx nginx-*
  sudo rm -rf /etc/nginx
  ok "Nginx removido!"
  sep
  info "Bloqueando regras UFW..."
  sudo ufw deny "Nginx Full" 2>/dev/null || true

  if ja_instalado apache2; then
    aviso "Apache ainda está instalado — PHP, Certbot e ferramentas foram mantidos."
  else
    sep
    info "Removendo net-tools..."
    sudo apt remove -y net-tools && sudo apt purge -y net-tools
    sep
    info "Removendo PHP..."
    sudo apt remove -y php* && sudo apt purge -y php*
    ok "PHP removido!"
    sep
    info "Removendo Certbot..."
    sudo apt remove -y certbot python3-certbot-nginx && sudo apt purge -y certbot python3-certbot-nginx
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
  fi
  sep
  info "Limpando resíduos..."
  sudo apt autoclean -y && apt --purge autoremove -y
  ok "LEMP desinstalado com sucesso!"
  linha
  pausar
  MenuNginx
}

AdicionarDominioOnlineNginx(){
  titulo "Adicionar Domínio Online (com SSL)"
  if ! ja_instalado nginx; then
    erro "Nginx não está instalado. Use a opção Instalar primeiro."
    pausar
    MenuNginx
    return
  fi
  entrada "Nome do domínio (ex: meusite.com):"
  read dominio
  sep
  entrada "Pasta root dentro do projeto (ex: /public ou deixe vazio):"
  read path
  sep

  info "Criando pasta /var/www/$dominio..."
  sudo mkdir -p /var/www/$dominio
  sudo chown -R www-data:www-data /var/www/$dominio
  sudo chmod -R 755 /var/www/$dominio
  echo "Site $dominio – OK!" | sudo tee /var/www/$dominio/index.html >/dev/null
  ok "Pasta criada!"
  sep
  info "Criando server block do Nginx..."
  _nginx_escrever_site "$dominio" "$path"
  ok "Server block criado!"
  sep
  info "Reiniciando Nginx..."
  sudo systemctl restart nginx
  ok "Nginx reiniciado!"
  sep
  ipserver="$(hostname -I | awk '{print $1}')"
  info "Configurando /etc/hosts  (IP: $ipserver)..."
  echo -e "127.0.0.1         $dominio www.$dominio" | sudo tee -a /etc/hosts >/dev/null
  ok "Hosts configurado!"
  sep
  info "Executando ConfigTest..."
  sudo nginx -t
  sep
  info "Recarregando Nginx..."
  sudo systemctl reload nginx
  sep
  info "Aplicando regras UFW..."
  sudo ufw allow 'Nginx Full'
  sudo ufw delete allow 'Nginx HTTP' 2>/dev/null || true
  sep
  info "Obtendo certificado SSL via Certbot..."
  sudo certbot run -n --nginx --agree-tos -d $dominio,www.$dominio -m $email --redirect
  sep
  info "Verificando renovação automática..."
  sudo systemctl status certbot.timer
  sudo certbot renew --dry-run
  sep
  info "Reiniciando Nginx..."
  sudo systemctl restart nginx
  linha
  ok "Domínio adicionado e SSL ativo!"
  echo
  echo "  ${NEGRITO}${VERDE_CLARO}  HTTP  ${RESET}  http://$dominio"
  echo "  ${NEGRITO}${VERDE_CLARO}  HTTPS ${RESET}  https://$dominio"
  linha
  pausar
  MenuNginx
}

AdicionarDominioLocalNginx(){
  titulo "Adicionar Domínio Local"
  if ! ja_instalado nginx; then
    erro "Nginx não está instalado. Use a opção Instalar primeiro."
    pausar
    MenuNginx
    return
  fi
  entrada "Nome do domínio (ex: meusite.local):"
  read dominio
  sep
  entrada "Pasta root dentro do projeto (ex: /public ou deixe vazio):"
  read path
  sep

  info "Criando pasta /var/www/$dominio..."
  sudo mkdir -p /var/www/$dominio
  sudo chown -R www-data:www-data /var/www/$dominio
  sudo chmod -R 755 /var/www/$dominio
  echo "Site $dominio – OK!" | sudo tee /var/www/$dominio/index.html >/dev/null
  ok "Pasta criada!"
  sep
  info "Criando server block do Nginx..."
  _nginx_escrever_site "$dominio" "$path"
  ok "Server block criado!"
  sep
  info "Reiniciando Nginx..."
  sudo systemctl restart nginx
  ok "Nginx reiniciado!"
  sep
  ipserver="$(hostname -I | awk '{print $1}')"
  info "Configurando /etc/hosts  (IP: $ipserver)..."
  echo -e "$ipserver         $dominio" | sudo tee -a /etc/hosts >/dev/null
  ok "Hosts configurado!"
  sep
  info "Executando ConfigTest..."
  sudo nginx -t
  sep
  info "Recarregando Nginx..."
  sudo systemctl reload nginx
  sep
  info "Aplicando regras UFW..."
  sudo ufw allow 'Nginx Full'
  sudo ufw delete allow 'Nginx HTTP' 2>/dev/null || true
  sep
  entrada "Deseja instalar SSL no domínio local? (y/n):"
  read obterSSL
  sep
  if [[ "$obterSSL" == "y" || "$obterSSL" == "Y" ]]; then
    info "Obtendo certificado SSL via Certbot..."
    sudo certbot run -n --nginx --agree-tos -d $dominio,www.$dominio -m $email --redirect
    sep
    info "Verificando renovação automática..."
    sudo systemctl status certbot.timer
    sudo certbot renew --dry-run
    ok "SSL ativo!"
    sep
  fi
  info "Reiniciando Nginx..."
  sudo systemctl restart nginx
  linha
  ok "Domínio local adicionado com sucesso!"
  echo
  echo "  ${NEGRITO}${VERDE_CLARO}  Local ${RESET}  http://$dominio"
  linha
  pausar
  MenuNginx
}

renovar_ssl_nginx(){
  titulo "Renovar Certificado SSL"
  entrada "Digite o domínio:"
  read dominio
  sep
  info "Renovando SSL para $dominio..."
  certbot certonly --force-renew -d $dominio
  ok "SSL do domínio $dominio renovado com sucesso!"
  linha
  pausar
  MenuNginx
}

RemoveDominioNginx(){
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
  info "Removendo configurações do Nginx..."
  sudo rm -f /etc/nginx/sites-available/$dominio.conf
  sudo rm -f /etc/nginx/sites-enabled/$dominio.conf
  sudo rm -f /etc/nginx/sites-available/$dominio
  sudo rm -f /etc/nginx/sites-enabled/$dominio
  sed -i "/$dominio/d" /etc/hosts
  if ja_instalado nginx; then
    sudo nginx -t && sudo systemctl reload nginx
  fi
  logger - WGR MF LOG = NOVO DOMINIO $dominio REMOVIDO
  ok "Domínio $dominio removido com sucesso!"
  linha
  pausar
  MenuNginx
}

AplicarPermissoesNginx(){
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
  MenuNginx
}

VerificaNginx(){
  titulo "Status do Nginx"
  local status
  status=$(sudo systemctl is-active nginx 2>/dev/null)
  if [[ "$status" == "active" ]]; then
    ok "Nginx: ATIVO"
  else
    erro "Nginx: INATIVO"
  fi
  sep
  sudo systemctl status nginx --no-pager -l 2>/dev/null | head -20
  sep
  info "Verificando porta 80 via NMAP..."
  result=$(nmap -A 127.0.0.1 | grep 80)
  echo "  ${BRANCO}$result${RESET}"
  logger - WGR MF LOG = Status do Nginx = $result
  linha
  pausar
  MenuNginx
}

RedefinirConfigNginx(){
  titulo "Redefinir Configuração do Nginx"
  info "Definindo index.php como índice padrão..."
  sudo mkdir -p /var/www /etc/nginx/conf.d
  sudo tee /etc/nginx/conf.d/lamp-index.conf >/dev/null <<'EOF'
index index.php index.html index.htm;
EOF
  sudo chown -R www-data:www-data /var/www
  sep
  info "Reiniciando Nginx..."
  sudo systemctl restart nginx
  ok "Nginx reiniciado com sucesso!"
  linha
  pausar
  MenuNginx
}

ClonarSiteNginx(){
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
  MenuNginx
}

LimparSiteNginx(){
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
  MenuNginx
}

ListarDominiosNginx(){
  titulo "Domínios Ativos"
  info "/etc/hosts:"
  sep
  cat /etc/hosts
  sep
  info "Sites habilitados no Nginx:"
  sep
  ls -1 /etc/nginx/sites-enabled/ 2>/dev/null || aviso "Nenhum site habilitado."
  linha
  pausar
  MenuNginx
}

VerLogsErroNginx(){
  titulo "Log de Erros do Nginx (últimas 50 linhas)"
  sudo tail -n 50 /var/log/nginx/error.log
  linha
  pausar
  MenuNginx
}

VerLogsAcessoNginx(){
  titulo "Log de Acesso do Nginx (últimas 50 linhas)"
  sudo tail -n 50 /var/log/nginx/access.log
  linha
  pausar
  MenuNginx
}

VerLogsDominioNginx(){
  titulo "Logs de Domínio"
  cat /etc/hosts
  sep
  entrada "Digite o domínio:"
  read dominio
  sep
  info "Exibindo log de erros de $dominio..."
  if [ -f "/var/log/nginx/$dominio-error.log" ]; then
    sudo tail -n 50 /var/log/nginx/$dominio-error.log
  else
    sudo tail -n 50 /var/log/nginx/error.log
  fi
  linha
  pausar
  MenuNginx
}

BackupSiteNginx(){
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
  MenuNginx
}

RestaurarBackupSiteNginx(){
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
  MenuNginx
}

ListarBackupsNginx(){
  titulo "Backups Disponíveis"
  if ls /var/backups/*.tar.gz 2>/dev/null; then
    sep
    du -sh /var/backups/*.tar.gz 2>/dev/null
  else
    aviso "Nenhum backup encontrado em /var/backups."
  fi
  linha
  pausar
  MenuNginx
}

# ── Menu Nginx ──────────────────────────────────────────────────────────────
MenuNginx(){
  cabecalho "NGINX / LEMP" "Douglas S. Santos"
  opcao_menu  1 "Instalar o LEMP"
  opcao_menu  2 "Desinstalar o LEMP"
  sep
  opcao_menu  3 "Adicionar Domínio Online (com SSL)"
  opcao_menu  4 "Adicionar Domínio Local"
  opcao_menu  5 "Remover Domínio"
  opcao_menu  6 "Aplicar Permissões em Domínio"
  opcao_menu  7 "Renovar SSL"
  opcao_menu  8 "Verificar Status do Nginx"
  opcao_menu  9 "Redefinir Config do Nginx"
  sep
  opcao_menu 10 "Clonar Site"
  opcao_menu 11 "Limpar Site"
  opcao_menu 12 "Listar Domínios Ativos"
  sep
  opcao_menu 13 "Backup de Site"
  opcao_menu 14 "Restaurar Backup de Site"
  opcao_menu 15 "Listar Backups"
  sep
  opcao_menu 16 "Ver Log de Erros do Nginx"
  opcao_menu 17 "Ver Log de Acesso do Nginx"
  opcao_menu 18 "Ver Logs de um Domínio"
  echo
  opcao_menu  0 "Voltar ao Menu Principal"
  echo
  entrada "Escolha uma opção:"
  read opcao
  linha
  case $opcao in
    1) InstalarLemp;;
    2) DesinstalarLemp;;
    3) AdicionarDominioOnlineNginx;;
    4) AdicionarDominioLocalNginx;;
    5) RemoveDominioNginx;;
    6) AplicarPermissoesNginx;;
    7) renovar_ssl_nginx;;
    8) VerificaNginx;;
    9) RedefinirConfigNginx;;
    10) ClonarSiteNginx;;
    11) LimparSiteNginx;;
    12) ListarDominiosNginx;;
    13) BackupSiteNginx;;
    14) RestaurarBackupSiteNginx;;
    15) ListarBackupsNginx;;
    16) VerLogsErroNginx;;
    17) VerLogsAcessoNginx;;
    18) VerLogsDominioNginx;;
    0) Menu;;
    *) erro "Opção inválida!" ; sleep 1 ; MenuNginx ;;
  esac
}
