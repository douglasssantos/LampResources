# ── MySQL ───────────────────────────────────────────────────────────────────
MY_BACKUP_DIR="/var/backups/mysql"

_my_exec(){
  sudo mysql -u root "$@" 2>/dev/null
}

_my_garantir_dir(){
  sudo mkdir -p "$MY_BACKUP_DIR"
}

_my_listar_backups(){
  if ls "$MY_BACKUP_DIR"/*.{sql,gz} 2>/dev/null | head -1 &>/dev/null; then
    echo
    printf "  ${CINZA}%-50s %8s  %s${RESET}\n" "Arquivo" "Tamanho" "Data"
    sep
    for f in $(ls -t "$MY_BACKUP_DIR"/*.{sql,gz} 2>/dev/null); do
      local nome tamanho data
      nome=$(basename "$f")
      tamanho=$(du -sh "$f" 2>/dev/null | awk '{print $1}')
      data=$(date -r "$f" "+%d/%m/%Y %H:%M" 2>/dev/null)
      printf "  ${BRANCO}%-50s${RESET} ${AMARELO_CLARO}%8s${RESET}  ${CINZA}%s${RESET}\n" "$nome" "$tamanho" "$data"
    done
    echo
  else
    aviso "Nenhum backup encontrado em $MY_BACKUP_DIR"
    return 1
  fi
}

InstalarMySQL(){
  titulo "Instalar MySQL"
  info "Atualizando repositórios..."
  sudo apt update
  sep
  info "Instalando mysql-server..."
  sudo apt install -y mysql-server
  sep
  info "Habilitando MySQL no boot..."
  sudo systemctl start mysql.service
  sudo systemctl enable mysql.service
  sep
  ok "MySQL instalado e iniciado com sucesso!"
  echo
  aviso "Recomendado executar o assistente de segurança:"
  item "sudo mysql_secure_installation"
  linha
  pausar
  MenuMySQL
}

DesinstalarMySQL(){
  titulo "Desinstalar MySQL"
  aviso "Todos os bancos de dados serão removidos permanentemente!"
  entrada "Confirmar? (y/n):"
  read confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    aviso "Operação cancelada."
    pausar; MenuMySQL; return
  fi
  sep
  info "Parando e removendo MySQL..."
  sudo systemctl stop mysql.service
  sudo apt --purge remove -y mysql-server mysql-client mysql-common
  sudo apt --purge remove -y mysql-server-*
  sudo rm -rf /etc/mysql /var/lib/mysql /var/log/mysql
  sudo deluser mysql 2>/dev/null || true
  sep
  info "Limpando resíduos..."
  sudo apt autoclean -y && sudo apt --purge autoremove -y
  ok "MySQL desinstalado com sucesso!"
  linha
  pausar
  MenuMySQL
}

IniciarMySQL(){
  titulo "Iniciar MySQL"
  info "Iniciando MySQL..."
  sudo systemctl start mysql.service
  ok "MySQL iniciado!"
  linha
  pausar
  MenuMySQL
}

PararMySQL(){
  titulo "Parar MySQL"
  info "Parando MySQL..."
  sudo systemctl stop mysql.service
  ok "MySQL parado!"
  linha
  pausar
  MenuMySQL
}

ReiniciarMySQL(){
  titulo "Reiniciar MySQL"
  info "Reiniciando MySQL..."
  sudo systemctl restart mysql.service
  ok "MySQL reiniciado!"
  linha
  pausar
  MenuMySQL
}

StatusMySQL(){
  titulo "Status do MySQL"
  sudo systemctl status mysql.service
  linha
  pausar
  MenuMySQL
}

SegurancaMySQL(){
  titulo "Assistente de Segurança MySQL"
  info "Executando mysql_secure_installation..."
  sep
  sudo mysql_secure_installation
  linha
  pausar
  MenuMySQL
}

CriarUsuarioMySQL(){
  titulo "Criar Usuário MySQL"
  entrada "Nome do usuário:"
  read myuser
  sep
  printf "  ${CIANO}▶  ${AMARELO_CLARO}%s${RESET} " "Senha do usuário:"
  read mypass
  echo
  sep
  entrada "Host do usuário (ex: localhost ou % para qualquer host):"
  read myhost
  [[ -z "$myhost" ]] && myhost="localhost"
  sep
  info "Criando usuário $myuser@$myhost..."
  _my_exec -e "CREATE USER IF NOT EXISTS '${myuser}'@'${myhost}' IDENTIFIED BY '${mypass}';"
  ok "Usuário $myuser@$myhost criado!"
  sep
  entrada "Conceder todos os privilégios? (y/n):"
  read conceder
  if [[ "$conceder" == "y" || "$conceder" == "Y" ]]; then
    entrada "Nome do banco (ou * para todos):"
    read mygrant
    [[ -z "$mygrant" ]] && mygrant="*"
    _my_exec -e "GRANT ALL PRIVILEGES ON ${mygrant}.* TO '${myuser}'@'${myhost}'; FLUSH PRIVILEGES;"
    ok "Privilégios concedidos em $mygrant para $myuser!"
  fi
  linha
  pausar
  MenuMySQL
}

DeletarUsuarioMySQL(){
  titulo "Deletar Usuário MySQL"
  info "Usuários existentes:"
  sep
  _my_exec -e "SELECT User, Host FROM mysql.user WHERE User NOT IN ('root','mysql.sys','mysql.session','mysql.infoschema');"
  sep
  entrada "Nome do usuário a deletar:"
  read myuser
  sep
  entrada "Host do usuário (padrão: localhost):"
  read myhost
  [[ -z "$myhost" ]] && myhost="localhost"
  sep
  aviso "Deletar '$myuser'@'$myhost'?"
  entrada "Confirmar? (y/n):"
  read confirm
  sep
  if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    _my_exec -e "DROP USER IF EXISTS '${myuser}'@'${myhost}'; FLUSH PRIVILEGES;"
    ok "Usuário $myuser@$myhost deletado!"
  else
    aviso "Operação cancelada."
  fi
  linha
  pausar
  MenuMySQL
}

ListarUsuariosMySQL(){
  titulo "Usuários do MySQL"
  _my_exec -e "SELECT User, Host, plugin FROM mysql.user ORDER BY User;"
  linha
  pausar
  MenuMySQL
}

CriarBancoDadosMySQL(){
  titulo "Criar Banco de Dados MySQL"
  entrada "Nome do banco de dados:"
  read mydb
  sep
  entrada "Charset (padrão: utf8mb4):"
  read mycharset
  [[ -z "$mycharset" ]] && mycharset="utf8mb4"
  sep
  info "Criando banco $mydb (charset: $mycharset)..."
  _my_exec -e "CREATE DATABASE IF NOT EXISTS \`${mydb}\` CHARACTER SET ${mycharset} COLLATE ${mycharset}_unicode_ci;"
  ok "Banco $mydb criado com sucesso!"
  sep
  entrada "Criar usuário para este banco? (y/n):"
  read criarusr
  if [[ "$criarusr" == "y" || "$criarusr" == "Y" ]]; then
    entrada "Nome do usuário:"
    read myuser
    printf "  ${CIANO}▶  ${AMARELO_CLARO}%s${RESET} " "Senha:"
    read -s mypass
    echo
    _my_exec -e "CREATE USER IF NOT EXISTS '${myuser}'@'localhost' IDENTIFIED BY '${mypass}'; GRANT ALL PRIVILEGES ON \`${mydb}\`.* TO '${myuser}'@'localhost'; FLUSH PRIVILEGES;"
    ok "Usuário $myuser criado e vinculado ao banco $mydb!"
  fi
  linha
  pausar
  MenuMySQL
}

DeletarBancoMySQL(){
  titulo "Deletar Banco de Dados MySQL"
  info "Bancos disponíveis:"
  sep
  _my_exec -e "SHOW DATABASES;" | grep -v "^Database$\|information_schema\|performance_schema\|mysql\|sys"
  sep
  entrada "Nome do banco a deletar:"
  read mydb
  sep
  aviso "Esta operação é IRREVERSÍVEL! O banco '$mydb' será apagado."
  entrada "Confirmar? (y/n):"
  read confirm
  sep
  if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    info "Deletando banco $mydb..."
    _my_exec -e "DROP DATABASE IF EXISTS \`${mydb}\`;"
    ok "Banco $mydb deletado!"
  else
    aviso "Operação cancelada."
  fi
  linha
  pausar
  MenuMySQL
}

ListarBancosMySQL(){
  titulo "Bancos de Dados no MySQL"
  _my_exec -e "SHOW DATABASES;"
  linha
  pausar
  MenuMySQL
}

BackupBancoMySQL(){
  titulo "Backup de Banco MySQL"

  _my_garantir_dir

  info "Bancos disponíveis:"
  sep
  _my_exec -e "SHOW DATABASES;" | grep -v "^Database$\|information_schema\|performance_schema\|sys"
  sep

  entrada "Nome do banco (ou ALL para todos):"
  read mydb
  echo

  entrada "Formato — [1] SQL (padrão)  [2] Comprimido .gz:"
  read fmt
  echo
  sep

  entrada "Tipo — [1] Completo  [2] Somente estrutura  [3] Somente dados:"
  read tipo
  echo

  local extra_flags=""
  case "$tipo" in
    2) extra_flags="--no-data" ;;
    3) extra_flags="--no-create-info" ;;
    *) extra_flags="" ;;
  esac

  local timestamp
  timestamp=$(date +"%Y%m%d_%H%M%S")
  sep

  if [[ "$mydb" == "ALL" || "$mydb" == "all" ]]; then
    local outfile="$MY_BACKUP_DIR/my_all_${timestamp}.sql"
    info "Criando backup de TODOS os bancos..."
    if sudo mysqldump -u root $extra_flags --all-databases > "$outfile" 2>/dev/null; then
      local tamanho; tamanho=$(du -sh "$outfile" | awk '{print $1}')
      ok "Backup completo criado!"
      item "Arquivo: $outfile"
      item "Tamanho: $tamanho"
    else
      sudo rm -f "$outfile" 2>/dev/null
      erro "Falha ao criar o backup!"
    fi
  else
    local outfile ext
    case "$fmt" in
      2)
        ext="sql.gz"
        outfile="$MY_BACKUP_DIR/my_${mydb}_${timestamp}.${ext}"
        info "Criando backup comprimido de $mydb..."
        sudo mysqldump -u root $extra_flags "$mydb" 2>/dev/null | gzip > "$outfile"
        ;;
      *)
        ext="sql"
        outfile="$MY_BACKUP_DIR/my_${mydb}_${timestamp}.${ext}"
        info "Criando backup SQL de $mydb..."
        sudo mysqldump -u root $extra_flags "$mydb" > "$outfile" 2>/dev/null
        ;;
    esac

    if [[ -s "$outfile" ]]; then
      local tamanho; tamanho=$(du -sh "$outfile" | awk '{print $1}')
      ok "Backup criado com sucesso!"
      item "Banco:   $mydb"
      item "Arquivo: $outfile"
      item "Tamanho: $tamanho"
      item "Tipo:    ${extra_flags:-completo}"
    else
      sudo rm -f "$outfile" 2>/dev/null
      erro "Falha ao criar o backup! Verifique se o banco '$mydb' existe."
    fi
  fi

  linha
  pausar
  MenuBackupMySQL
}

RestaurarBancoMySQL(){
  titulo "Restaurar Banco MySQL"

  if ! _my_listar_backups; then
    pausar; MenuBackupMySQL; return
  fi

  entrada "Nome do arquivo (apenas o nome, sem o caminho):"
  read nome_arquivo
  local backupfile="$MY_BACKUP_DIR/$nome_arquivo"

  if [[ ! -f "$backupfile" ]]; then
    erro "Arquivo não encontrado: $backupfile"
    pausar; MenuBackupMySQL; return
  fi
  sep

  entrada "Nome do banco de destino:"
  read mydb
  sep

  local banco_existe
  banco_existe=$(_my_exec -e "SHOW DATABASES LIKE '${mydb}';" 2>/dev/null | grep -c "$mydb" || echo 0)

  if [[ "$banco_existe" -gt 0 ]]; then
    aviso "O banco '$mydb' já existe!"
    entrada "Sobrescrever? (drop e recreate) (y/n):"
    read sobreescrever
    if [[ "$sobreescrever" == "y" || "$sobreescrever" == "Y" ]]; then
      info "Removendo banco existente $mydb..."
      _my_exec -e "DROP DATABASE \`${mydb}\`;" 2>/dev/null
    else
      aviso "Restauração cancelada."
      pausar; MenuBackupMySQL; return
    fi
  fi

  info "Criando banco $mydb..."
  _my_exec -e "CREATE DATABASE IF NOT EXISTS \`${mydb}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

  sep
  info "Restaurando $nome_arquivo → $mydb..."

  local ext="${backupfile##*.}"
  local sucesso=false

  case "$ext" in
    gz)
      zcat "$backupfile" | sudo mysql -u root "$mydb" &>/dev/null && sucesso=true
      ;;
    sql)
      sudo mysql -u root "$mydb" < "$backupfile" &>/dev/null && sucesso=true
      ;;
  esac

  if $sucesso; then
    ok "Banco '$mydb' restaurado com sucesso!"
  else
    erro "Ocorreu um erro durante a restauração."
    aviso "Verifique se o MySQL está rodando e tente novamente."
  fi

  linha
  pausar
  MenuBackupMySQL
}

ListarBackupsMySQL(){
  titulo "Backups MySQL Disponíveis"
  _my_listar_backups || true
  sep
  if ls "$MY_BACKUP_DIR"/*.{sql,gz} 2>/dev/null | head -1 &>/dev/null; then
    local total; total=$(du -sh "$MY_BACKUP_DIR" 2>/dev/null | awk '{print $1}')
    item "Diretório:    $MY_BACKUP_DIR"
    item "Espaço total: $total"
  fi
  linha
  pausar
  MenuBackupMySQL
}

AgendarBackupMySQL(){
  titulo "Agendar Backup Automático MySQL"

  info "O backup será feito via cron e salvo em $MY_BACKUP_DIR"
  echo

  entrada "Nome do banco (ou ALL para todos):"
  read mydb
  sep

  echo "  ${BRANCO}Frequência:${RESET}"
  opcao_menu 1 "Diário (03:00)"
  opcao_menu 2 "Semanal (domingo às 03:00)"
  opcao_menu 3 "A cada 6 horas"
  opcao_menu 4 "Personalizado"
  echo
  entrada "Escolha:"
  read freq
  echo

  local cron_expr banco_cmd outfile_expr
  outfile_expr="$MY_BACKUP_DIR/my_${mydb}_\$(date +%Y%m%d_%H%M%S).sql"

  case "$mydb" in
    ALL|all) banco_cmd="mysqldump -u root --all-databases > $outfile_expr" ;;
    *)       banco_cmd="mysqldump -u root $mydb > $outfile_expr" ;;
  esac

  case "$freq" in
    1) cron_expr="0 3 * * *" ;;
    2) cron_expr="0 3 * * 0" ;;
    3) cron_expr="0 */6 * * *" ;;
    4)
      entrada "Digite a expressão cron (ex: 0 4 * * 1):"
      read cron_expr
      ;;
    *) cron_expr="0 3 * * *" ;;
  esac

  sep
  local cron_line="$cron_expr $banco_cmd"
  info "Adicionando ao crontab do root..."
  ( sudo crontab -l 2>/dev/null | grep -v "my_backup_${mydb}"; echo "# my_backup_${mydb}"; echo "$cron_line" ) | sudo crontab -
  ok "Backup agendado com sucesso!"
  item "Banco:     $mydb"
  item "Expressão: $cron_expr"
  item "Destino:   $MY_BACKUP_DIR"
  linha
  pausar
  MenuBackupMySQL
}

