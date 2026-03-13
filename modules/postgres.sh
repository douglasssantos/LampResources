# ── PostgreSQL ──────────────────────────────────────────────────────────────
InstalarPostgres(){
  titulo "Instalar PostgreSQL"
  info "Atualizando repositórios..."
  sudo apt update
  sep
  info "Instalando PostgreSQL..."
  sudo apt install -y postgresql postgresql-contrib
  sep
  info "Habilitando PostgreSQL no boot..."
  sudo systemctl start postgresql.service
  sudo systemctl enable postgresql.service
  ok "PostgreSQL instalado e iniciado com sucesso!"
  linha
  pausar
  MenuPostgres
}
DesinstalarPostgres(){
  titulo "Desinstalar PostgreSQL"
  aviso "Todos os bancos de dados serão removidos permanentemente!"
  entrada "Confirmar? (y/n):"
  read confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    aviso "Operação cancelada."
    pausar
    MenuPostgres
    return
  fi
  sep
  info "Parando e removendo PostgreSQL..."
  sudo systemctl stop postgresql.service
  sudo apt --purge remove -y postgresql postgresql-*
  sudo rm -rf /var/lib/postgresql/ /var/log/postgresql/ /etc/postgresql/
  sudo deluser postgres 2>/dev/null || true
  sep
  info "Limpando resíduos..."
  sudo apt autoclean -y && sudo apt --purge autoremove -y
  ok "PostgreSQL desinstalado com sucesso!"
  linha
  pausar
  MenuPostgres
}
IniciarPostgres(){
  titulo "Iniciar PostgreSQL"
  info "Iniciando PostgreSQL..."
  sudo systemctl start postgresql.service
  ok "PostgreSQL iniciado!"
  linha
  pausar
  MenuPostgres
}
PararPostgres(){
  titulo "Parar PostgreSQL"
  info "Parando PostgreSQL..."
  sudo systemctl stop postgresql.service
  ok "PostgreSQL parado!"
  linha
  pausar
  MenuPostgres
}
ReiniciarPostgres(){
  titulo "Reiniciar PostgreSQL"
  info "Reiniciando PostgreSQL..."
  sudo systemctl restart postgresql.service
  ok "PostgreSQL reiniciado!"
  linha
  pausar
  MenuPostgres
}
StatusPostgres(){
  titulo "Status do PostgreSQL"
  sudo systemctl status postgresql.service
  linha
  pausar
  MenuPostgres
}
CriarUsuarioPostgres(){
  titulo "Criar Usuário PostgreSQL"
  entrada "Nome do usuário:"
  read pguser
  sep
  printf "  ${CIANO}▶  ${AMARELO_CLARO}%s${RESET} " "Senha do usuário:"
  read pgpass
  echo
  sep
  info "Criando usuário $pguser..."
  sudo -u postgres psql -c "CREATE USER $pguser WITH PASSWORD '$pgpass';"
  ok "Usuário $pguser criado com sucesso!"
  linha
  pausar
  MenuPostgres
}
CriarBancoDadosPostgres(){
  titulo "Criar Banco de Dados PostgreSQL"
  entrada "Nome do banco de dados:"
  read pgdb
  sep
  entrada "Dono do banco (usuário postgres):"
  read pgowner
  sep
  info "Criando banco $pgdb..."
  sudo -u postgres psql -c "CREATE DATABASE $pgdb OWNER $pgowner;"
  ok "Banco $pgdb criado com sucesso!"
  linha
  pausar
  MenuPostgres
}
ListarBancosPostgres(){
  titulo "Bancos de Dados no PostgreSQL"
  sudo -u postgres psql -c "\l"
  linha
  pausar
  MenuPostgres
}
PG_BACKUP_DIR="/var/backups/postgres"

_pg_garantir_dir(){
  sudo mkdir -p "$PG_BACKUP_DIR"
}

