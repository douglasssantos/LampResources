# ── MongoDB ──────────────────────────────────────────────────────────────────
MONGO_BACKUP_DIR="/var/backups/mongodb"

_mongo_garantir_dir(){
  sudo mkdir -p "$MONGO_BACKUP_DIR"
}

_mongo_listar_backups(){
  local found=false
  for f in "$MONGO_BACKUP_DIR"/mongo_*; do
    [[ -e "$f" ]] && found=true && break
  done
  if $found; then
    echo
    printf "  ${CINZA}%-50s %8s  %s${RESET}\n" "Arquivo/Diretório" "Tamanho" "Data"
    sep
    for f in $(ls -td "$MONGO_BACKUP_DIR"/mongo_* 2>/dev/null); do
      [[ -e "$f" ]] || continue
      local nome tamanho data
      nome=$(basename "$f")
      tamanho=$(du -sh "$f" 2>/dev/null | awk '{print $1}')
      data=$(stat -c %y "$f" 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1 || date -r "$f" "+%d/%m/%Y %H:%M" 2>/dev/null)
      printf "  ${BRANCO}%-50s${RESET} ${AMARELO_CLARO}%8s${RESET}  ${CINZA}%s${RESET}\n" "$nome" "$tamanho" "$data"
    done
    echo
  else
    aviso "Nenhum backup encontrado em $MONGO_BACKUP_DIR"
    return 1
  fi
}

_mongo_listar_databases(){
  mongosh --quiet --eval "db.adminCommand('listDatabases').databases.forEach(d => print(d.name))" 2>/dev/null || \
  mongo --quiet --eval "db.adminCommand('listDatabases').databases.forEach(function(d){print(d.name)})" 2>/dev/null
}

InstalarMongoDB(){
  titulo "Instalar MongoDB"
  info "Verificando versão do Ubuntu..."
  local codename
  codename=$(lsb_release -cs 2>/dev/null || . /etc/os-release 2>/dev/null && echo "$VERSION_CODENAME")
  if [[ -z "$codename" ]]; then
    erro "Não foi possível detectar a versão do Ubuntu."
    pausar; MenuMongoDB; return
  fi
  sep
  info "Adicionando repositório oficial MongoDB..."
  curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor 2>/dev/null
  echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu ${codename}/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
  sep
  info "Atualizando repositórios..."
  sudo apt update
  sep
  info "Instalando mongodb-org, mongodb-database-tools e mongosh..."
  sudo apt install -y mongodb-org mongodb-database-tools mongodb-mongosh
  sep
  info "Habilitando MongoDB no boot..."
  sudo systemctl start mongod
  sudo systemctl enable mongod
  ok "MongoDB instalado e iniciado com sucesso!"
  linha
  pausar
  MenuMongoDB
}

DesinstalarMongoDB(){
  titulo "Desinstalar MongoDB"
  aviso "Todos os dados serão removidos permanentemente!"
  entrada "Confirmar? (y/n):"
  read confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    aviso "Operação cancelada."
    pausar; MenuMongoDB; return
  fi
  sep
  info "Parando e removendo MongoDB..."
  sudo systemctl stop mongod 2>/dev/null
  sudo apt --purge remove -y mongodb-org mongodb-org-* mongodb-database-tools
  sudo rm -rf /var/lib/mongodb /var/log/mongodb /etc/mongod.conf
  sudo rm -f /etc/apt/sources.list.d/mongodb-org-*.list
  sep
  info "Limpando resíduos..."
  sudo apt autoclean -y && sudo apt --purge autoremove -y
  ok "MongoDB desinstalado com sucesso!"
  linha
  pausar
  MenuMongoDB
}

IniciarMongoDB(){
  titulo "Iniciar MongoDB"
  info "Iniciando MongoDB..."
  sudo systemctl start mongod
  ok "MongoDB iniciado!"
  linha
  pausar
  MenuMongoDB
}

PararMongoDB(){
  titulo "Parar MongoDB"
  info "Parando MongoDB..."
  sudo systemctl stop mongod
  ok "MongoDB parado!"
  linha
  pausar
  MenuMongoDB
}

ReiniciarMongoDB(){
  titulo "Reiniciar MongoDB"
  info "Reiniciando MongoDB..."
  sudo systemctl restart mongod
  ok "MongoDB reiniciado!"
  linha
  pausar
  MenuMongoDB
}

StatusMongoDB(){
  titulo "Status do MongoDB"
  sudo systemctl status mongod
  linha
  pausar
  MenuMongoDB
}

