@echo off
chcp 65001 >nul
setlocal

echo ╔══════════════════════════════════════════════════════════════════════╗
echo ║               🚀 VLC Organizer - Build Standalone (~30MB)            ║
echo ╚══════════════════════════════════════════════════════════════════════╝
echo.

:: Verificar se .NET está instalado
echo 🔍 Verificando .NET SDK...
dotnet --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ .NET SDK não encontrado!
    echo    Por favor, instale o .NET 8.0 SDK de: https://dotnet.microsoft.com/download
    pause
    exit /b 1
)

echo ✅ .NET SDK encontrado

:: Verificar se o projeto existe
if not exist "VLCOrganizer.Installer\VLCOrganizer.Installer.csproj" (
    echo ❌ Projeto não encontrado: VLCOrganizer.Installer\VLCOrganizer.Installer.csproj
    pause
    exit /b 1
)

:: Criar diretório bin se não existir
if not exist "bin-standalone" mkdir "bin-standalone"

echo.
echo 🔨 Compilando VLC Organizer Installer (Versão Standalone)...
echo 📋 Não requer .NET no computador de destino
echo.

:: Navegar para o diretório do projeto
cd VLCOrganizer.Installer

:: Build do projeto (self-contained)
echo 📦 Executando dotnet publish (self-contained)...
dotnet publish -c Release --self-contained true -r win-x64 -p:PublishSingleFile=true -p:EnableCompressionInSingleFile=true -o "..\bin-standalone"

if %errorlevel% neq 0 (
    echo.
    echo ❌ Erro durante a compilação!
    cd..
    pause
    exit /b 1
)

cd..

:: Verificar se o executável foi criado
if exist "bin-standalone\VLCOrganizer.Installer.exe" (
    echo.
    echo ╔══════════════════════════════════════════════════════════════════════╗
    echo ║                         ✅ BUILD CONCLUÍDO! ✅                       ║
    echo ╚══════════════════════════════════════════════════════════════════════╝
    echo.
    echo 🎉 Executável criado com sucesso:
    echo    📁 bin-standalone\VLCOrganizer.Installer.exe
    echo.
    
    :: Mostrar tamanho do arquivo
    for %%F in ("bin-standalone\VLCOrganizer.Installer.exe") do echo 📊 Tamanho: %%~zF bytes (~%%~zF KB)
    
    echo.
    echo ✅ VANTAGEM: Esta versão NÃO requer .NET no computador de destino
    echo 🎯 Arquivo único e independente - pode ser usado em qualquer Windows
    echo.
    echo 📋 Próximos passos:
    echo    1. Execute bin-standalone\VLCOrganizer.Installer.exe como Administrador
    echo    2. Clique em "Instalar Menu de Contexto"
    echo    3. Teste clicando com botão direito em uma pasta com vídeos
    echo.
) else (
    echo ❌ Erro: Executável não foi criado!
)

echo Pressione qualquer tecla para sair...
pause >nul