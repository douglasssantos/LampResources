# ── Redis ───────────────────────────────────────────────────────────────────
InstalarRedis(){
  titulo "Instalar Redis"
  info "Atualizando repositórios..."
  sudo apt update
  sep
  info "Instalando Redis Server..."
  sudo apt install -y redis-server
  sep
  info "Habilitando Redis no boot..."
  sudo systemctl enable redis-server.service
  sudo systemctl start redis-server.service
  ok "Redis instalado e iniciado com sucesso!"
  linha
  pausar
  MenuRedis
}
DesinstalarRedis(){
  titulo "Desinstalar Redis"
  info "Parando e removendo Redis..."
  sudo systemctl stop redis-server.service
  sudo apt remove -y redis-server && sudo apt purge -y redis-server
  sudo apt autoremove -y
  ok "Redis desinstalado com sucesso!"
  linha
  pausar
  MenuRedis
}
IniciarRedis(){
  titulo "Iniciar Redis"
  info "Iniciando Redis..."
  sudo systemctl start redis-server.service
  ok "Redis iniciado!"
  linha
  pausar
  MenuRedis
}
PararRedis(){
  titulo "Parar Redis"
  info "Parando Redis..."
  sudo systemctl stop redis-server.service
  ok "Redis parado!"
  linha
  pausar
  MenuRedis
}
ReiniciarRedis(){
  titulo "Reiniciar Redis"
  info "Reiniciando Redis..."
  sudo systemctl restart redis-server.service
  ok "Redis reiniciado!"
  linha
  pausar
  MenuRedis
}
StatusRedis(){
  titulo "Status do Redis"
  sudo systemctl status redis-server.service
  linha
  pausar
  MenuRedis
}
InfoRedis(){
  titulo "Informações do Redis"
  redis-cli info server 2>/dev/null || erro "Redis não está rodando ou não está instalado."
  linha
  pausar
  MenuRedis
}
TestarRedis(){
  titulo "Teste de Conexão Redis"
  result=$(redis-cli ping 2>/dev/null)
  if [[ "$result" == "PONG" ]]; then
    ok "Redis respondeu: PONG — conexão OK!"
  else
    erro "Redis não respondeu. Verifique se o serviço está rodando."
  fi
  linha
  pausar
  MenuRedis
}
LimparCacheRedis(){
  titulo "Limpar Cache do Redis"
  aviso "Isso apagará TODOS os dados em cache!"
  entrada "Confirmar? (y/n):"
  read confirm
  sep
  if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    redis-cli FLUSHALL
    ok "Cache do Redis limpo com sucesso!"
  else
    aviso "Operação cancelada."
  fi
  linha
  pausar
  MenuRedis
}


# ── Menu Redis ──────────────────────────────────────────────────────────────
MenuRedis(){
  cabecalho "REDIS" "Douglas S. Santos"
  opcao_menu 1 "Instalar Redis"
  opcao_menu 2 "Desinstalar Redis"
  sep
  opcao_menu 3 "Iniciar Redis"
  opcao_menu 4 "Parar Redis"
  opcao_menu 5 "Reiniciar Redis"
  opcao_menu 6 "Status do Redis"
  sep
  opcao_menu 7 "Informações do Redis"
  opcao_menu 8 "Testar Conexão"
  opcao_menu 9 "Limpar Cache"
  echo 
  opcao_menu 0 "Voltar ao Menu Principal"
  echo
  sep
  entrada "Escolha uma opção:"
  read opcao
  linha
  case $opcao in
    1) InstalarRedis;;
    2) DesinstalarRedis;;
    3) IniciarRedis;;
    4) PararRedis;;
    5) ReiniciarRedis;;
    6) StatusRedis;;
    7) InfoRedis;;
    8) TestarRedis;;
    9) LimparCacheRedis;;
    0) Menu;;
    *) erro "Opção inválida!" ; sleep 1 ; MenuRedis ;;
  esac
}