ListarBancosMongoDB(){
  titulo "Bancos de Dados no MongoDB"
  info "Databases disponíveis:"
  sep
  _mongo_listar_databases | while read -r db; do
    [[ -n "$db" ]] && item "$db"
  done
  sep
  linha
  pausar
  MenuMongoDB
}

BackupBancoMongoDB(){
  titulo "Backup de Banco MongoDB"

  _mongo_garantir_dir

  info "Databases disponíveis:"
  sep
  _mongo_listar_databases | while read -r db; do
    [[ -n "$db" ]] && item "$db"
  done
  sep

  entrada "Nome do banco (ou ALL para todos):"
  read mongodb
  echo

  entrada "Formato — [1] Diretório (BSON)  [2] Arquivo .archive  [3] Arquivo .archive.gz:"
  read fmt
  echo

  local timestamp
  timestamp=$(date +"%Y%m%d_%H%M%S")
  sep

  if [[ "$mongodb" == "ALL" || "$mongodb" == "all" ]]; then
    local outdir="$MONGO_BACKUP_DIR/mongo_all_${timestamp}"
    info "Criando backup de TODOS os bancos..."
    if sudo mongodump --out "$outdir" 2>/dev/null; then
      local tamanho; tamanho=$(du -sh "$outdir" 2>/dev/null | awk '{print $1}')
      ok "Backup completo criado!"
      item "Diretório: $outdir"
      item "Tamanho:   $tamanho"
    else
      sudo rm -rf "$outdir" 2>/dev/null
      erro "Falha ao criar o backup! Verifique se o MongoDB está rodando."
    fi
  else
    case "$fmt" in
      2)
        local outfile="$MONGO_BACKUP_DIR/mongo_${mongodb}_${timestamp}.archive"
        info "Criando backup em arquivo .archive de $mongodb..."
        if sudo mongodump --db "$mongodb" --archive="$outfile" 2>/dev/null; then
          local tamanho; tamanho=$(du -sh "$outfile" 2>/dev/null | awk '{print $1}')
          ok "Backup criado com sucesso!"
          item "Banco:     $mongodb"
          item "Arquivo:   $outfile"
          item "Tamanho:   $tamanho"
        else
          sudo rm -f "$outfile" 2>/dev/null
          erro "Falha ao criar o backup! Verifique se o banco '$mongodb' existe."
        fi
        ;;
      3)
        local outfile="$MONGO_BACKUP_DIR/mongo_${mongodb}_${timestamp}.archive.gz"
        info "Criando backup comprimido de $mongodb..."
        if sudo mongodump --db "$mongodb" --archive="$outfile" --gzip 2>/dev/null; then
          local tamanho; tamanho=$(du -sh "$outfile" 2>/dev/null | awk '{print $1}')
          ok "Backup criado com sucesso!"
          item "Banco:     $mongodb"
          item "Arquivo:   $outfile"
          item "Tamanho:   $tamanho"
        else
          sudo rm -f "$outfile" 2>/dev/null
          erro "Falha ao criar o backup! Verifique se o banco '$mongodb' existe."
        fi
        ;;
      *)
        local outdir="$MONGO_BACKUP_DIR/mongo_${mongodb}_${timestamp}"
        info "Criando backup em diretório BSON de $mongodb..."
        if sudo mongodump --db "$mongodb" --out "$outdir" 2>/dev/null; then
          local tamanho; tamanho=$(du -sh "$outdir" 2>/dev/null | awk '{print $1}')
          ok "Backup criado com sucesso!"
          item "Banco:     $mongodb"
          item "Diretório: $outdir"
          item "Tamanho:   $tamanho"
        else
          sudo rm -rf "$outdir" 2>/dev/null
          erro "Falha ao criar o backup! Verifique se o banco '$mongodb' existe."
        fi
        ;;
    esac
  fi

  linha
  pausar
  MenuBackupMongoDB
}

