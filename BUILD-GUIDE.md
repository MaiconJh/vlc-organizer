# 🎬 VLC Organizer - Guia de Build

## 📋 Opções de Compilação

Agora você tem **duas opções** de build para o VLC Organizer:

### 🪶 Versão Leve (~150KB)
```batch
.\build-light.bat
```

**Características:**
- ✅ Arquivo muito pequeno (~150KB)
- ⚠️ Requer .NET 8.0 Runtime no computador de destino
- 🚀 Build rápido (2-3 segundos)
- 📦 Saída: `bin\VLCOrganizer.Installer.exe`

### 🚀 Versão Standalone (~30MB)
```batch
.\build-standalone.bat
```

**Características:**
- ✅ Arquivo único e independente
- ✅ NÃO requer .NET no computador de destino
- 📦 Inclui todas as dependências
- 🐌 Build mais lento (15-20 segundos)
- 📁 Saída: `bin-standalone\VLCOrganizer.Installer.exe`

## 🎯 Qual Escolher?

### Use a **Versão Leve** se:
- Você tem controle sobre os computadores onde será instalado
- Os computadores já têm ou podem instalar .NET 8.0
- Você quer economia de espaço em disco
- Você vai distribuir internamente

### Use a **Versão Standalone** se:
- Você vai distribuir para usuários externos
- Não quer depender de instalações adicionais
- Prefere um arquivo que "funciona em qualquer lugar"
- O tamanho não é um problema

## 📥 Download do .NET Runtime

Se optar pela versão leve, os usuários precisarão do .NET 8.0 Runtime:
- **Desktop Runtime**: https://dotnet.microsoft.com/download/dotnet/8.0

## 🔧 Como Usar o Instalador

1. **Execute como Administrador** (obrigatório para registry)
2. **Selecione o local de instalação** (padrão: `C:\Program Files\VLC Organizer`)
3. **Clique em "Instalar Menu de Contexto"**
4. **Teste**: Clique com botão direito em uma pasta com vídeos

## 🗑️ Desinstalação

O instalador também permite desinstalar:
1. Execute o instalador novamente
2. Clique em "Desinstalar Menu de Contexto"
3. Opcionalmente, remova os arquivos da pasta de instalação

## 🎬 Funcionamento

Após a instalação, você terá uma nova opção **"Organizar com VLC"** no menu de contexto das pastas. Esta opção executa o script PowerShell que:

- 🔍 Busca vídeos na pasta selecionada
- 🎵 Cria playlist ordenada
- 🚀 Abre diretamente no VLC Player
- ⚙️ Usa configurações otimizadas para reprodução

---

**💡 Dica**: Para uso pessoal, recomendo a versão leve. Para distribuição, use a standalone!