# 🎬 VLC Organizer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![.NET](https://img.shields.io/badge/.NET-8.0-purple.svg)](https://dotnet.microsoft.com/download/dotnet/8.0)
[![Platform](https://img.shields.io/badge/Platform-Windows-blue.svg)](https://www.microsoft.com/windows)

> **Organizador inteligente de vídeos para VLC Player com menu de contexto do Windows**

## 🚀 Download Rápido

### 📥 Releases Disponíveis

| Versão | Tamanho | Requisitos | Download |
|--------|---------|------------|----------|
| **🪶 Leve** | ~150KB | .NET 8.0 Runtime | [📁 v1.0-light](../../releases/tag/v1.0-light) |
| **🚀 Standalone** | ~30MB | Nenhum | [📁 v1.0-standalone](../../releases/tag/v1.0-standalone) |

## 📋 O que faz?

O VLC Organizer adiciona uma opção **"Organizar com VLC"** no menu de contexto das pastas do Windows. Ao clicar:

1. 🔍 **Busca** todos os vídeos na pasta
2. 🎵 **Cria** uma playlist ordenada
3. 🚀 **Abre** diretamente no VLC Player
4. ⚙️ **Configura** reprodução otimizada

## 🎯 Qual Versão Escolher?

### 🪶 **Versão Leve** (Recomendada)
- ✅ Arquivo pequeno (~150KB)
- ⚠️ Requer [.NET 8.0 Runtime](https://dotnet.microsoft.com/download/dotnet/8.0)
- 🎯 Ideal para uso pessoal/interno

### 🚀 **Versão Standalone**
- ✅ Funciona sem instalações adicionais
- 📦 Arquivo único e independente
- 🎯 Ideal para distribuição externa

## � Instalação

1. **Baixe** a versão desejada nos releases
2. **Execute como Administrador** (obrigatório)
3. **Selecione** o local de instalação
4. **Clique** em "Instalar Menu de Contexto"
5. **Teste** em uma pasta com vídeos!

## 🎬 Como Usar

Após a instalação:

1. Navegue até uma pasta com vídeos
2. **Clique com botão direito** na pasta
3. Selecione **"Organizar com VLC"**
4. O VLC abrirá com todos os vídeos organizados!

## 📁 Estrutura do Projeto

```
VLC-Organizer/
├── src/                           # Scripts PowerShell
│   ├── VLC-Organizer-Final.ps1   # Script principal
│   └── VLC-Organizer-Silent.ps1  # Versão silenciosa
├── config/                        # Configurações
│   └── settings.json             # Configurações do sistema
├── VLCOrganizer.Installer/       # Código fonte do instalador
│   ├── MainForm.cs               # Interface do instalador
│   ├── Program.cs                # Ponto de entrada
│   └── *.csproj                  # Projeto C#
├── bin/                          # Executáveis compilados
└── logs/                         # Arquivos de log
```

## 🔧 Instalação

### Usando o Instalador Independente (Recomendado)

1. **Execute o instalador**:
   - Baixe/compile `VLCOrganizer.Installer.exe`
   - Clique com botão direito → "Executar como administrador"

2. **Personalize a instalação**:
   - Escolha onde instalar (padrão: `C:\Program Files\VLC Organizer`)
   - Clique em "📂 Procurar" para alterar o local

3. **Instale**:
   - Clique em "📥 Instalar Menu de Contexto"
   - Os arquivos serão extraídos automaticamente
   - Menu de contexto será registrado

> ✨ **Instalador Independente**: O arquivo `.exe` contém tudo que é necessário - não precisa de arquivos externos!

### Método 2: Registro Manual

Se preferir registrar manualmente no registro do Windows:

```powershell
# Execute PowerShell como Administrador
$installPath = "C:\caminho\para\VLC-Organizer"
$scriptPath = "$installPath\src\VLC-Organizer-Final.ps1"
$command = "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`" -PlaylistPath `"%V`""

# Registrar menu de contexto
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\OrganizarVLC" /ve /t REG_SZ /d "🎬 Organizar esta Pasta com VLC" /f
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\OrganizarVLC" /v "Icon" /t REG_SZ /d "shell32.dll,23" /f
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\OrganizarVLC\command" /ve /t REG_SZ /d "$command" /f
```

## 🎯 Como Usar

1. **Organize seus vídeos** em pastas (preferencialmente por série)
2. **Clique com botão direito** na pasta que contém os vídeos
3. **Selecione** "🎬 Organizar esta Pasta com VLC"
4. **Aguarde** o processamento automático
5. **VLC abrirá** automaticamente com a playlist organizada

## 📝 Exemplos de Nomenclatura Suportada

O organizador reconhece diversos padrões de nomenclatura:

```
✅ Series Name S01E01.mp4
✅ Series Name Season 1 Episode 1.mkv  
✅ Series Name - 1x01.avi
✅ [Series Name] S01E01.mp4
✅ Series Name - Temporada 1 Episodio 1.mp4
```

## ⚙️ Configuração

Edite o arquivo `config/settings.json` para personalizar:

```json
{
  "files": {
    "supportedExtensions": [".mp4", ".mkv", ".avi", ".mov", ".wmv"],
    "playlistName": "playlist_organizada.xspf"
  },
  "vlc": {
    "possiblePaths": [
      "C:\\Program Files\\VideoLAN\\VLC\\vlc.exe",
      "C:\\Program Files (x86)\\VideoLAN\\VLC\\vlc.exe"
    ]
  },
  "parsing": {
    "seasonPatterns": [
      "S(\\d+)E(\\d+)",
      "Season\\s*(\\d+).*Episode\\s*(\\d+)"
    ]
  }
}
```

## 🗑️ Desinstalação

### Usando o Instalador:
1. Execute `VLCOrganizer.Installer.exe` como Administrador
2. Clique em "🗑️ Desinstalar"
3. Escolha se deseja remover os arquivos instalados ou apenas o menu de contexto

### Manual:
```powershell
# Execute PowerShell como Administrador
reg delete "HKEY_CLASSES_ROOT\Directory\Background\shell\OrganizarVLC" /f
reg delete "HKEY_CLASSES_ROOT\Directory\shell\OrganizarVLC" /f
```

## 🛠️ Desenvolvimento

### Pré-requisitos
- .NET 8.0 SDK
- Visual Studio 2022 ou VS Code
- Windows 10/11

### Compilar o Instalador
```bash
cd VLCOrganizer.Installer
dotnet build -c Release
dotnet publish -c Release -r win-x64 --self-contained true /p:PublishSingleFile=true
```

### Estrutura do Código
- **MainForm.cs**: Interface gráfica do instalador
- **Program.cs**: Ponto de entrada da aplicação
- **VLC-Organizer-Final.ps1**: Script principal em PowerShell

## 📋 Requisitos do Sistema

- ✅ Windows 10/11
- ✅ PowerShell 5.1+ (incluso no Windows)
- ✅ VLC Media Player (opcional, mas recomendado)
- ✅ **Nenhuma dependência externa** - instalador é auto-contido!

## 🐛 Resolução de Problemas

### PowerShell não executa scripts
```powershell
# Execute como Administrador
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### VLC não abre automaticamente
- Verifique se o VLC está instalado nos caminhos padrão
- Edite `config/settings.json` para adicionar o caminho correto do VLC

### Menu de contexto não aparece
- Verifique se o instalador foi executado como Administrador
- Confirme que o script PowerShell existe no caminho registrado

## 📄 Licença

Este projeto é fornecido "como está" para uso pessoal e educacional.

## 🤝 Contribuições

Contribuições são bem-vindas! Sinta-se livre para:
- Relatar bugs
- Sugerir melhorias
- Submeter pull requests

---

**🎬 VLC Organizer v2.0** - Transformando pastas bagunçadas em playlists organizadas! ✨