RestaurarBancoMongoDB(){
  titulo "Restaurar Backup MongoDB"

  _mongo_garantir_dir

  if ! _mongo_listar_backups; then
    pausar; MenuBackupMongoDB; return
  fi

  entrada "Caminho do backup (diretório dump/, arquivo .archive ou .archive.gz):"
  read backup_path
  echo

  if [[ ! -e "$backup_path" ]]; then
    backup_path="$MONGO_BACKUP_DIR/$backup_path"
  fi
  if [[ ! -e "$backup_path" ]]; then
    erro "Arquivo ou diretório não encontrado: $backup_path"
    pausar; MenuBackupMongoDB; return
  fi

  entrada "Nome do banco de destino (deixe vazio para restaurar no banco original):"
  read db_dest
  echo

  sep
  info "Restaurando backup..."

  local sucesso=false
  if [[ -d "$backup_path" ]]; then
    if [[ -n "$db_dest" ]]; then
      local db_subdir
      db_subdir=$(find "$backup_path" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -1)
      [[ -n "$db_subdir" ]] && sudo mongorestore --db "$db_dest" "$db_subdir" 2>/dev/null && sucesso=true
      [[ -z "$db_subdir" ]] && sudo mongorestore --db "$db_dest" "$backup_path" 2>/dev/null && sucesso=true
    else
      sudo mongorestore "$backup_path" 2>/dev/null && sucesso=true
    fi
  elif [[ "$backup_path" == *.gz ]]; then
    if [[ -n "$db_dest" ]]; then
      sudo mongorestore --archive="$backup_path" --gzip --nsFrom="*.*" --nsTo="${db_dest}.*" 2>/dev/null && sucesso=true
    else
      sudo mongorestore --archive="$backup_path" --gzip 2>/dev/null && sucesso=true
    fi
  else
    if [[ -n "$db_dest" ]]; then
      sudo mongorestore --archive="$backup_path" --nsFrom="*.*" --nsTo="${db_dest}.*" 2>/dev/null && sucesso=true
    else
      sudo mongorestore --archive="$backup_path" 2>/dev/null && sucesso=true
    fi
  fi

  if $sucesso; then
    ok "Backup restaurado com sucesso!"
  else
    erro "Ocorreu um erro durante a restauração."
    aviso "Verifique se o MongoDB está rodando e tente novamente."
  fi

  linha
  pausar
  MenuBackupMongoDB
}

ListarBackupsMongoDB(){
  titulo "Backups MongoDB Disponíveis"
  _mongo_listar_backups || true
  sep
  if [[ -d "$MONGO_BACKUP_DIR" ]]; then
    local total; total=$(du -sh "$MONGO_BACKUP_DIR" 2>/dev/null | awk '{print $1}')
    item "Diretório:    $MONGO_BACKUP_DIR"
    item "Espaço total: $total"
  fi
  linha
  pausar
  MenuBackupMongoDB
}

AgendarBackupMongoDB(){
  titulo "Agendar Backup Automático MongoDB"

  info "O backup será feito via cron e salvo em $MONGO_BACKUP_DIR"
  echo

  entrada "Nome do banco (ou ALL para todos):"
  read mongodb
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

  local cron_expr out_expr
  case "$mongodb" in
    ALL|all)
      out_expr="$MONGO_BACKUP_DIR/mongo_all_\$(date +%Y%m%d_%H%M%S)"
      cron_expr="mongodump --out $out_expr"
      ;;
    *)
      out_expr="$MONGO_BACKUP_DIR/mongo_${mongodb}_\$(date +%Y%m%d_%H%M%S).archive.gz"
      cron_expr="mongodump --db $mongodb --archive=$out_expr --gzip"
      ;;
  esac

  case "$freq" in
    1) cron_expr="0 3 * * * $cron_expr" ;;
    2) cron_expr="0 3 * * 0 $cron_expr" ;;
    3) cron_expr="0 */6 * * * $cron_expr" ;;
    4)
      entrada "Digite a expressão cron (ex: 0 4 * * 1):"
      read cron_time
      cron_expr="$cron_time $cron_expr"
      ;;
    *) cron_expr="0 3 * * * $cron_expr" ;;
  esac

  sep
  info "Adicionando ao crontab do root..."
  ( sudo crontab -l 2>/dev/null | grep -v "mongo_backup_${mongodb}"; echo "# mongo_backup_${mongodb}"; echo "$cron_expr" ) | sudo crontab -
  ok "Backup agendado com sucesso!"
  item "Banco:     $mongodb"
  item "Destino:   $MONGO_BACKUP_DIR"
  linha
  pausar
  MenuBackupMongoDB
}