_pg_listar_backups(){
  if ls "$PG_BACKUP_DIR"/*.{sql,gz,dump} 2>/dev/null | head -1 &>/dev/null; then
    echo
    printf "  ${CINZA}%-50s %8s  %s${RESET}\n" "Arquivo" "Tamanho" "Data"
    sep
    for f in $(ls -t "$PG_BACKUP_DIR"/*.{sql,gz,dump} 2>/dev/null); do
      local nome tamanho data
      nome=$(basename "$f")
      tamanho=$(du -sh "$f" 2>/dev/null | awk '{print $1}')
      data=$(date -r "$f" "+%d/%m/%Y %H:%M" 2>/dev/null)
      printf "  ${BRANCO}%-50s${RESET} ${AMARELO_CLARO}%8s${RESET}  ${CINZA}%s${RESET}\n" "$nome" "$tamanho" "$data"
    done
    echo
  else
    aviso "Nenhum backup encontrado em $PG_BACKUP_DIR"
    return 1
  fi
}

BackupBancoPostgres(){
  titulo "Backup de Banco PostgreSQL"

  _pg_garantir_dir

  info "Bancos disponíveis:"
  sep
  sudo -u postgres psql -c "\l" 2>/dev/null
  sep

  entrada "Nome do banco (ou ALL para todos):"
  read pgdb
  echo

  entrada "Formato — [1] SQL (padrão)  [2] Comprimido .gz  [3] Custom .dump:"
  read fmt
  echo
  sep

  local timestamp
  timestamp=$(date +"%Y%m%d_%H%M%S")

  entrada "Tipo — [1] Completo  [2] Somente estrutura  [3] Somente dados:"
  read tipo
  echo

  local extra_flags=""
  case "$tipo" in
    2) extra_flags="--schema-only" ;;
    3) extra_flags="--data-only" ;;
    *) extra_flags="" ;;
  esac

  sep

  if [[ "$pgdb" == "ALL" || "$pgdb" == "all" ]]; then
    # ── Backup de todos os bancos ──────────────────────────────────────────
    local outfile="$PG_BACKUP_DIR/pg_all_${timestamp}.sql"
    info "Criando backup de TODOS os bancos..."
    if sudo -u postgres pg_dumpall $extra_flags > "$outfile" 2>/dev/null; then
      local tamanho
      tamanho=$(du -sh "$outfile" | awk '{print $1}')
      ok "Backup completo criado!"
      item "Arquivo: $outfile"
      item "Tamanho: $tamanho"
    else
      erro "Falha ao criar o backup!"
      linha; pausar; MenuBackupPostgres; return
    fi
  else
    # ── Backup de um banco específico ─────────────────────────────────────
    local outfile ext
    case "$fmt" in
      2)
        ext="sql.gz"
        outfile="$PG_BACKUP_DIR/pg_${pgdb}_${timestamp}.${ext}"
        info "Criando backup comprimido de $pgdb..."
        sudo -u postgres pg_dump $extra_flags "$pgdb" 2>/dev/null | gzip > "$outfile"
        ;;
      3)
        ext="dump"
        outfile="$PG_BACKUP_DIR/pg_${pgdb}_${timestamp}.${ext}"
        info "Criando backup custom de $pgdb..."
        sudo -u postgres pg_dump -Fc $extra_flags "$pgdb" -f "$outfile" 2>/dev/null
        ;;
      *)
        ext="sql"
        outfile="$PG_BACKUP_DIR/pg_${pgdb}_${timestamp}.${ext}"
        info "Criando backup SQL de $pgdb..."
        sudo -u postgres pg_dump $extra_flags "$pgdb" > "$outfile" 2>/dev/null
        ;;
    esac

    if [[ -s "$outfile" ]]; then
      local tamanho
      tamanho=$(du -sh "$outfile" | awk '{print $1}')
      ok "Backup criado com sucesso!"
      item "Banco:   $pgdb"
      item "Arquivo: $outfile"
      item "Tamanho: $tamanho"
      item "Tipo:    ${extra_flags:-completo}"
    else
      sudo rm -f "$outfile" 2>/dev/null
      erro "Falha ao criar o backup! Verifique se o banco '$pgdb' existe."
    fi
  fi

  linha
  pausar
  MenuBackupPostgres
}

RestaurarBancoPostgres(){
  titulo "Restaurar Banco PostgreSQL"

  if ! _pg_listar_backups; then
    pausar; MenuBackupPostgres; return
  fi

  entrada "Nome do arquivo (apenas o nome, sem o caminho):"
  read nome_arquivo
  local backupfile="$PG_BACKUP_DIR/$nome_arquivo"

  if [[ ! -f "$backupfile" ]]; then
    erro "Arquivo não encontrado: $backupfile"
    pausar; MenuBackupPostgres; return
  fi
  sep

  entrada "Nome do banco de destino:"
  read pgdb
  sep

  local banco_existe
  banco_existe=$(sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='$pgdb'" 2>/dev/null)

  if [[ "$banco_existe" == "1" ]]; then
    aviso "O banco '$pgdb' já existe!"
    entrada "Sobrescrever? (drop e recreate) (y/n):"
    read sobreescrever
    if [[ "$sobreescrever" == "y" || "$sobreescrever" == "Y" ]]; then
      info "Removendo banco existente $pgdb..."
      sudo -u postgres psql -c "DROP DATABASE $pgdb;" 2>/dev/null
    else
      aviso "Restauração cancelada."
      pausar; MenuBackupPostgres; return
    fi
  fi

  info "Criando banco $pgdb..."
  sudo -u postgres psql -c "CREATE DATABASE $pgdb;" 2>/dev/null

  sep
  info "Restaurando $nome_arquivo → $pgdb..."

  local ext="${backupfile##*.}"
  local sucesso=false

  case "$ext" in
    gz)
      zcat "$backupfile" | sudo -u postgres psql "$pgdb" &>/dev/null && sucesso=true
      ;;
    dump)
      sudo -u postgres pg_restore -d "$pgdb" "$backupfile" &>/dev/null && sucesso=true
      ;;
    sql)
      sudo -u postgres psql "$pgdb" < "$backupfile" &>/dev/null && sucesso=true
      ;;
  esac

  if $sucesso; then
    ok "Banco '$pgdb' restaurado com sucesso!"
  else
    erro "Ocorreu um erro durante a restauração."
    aviso "Tente verificar os logs do PostgreSQL para mais detalhes."
  fi

  linha
  pausar
  MenuBackupPostgres
}

ListarBackupsPostgres(){
  titulo "Backups Disponíveis"
  _pg_listar_backups || true
  sep
  if ls "$PG_BACKUP_DIR"/*.{sql,gz,dump} 2>/dev/null | head -1 &>/dev/null; then
    local total
    total=$(du -sh "$PG_BACKUP_DIR" 2>/dev/null | awk '{print $1}')
    item "Diretório:    $PG_BACKUP_DIR"
    item "Espaço total: $total"
  fi
  linha
  pausar
  MenuBackupPostgres
}

AgendarBackupPostgres(){
  titulo "Agendar Backup Automático"

  info "O backup será feito via cron e salvo em $PG_BACKUP_DIR"
  echo

  entrada "Nome do banco (ou ALL para todos):"
  read pgdb
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
  outfile_expr="$PG_BACKUP_DIR/pg_${pgdb}_\$(date +%Y%m%d_%H%M%S).sql"

  case "$pgdb" in
    ALL|all) banco_cmd="sudo -u postgres pg_dumpall > $outfile_expr" ;;
    *)       banco_cmd="sudo -u postgres pg_dump $pgdb > $outfile_expr" ;;
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
  ( sudo crontab -l 2>/dev/null | grep -v "pg_backup_${pgdb}"; echo "# pg_backup_${pgdb}"; echo "$cron_line" ) | sudo crontab -
  ok "Backup agendado com sucesso!"
  item "Banco:     $pgdb"
  item "Expressão: $cron_expr"
  item "Destino:   $PG_BACKUP_DIR"
  linha
  pausar
  MenuBackupPostgres
}

LimparBackupsAntigos(){
  titulo "Limpar Backups Antigos"

  if ! _pg_listar_backups; then
    pausar; MenuBackupPostgres; return
  fi

  entrada "Remover backups com mais de quantos dias? (ex: 30):"
  read dias
  sep

  if ! [[ "$dias" =~ ^[0-9]+$ ]]; then
    erro "Valor inválido. Digite apenas números."
    pausar; MenuBackupPostgres; return
  fi

  local count
  count=$(sudo find "$PG_BACKUP_DIR" -name "pg_*.{sql,gz,dump}" -mtime +$dias 2>/dev/null | wc -l)

  if [[ "$count" -eq 0 ]]; then
    aviso "Nenhum backup com mais de $dias dias encontrado."
    pausar; MenuBackupPostgres; return
  fi

  aviso "$count arquivo(s) com mais de $dias dias serão deletados:"
  sudo find "$PG_BACKUP_DIR" -name "pg_*" -mtime +$dias 2>/dev/null | while read f; do
    item "$(basename $f)"
  done
  echo
  entrada "Confirmar exclusão? (y/n):"
  read confirm
  sep

  if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    sudo find "$PG_BACKUP_DIR" -name "pg_*" -mtime +$dias -delete 2>/dev/null
    ok "$count backup(s) removido(s)!"
  else
    aviso "Operação cancelada."
  fi
  linha
  pausar
  MenuBackupPostgres
}

VerAgendamentosBackup(){
  titulo "Agendamentos de Backup (crontab)"
  sep
  sudo crontab -l 2>/dev/null | grep "pg_backup\|pg_dump\|pg_dumpall" || aviso "Nenhum agendamento de backup encontrado."
  linha
  pausar
  MenuBackupPostgres
}

RemoverAgendamentoBackup(){
  titulo "Remover Agendamento de Backup"
  sep
  sudo crontab -l 2>/dev/null | grep -n "pg_backup\|pg_dump\|pg_dumpall" || {
    aviso "Nenhum agendamento encontrado."
    pausar; MenuBackupPostgres; return
  }
  sep
  entrada "Nome do banco do agendamento a remover:"
  read pgdb
  sep
  ( sudo crontab -l 2>/dev/null | grep -v "pg_backup_${pgdb}" | grep -v "pg_dump.*${pgdb}" ) | sudo crontab -
  ok "Agendamento para '$pgdb' removido!"
  linha
  pausar
  MenuBackupPostgres
}
DeletarUsuarioPostgres(){
  titulo "Deletar Usuário PostgreSQL"
  entrada "Nome do usuário a deletar:"
  read pguser
  sep
  info "Deletando usuário $pguser..."
  sudo -u postgres psql -c "DROP USER IF EXISTS $pguser;"
  ok "Usuário $pguser deletado!"
  linha
  pausar
  MenuPostgres
}
DeletarBancoPostgres(){
  titulo "Deletar Banco de Dados PostgreSQL"
  entrada "Nome do banco a deletar:"
  read pgdb
  sep
  aviso "Esta operação é IRREVERSÍVEL! O banco $pgdb será apagado."
  entrada "Confirmar? (y/n):"
  read confirm
  sep
  if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    info "Deletando banco $pgdb..."
    sudo -u postgres psql -c "DROP DATABASE IF EXISTS $pgdb;"
    ok "Banco $pgdb deletado!"
  else
    aviso "Operação cancelada."
  fi
  linha
  pausar
  MenuPostgres
}

# ══════════════════════════════════════════════════════════════════════════════
# MySQL
# ══════════════════════════════════════════════════════════════════════════════

MY_BACKUP_DIR="/var/backups/mysql"


# ── Menu Backup PostgreSQL ──────────────────────────────────────────────────
MenuBackupPostgres(){
  cabecalho "POSTGRESQL — BACKUP" "Douglas S. Santos"
  opcao_menu 1 "Criar Backup (banco único ou todos)"
  opcao_menu 2 "Restaurar Backup"
  opcao_menu 3 "Listar Backups"
  opcao_menu 4 "Limpar Backups Antigos"
  sep
  opcao_menu 5 "Agendar Backup Automático (cron)"
  opcao_menu 6 "Ver Agendamentos"
  opcao_menu 7 "Remover Agendamento"
  echo
  opcao_menu 0 "Voltar ao Menu PostgreSQL"
  echo
  entrada "Escolha uma opção:"
  read opcao
  linha
  case $opcao in
    1) BackupBancoPostgres;;
    2) RestaurarBancoPostgres;;
    3) ListarBackupsPostgres;;
    4) LimparBackupsAntigos;;
    5) AgendarBackupPostgres;;
    6) VerAgendamentosBackup;;
    7) RemoverAgendamentoBackup;;
    0) MenuPostgres;;
    *) erro "Opção inválida!" ; sleep 1 ; MenuBackupPostgres ;;
  esac
}


# ── Menu PostgreSQL ─────────────────────────────────────────────────────────
MenuPostgres(){
  cabecalho "POSTGRESQL" "Douglas S. Santos"
  opcao_menu  1 "Instalar PostgreSQL"
  opcao_menu  2 "Desinstalar PostgreSQL"
  sep
  opcao_menu  3 "Iniciar PostgreSQL"
  opcao_menu  4 "Parar PostgreSQL"
  opcao_menu  5 "Reiniciar PostgreSQL"
  opcao_menu  6 "Status do PostgreSQL"
  sep
  opcao_menu  7 "Criar Usuário"
  opcao_menu  8 "Deletar Usuário"
  opcao_menu  9 "Criar Banco de Dados"
  opcao_menu 10 "Deletar Banco de Dados"
  opcao_menu 11 "Listar Bancos de Dados"
  sep
  opcao_menu 12 "Backup / Restore"
  echo
  opcao_menu  0 "Voltar ao Menu Principal"
  echo
  entrada "Escolha uma opção:"
  read opcao
  linha
  case $opcao in
    1) InstalarPostgres;;
    2) DesinstalarPostgres;;
    3) IniciarPostgres;;
    4) PararPostgres;;
    5) ReiniciarPostgres;;
    6) StatusPostgres;;
    7) CriarUsuarioPostgres;;
    8) DeletarUsuarioPostgres;;
    9) CriarBancoDadosPostgres;;
    10) DeletarBancoPostgres;;
    11) ListarBancosPostgres;;
    12) MenuBackupPostgres;;
    0) Menu;;
    *) erro "Opção inválida!" ; sleep 1 ; MenuPostgres ;;
  esac
}