LimparBackupsAntigosMySQL(){
  titulo "Limpar Backups Antigos MySQL"

  if ! _my_listar_backups; then
    pausar; MenuBackupMySQL; return
  fi

  entrada "Remover backups com mais de quantos dias? (ex: 30):"
  read dias
  sep

  if ! [[ "$dias" =~ ^[0-9]+$ ]]; then
    erro "Valor inválido. Digite apenas números."
    pausar; MenuBackupMySQL; return
  fi

  local count
  count=$(sudo find "$MY_BACKUP_DIR" -name "my_*" -mtime +$dias 2>/dev/null | wc -l)

  if [[ "$count" -eq 0 ]]; then
    aviso "Nenhum backup com mais de $dias dias encontrado."
    pausar; MenuBackupMySQL; return
  fi

  aviso "$count arquivo(s) com mais de $dias dias serão deletados:"
  sudo find "$MY_BACKUP_DIR" -name "my_*" -mtime +$dias 2>/dev/null | while read f; do
    item "$(basename $f)"
  done
  echo
  entrada "Confirmar exclusão? (y/n):"
  read confirm
  sep

  if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    sudo find "$MY_BACKUP_DIR" -name "my_*" -mtime +$dias -delete 2>/dev/null
    ok "$count backup(s) removido(s)!"
  else
    aviso "Operação cancelada."
  fi
  linha
  pausar
  MenuBackupMySQL
}