LimparBackupsAntigosMongoDB(){
  titulo "Limpar Backups Antigos MongoDB"

  if ! _mongo_listar_backups; then
    pausar; MenuBackupMongoDB; return
  fi

  entrada "Remover backups com mais de quantos dias? (ex: 30):"
  read dias
  sep

  if ! [[ "$dias" =~ ^[0-9]+$ ]]; then
    erro "Valor inválido. Digite apenas números."
    pausar; MenuBackupMongoDB; return
  fi

  local count
  count=$(sudo find "$MONGO_BACKUP_DIR" -name "mongo_*" -mtime +$dias 2>/dev/null | wc -l)

  if [[ "$count" -eq 0 ]]; then
    aviso "Nenhum backup com mais de $dias dias encontrado."
    pausar; MenuBackupMongoDB; return
  fi

  aviso "$count item(ns) com mais de $dias dias serão deletados:"
  sudo find "$MONGO_BACKUP_DIR" -name "mongo_*" -mtime +$dias 2>/dev/null | while read -r f; do
    item "$(basename "$f")"
  done
  echo
  entrada "Confirmar exclusão? (y/n):"
  read confirm
  sep

  if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    sudo find "$MONGO_BACKUP_DIR" -name "mongo_*" -mtime +$dias -exec rm -rf {} \; 2>/dev/null
    ok "$count backup(s) removido(s)!"
  else
    aviso "Operação cancelada."
  fi
  linha
  pausar
  MenuBackupMongoDB
}

VerAgendamentosBackupMongoDB(){
  titulo "Agendamentos de Backup MongoDB (crontab)"
  sep
  sudo crontab -l 2>/dev/null | grep "mongo_backup\|mongodump" || aviso "Nenhum agendamento de backup MongoDB encontrado."
  linha
  pausar
  MenuBackupMongoDB
}

RemoverAgendamentoBackupMongoDB(){
  titulo "Remover Agendamento de Backup MongoDB"
  sep
  sudo crontab -l 2>/dev/null | grep "mongo_backup\|mongodump" || {
    aviso "Nenhum agendamento encontrado."
    pausar; MenuBackupMongoDB; return
  }
  sep
  entrada "Nome do banco do agendamento a remover:"
  read mongodb
  sep
  ( sudo crontab -l 2>/dev/null | grep -v "mongo_backup_${mongodb}" | grep -v "mongodump.*${mongodb}" ) | sudo crontab -
  ok "Agendamento para '$mongodb' removido!"
  linha
  pausar
  MenuBackupMongoDB
}


# ── Menu Backup MongoDB ──────────────────────────────────────────────────────
MenuBackupMongoDB(){
  cabecalho "MONGODB — BACKUP" "Douglas S. Santos"
  opcao_menu 1 "Criar Backup (banco único ou todos)"
  opcao_menu 2 "Restaurar Backup"
  opcao_menu 3 "Listar Backups"
  opcao_menu 4 "Limpar Backups Antigos"
  sep
  opcao_menu 5 "Agendar Backup Automático (cron)"
  opcao_menu 6 "Ver Agendamentos"
  opcao_menu 7 "Remover Agendamento"
  echo
  opcao_menu 0 "Voltar ao Menu MongoDB"
  echo
  entrada "Escolha uma opção:"
  read opcao
  linha
  case $opcao in
    1) BackupBancoMongoDB;;
    2) RestaurarBancoMongoDB;;
    3) ListarBackupsMongoDB;;
    4) LimparBackupsAntigosMongoDB;;
    5) AgendarBackupMongoDB;;
    6) VerAgendamentosBackupMongoDB;;
    7) RemoverAgendamentoBackupMongoDB;;
    0) MenuMongoDB;;
    *) erro "Opção inválida!" ; sleep 1 ; MenuBackupMongoDB ;;
  esac
}


# ── Menu MongoDB ─────────────────────────────────────────────────────────────
MenuMongoDB(){
  cabecalho "MONGODB" "Douglas S. Santos"
  opcao_menu  1 "Instalar MongoDB"
  opcao_menu  2 "Desinstalar MongoDB"
  sep
  opcao_menu  3 "Iniciar MongoDB"
  opcao_menu  4 "Parar MongoDB"
  opcao_menu  5 "Reiniciar MongoDB"
  opcao_menu  6 "Status do MongoDB"
  sep
  opcao_menu  7 "Listar Bancos de Dados"
  sep
  opcao_menu  8 "Backup / Restore"
  echo
  opcao_menu  0 "Voltar ao Menu Principal"
  echo
  entrada "Escolha uma opção:"
  read opcao
  linha
  case $opcao in
    1)  InstalarMongoDB;;
    2)  DesinstalarMongoDB;;
    3)  IniciarMongoDB;;
    4)  PararMongoDB;;
    5)  ReiniciarMongoDB;;
    6)  StatusMongoDB;;
    7)  ListarBancosMongoDB;;
    8)  MenuBackupMongoDB;;
    0)  Menu;;
    *) erro "Opção inválida!" ; sleep 1 ; MenuMongoDB ;;
  esac
}
