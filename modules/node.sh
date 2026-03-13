# ── Node.js ─────────────────────────────────────────────────────────────────
InstalarNVM(){
  titulo "Instalar NVM (Node Version Manager)"
  info "Baixando e instalando NVM v0.34.0..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
  export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  source $HOME/.bashrc
  ok "NVM instalado com sucesso!"
  linha
  pausar
  MenuNode
}
InstalarNodeUltimaVersao(){
  titulo "Instalar Última Versão do Node"
  info "Instalando Node (versão mais recente)..."
  nvm install node
  ok "Node instalado!"
  linha
  pausar
  MenuNode
}
InstalarNodeOutraVersao(){
  titulo "Instalar Versão Específica do Node"
  entrada "Informe a versão desejada (Ex: 18.14.2):"
  read vNode
  sep
  info "Instalando Node v$vNode..."
  nvm install v$vNode
  ok "Node v$vNode instalado!"
  linha
  pausar
  MenuNode
}
InstalarVersaoNodeNativo(){
  titulo "Instalar Node (Repositório Nativo)"
  info "Atualizando repositórios..."
  sudo apt update
  sep
  info "Instalando Node.js..."
  sudo apt install -y nodejs
  sep
  info "Instalando NPM..."
  sudo apt install -y npm
  ok "Node e NPM instalados!"
  linha
  pausar
  MenuNode
}
ListarVersoesNodeInstaladas(){
  titulo "Versões do Node Instaladas"
  nvm ls
  linha
  pausar
  MenuNode
}
ListarVersoesNodeParaInstalacao(){
  titulo "Versões do Node Disponíveis"
  nvm ls-remote
  linha
  pausar
  MenuNode
}
UsarOutraVersaoNode(){
  titulo "Habilitar Versão do Node"
  entrada "Informe a versão desejada (Ex: 18.14.2):"
  read vNode
  sep
  info "Habilitando Node v$vNode..."
  nvm use v$vNode
  ok "Node v$vNode habilitado!"
  linha
  pausar
  MenuNode
}
UsarUltimaVersaoNode(){
  titulo "Habilitar Última Versão do Node"
  info "Habilitando versão mais recente..."
  nvm use node
  ok "Versão mais recente habilitada!"
  linha
  pausar
  MenuNode
}
DesinstalarNode(){
  titulo "Desinstalar Versão do Node"
  entrada "Informe a versão a desinstalar (Ex: 18.14.2):"
  read vNode
  sep
  info "Desinstalando Node v$vNode..."
  nvm uninstall v$vNode
  ok "Node v$vNode removido!"
  linha
  pausar
  MenuNode
}
VersaoAtivaDoNode(){
  titulo "Versão Ativa do Node (NVM)"
  nvm current
  linha
  pausar
  MenuNode
}
VersaoAtivaDoNodeNativo(){
  titulo "Versão do Node (Nativo)"
  NODE=$(node -v 2>/dev/null || echo "não instalado")
  NPM=$(npm -v 2>/dev/null || echo "não instalado")
  item "Node:  $NODE"
  item "NPM:   v$NPM"
  linha
  pausar
  MenuNode
}


# ── Git ─────────────────────────────────────────────────────────────────────
ClonarRepositorioGit(){
  titulo "Clonar Repositório Git"
  entrada "Nome do domínio (sem http://):"
  read dominio
  sep
  entrada "URL do repositório Git:"
  read repositorio
  sep
  entrada "Branch (deixe vazio para padrão):"
  read branch
  sep
  info "Limpando /var/www/$dominio..."
  sudo rm -R /var/www/$dominio/* 2>/dev/null
  sep
  info "Clonando repositório..."
  if [[ -z "$branch" ]]; then
    git clone $repositorio /var/www/$dominio
  else
    git clone -b $branch $repositorio /var/www/$dominio
  fi
  ok "Repositório clonado!"
  sep
  cd "/var/www/$dominio/"
  info "Rodando composer install..."
  composer install
  sep
  info "Rodando npm install..."
  npm install
  ok "Dependências instaladas!"
  linha
  pausar
  Menu
}


# ── Menu Node ───────────────────────────────────────────────────────────────
MenuNode(){
  cabecalho "NODE.JS" "Douglas S. Santos"
  opcao_menu  1 "Instalar Node Version Manager (NVM)"
  opcao_menu  2 "Instalar Node (Repositório Nativo)"
  opcao_menu  3 "Instalar última versão do Node"
  opcao_menu  4 "Instalar outra versão do Node"
  sep
  opcao_menu  5 "Versões do Node disponíveis (NVM)"
  opcao_menu  6 "Versões do Node instaladas"
  sep
  opcao_menu  7 "Habilitar última versão do Node"
  opcao_menu  8 "Habilitar outra versão do Node"
  opcao_menu  9 "Versão ativa do Node (NVM)"
  sep
  opcao_menu 10 "Versão ativa do Node (Nativo)"
  opcao_menu 11 "Desinstalar versão do Node"
  echo
  opcao_menu  0 "Voltar ao Menu Principal"
  echo
  entrada "Escolha uma opção:"
  read opcao
  linha
  case $opcao in
    1) InstalarNVM;;
    2) InstalarVersaoNodeNativo;;
    3) InstalarNodeUltimaVersao;;
    4) InstalarNodeOutraVersao;;
    5) ListarVersoesNodeParaInstalacao;;
    6) ListarVersoesNodeInstaladas;;
    7) UsarUltimaVersaoNode;;
    8) UsarOutraVersaoNode;;
    9) VersaoAtivaDoNode;;
    10) VersaoAtivaDoNodeNativo;;
    11) DesinstalarNode;;
    0) Menu;;
    *) erro "Opção inválida!" ; sleep 1 ; MenuNode ;;
  esac
}