VerAgendamentosBackupMySQL(){
  titulo "Agendamentos de Backup MySQL (crontab)"
  sep
  sudo crontab -l 2>/dev/null | grep "my_backup\|mysqldump" || aviso "Nenhum agendamento de backup MySQL encontrado."
  linha
  pausar
  MenuBackupMySQL
}

RemoverAgendamentoBackupMySQL(){
  titulo "Remover Agendamento de Backup MySQL"
  sep
  sudo crontab -l 2>/dev/null | grep "my_backup\|mysqldump" || {
    aviso "Nenhum agendamento encontrado."
    pausar; MenuBackupMySQL; return
  }
  sep
  entrada "Nome do banco do agendamento a remover:"
  read mydb
  sep
  ( sudo crontab -l 2>/dev/null | grep -v "my_backup_${mydb}" | grep -v "mysqldump.*${mydb}" ) | sudo crontab -
  ok "Agendamento para '$mydb' removido!"
  linha
  pausar
  MenuBackupMySQL
}


# ── Menu Backup MySQL ───────────────────────────────────────────────────────
MenuBackupMySQL(){
  cabecalho "MYSQL — BACKUP" "Douglas S. Santos"
  opcao_menu 1 "Criar Backup (banco único ou todos)"
  opcao_menu 2 "Restaurar Backup"
  opcao_menu 3 "Listar Backups"
  opcao_menu 4 "Limpar Backups Antigos"
  sep
  opcao_menu 5 "Agendar Backup Automático (cron)"
  opcao_menu 6 "Ver Agendamentos"
  opcao_menu 7 "Remover Agendamento"
  echo
  opcao_menu 0 "Voltar ao Menu MySQL"
  echo
  entrada "Escolha uma opção:"
  read opcao
  linha
  case $opcao in
    1) BackupBancoMySQL;;
    2) RestaurarBancoMySQL;;
    3) ListarBackupsMySQL;;
    4) LimparBackupsAntigosMySQL;;
    5) AgendarBackupMySQL;;
    6) VerAgendamentosBackupMySQL;;
    7) RemoverAgendamentoBackupMySQL;;
    0) MenuMySQL;;
    *) erro "Opção inválida!" ; sleep 1 ; MenuBackupMySQL ;;
  esac
}


