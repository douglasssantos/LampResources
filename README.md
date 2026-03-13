<div align="center">

# 🛠️ Lamp Resources

**Shell script interativo para gerenciamento completo de ambientes LAMP no Linux**

[![Shell Script](https://img.shields.io/badge/Shell_Script-bash-4EAA25?style=flat-square&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Linux](https://img.shields.io/badge/Linux-Ubuntu%20%2F%20Debian-E95420?style=flat-square&logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![License](https://img.shields.io/badge/Licença-MIT-blue?style=flat-square)](LICENSE)
[![Stars](https://img.shields.io/github/stars/douglasssantos/LampResources?style=flat-square&color=yellow)](https://github.com/douglasssantos/LampResources/stargazers)

</div>

---

## 📋 Sobre

O **Lamp Resources** é um script interativo em Bash com interface visual colorida no terminal, criado para agilizar o dia a dia de desenvolvedores e administradores de servidores Linux.

Com ele você gerencia todo o seu ambiente de desenvolvimento e produção a partir de menus simples e organizados — sem precisar decorar comandos.

---

## ✨ Funcionalidades

### 🌐 Apache / LAMP
| | |
|---|---|
| Instalar / Desinstalar o LAMP completo | Adicionar domínios online com SSL automático (Certbot) |
| Adicionar domínios locais de desenvolvimento | Remover domínios do vHost |
| Aplicar permissões em domínios | Renovar certificados SSL |
| Clonar / Limpar sites | Listar domínios ativos |
| **Backup de sites** (`.tar.gz` com timestamp) | **Restaurar backups de sites** |
| Ver logs de erro e acesso do Apache | Redefinir configurações do Apache |

### 🐘 PHP
| | |
|---|---|
| Instalar versão específica ou mais recente | Listar versões instaladas |
| Habilitar / Desabilitar versões | Desinstalar versões |
| Adicionar PPA `ondrej/php` | **Configurar `php.ini`** (memory, upload, timeout) |

### 🟢 Node.js
| | |
|---|---|
| Instalar NVM (Node Version Manager) | Instalar Node pelo repositório nativo |
| Instalar última versão ou versão específica | Listar versões instaladas e disponíveis |
| Habilitar versão específica | Desinstalar versões |

### 🐘 PostgreSQL
| | |
|---|---|
| Instalar / Desinstalar | Iniciar / Parar / Reiniciar / Status |
| Criar / Deletar usuários | Criar / Deletar bancos de dados |
| Listar bancos de dados | **Submenu completo de Backup / Restore** |

#### 💾 Backup PostgreSQL
| | |
|---|---|
| Backup em SQL, `.sql.gz` ou `.dump` | Backup de banco único ou **todos os bancos** |
| Restaurar com detecção automática de formato | Listar backups com tamanho e data |
| Limpar backups antigos (por dias) | **Agendar backup automático via cron** |
| Ver e remover agendamentos | — |

### 📦 Redis
| | |
|---|---|
| Instalar / Desinstalar | Iniciar / Parar / Reiniciar / Status |
| Informações do servidor | Testar conexão (`PING`) |
| Limpar cache (`FLUSHALL`) | — |

### 🖥️ Sistema
| | |
|---|---|
| Informações do servidor (SO, CPU, RAM, disco, IP) | Status de todos os serviços (Apache, PostgreSQL, Redis) |
| Atualizar o sistema (`apt upgrade`) | Ver portas em uso |
| Limpar logs do Apache | — |

### 🔧 Outros
- Instalar **Composer**
- Clonar **repositório Git** com `composer install` e `npm install` automáticos

---

## 🚀 Instalação

```bash
# 1. Clone o repositório
git clone https://github.com/douglasssantos/LampResources.git

# 2. Acesse a pasta
cd LampResources/

# 3. Dê permissão ao instalador
sudo chmod +x ./install

# 4. Execute o instalador
sudo ./install
```

> Após a instalação, o Lamp estará disponível globalmente.

---

## ▶️ Uso

```bash
sudo lamp
```

Para **atualizar** ou **desinstalar**, execute o instalador novamente:

```bash
sudo ./install
```

---

## 📦 Requisitos

- Linux (Ubuntu 20.04+ / Debian 11+)
- Bash 4+
- Acesso `sudo`
- Conexão com a internet (para instalações)

---

## 📁 Estrutura

```
LampResources/
├── lamp       # Script principal
└── install    # Instalador / Atualizador / Desinstalador
```

---

## 🤝 Contribuindo

Contribuições são bem-vindas! Sinta-se à vontade para abrir uma _issue_ ou _pull request_.

1. Fork o projeto
2. Crie sua branch: `git checkout -b feature/minha-feature`
3. Commit: `git commit -m "feat: minha nova feature"`
4. Push: `git push origin feature/minha-feature`
5. Abra um Pull Request

---

## ⭐ Apoie o projeto

Se este projeto te ajudou, **deixe uma estrela** no repositório! Isso ajuda o projeto a alcançar mais pessoas.

[![GitHub Stars](https://img.shields.io/github/stars/douglasssantos/LampResources?style=for-the-badge&color=yellow)](https://github.com/douglasssantos/LampResources/stargazers)

---

## 📬 Contatos

<table>
  <tr>
    <td><strong>E-mail</strong></td>
    <td><a href="mailto:douglassantos2127@gmail.com">douglassantos2127@gmail.com</a></td>
  </tr>
  <tr>
    <td><strong>LinkedIn</strong></td>
    <td><a href="https://www.linkedin.com/in/douglas-da-silva-santos/" target="_blank">linkedin.com/in/douglas-da-silva-santos</a></td>
  </tr>
  <tr>
    <td><strong>GeekHunter</strong></td>
    <td><a href="https://app.geekhunter.com.br/empresas/buscar-candidatos" target="_blank">Ver perfil</a></td>
  </tr>
</table>

---

<div align="center">
  <sub>Feito com ❤️ por <a href="https://github.com/douglasssantos">Douglas S. Santos</a></sub>
</div>