# ── Menu MySQL ──────────────────────────────────────────────────────────────
MenuMySQL(){
  cabecalho "MYSQL" "Douglas S. Santos"
  opcao_menu  1 "Instalar MySQL"
  opcao_menu  2 "Desinstalar MySQL"
  sep
  opcao_menu  3 "Iniciar MySQL"
  opcao_menu  4 "Parar MySQL"
  opcao_menu  5 "Reiniciar MySQL"
  opcao_menu  6 "Status do MySQL"
  opcao_menu  7 "Assistente de Segurança"
  sep
  opcao_menu  8 "Criar Usuário"
  opcao_menu  9 "Deletar Usuário"
  opcao_menu 10 "Listar Usuários"
  opcao_menu 11 "Criar Banco de Dados"
  opcao_menu 12 "Deletar Banco de Dados"
  opcao_menu 13 "Listar Bancos de Dados"
  sep
  opcao_menu 14 "Backup / Restore"
  echo
  opcao_menu  0 "Voltar ao Menu Principal"
  echo
  entrada "Escolha uma opção:"
  read opcao
  linha
  case $opcao in
    1)  InstalarMySQL;;
    2)  DesinstalarMySQL;;
    3)  IniciarMySQL;;
    4)  PararMySQL;;
    5)  ReiniciarMySQL;;
    6)  StatusMySQL;;
    7)  SegurancaMySQL;;
    8)  CriarUsuarioMySQL;;
    9)  DeletarUsuarioMySQL;;
    10) ListarUsuariosMySQL;;
    11) CriarBancoDadosMySQL;;
    12) DeletarBancoMySQL;;
    13) ListarBancosMySQL;;
    14) MenuBackupMySQL;;
    0)  Menu;;
    *) erro "Opção inválida!" ; sleep 1 ; MenuMySQL ;;
  esac
}

