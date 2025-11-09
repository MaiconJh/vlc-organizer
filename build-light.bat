@echo off
chcp 65001 >nul
setlocal

echo ╔══════════════════════════════════════════════════════════════════════╗
echo ║                🔨 VLC Organizer - Build Light (~150KB)               ║
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
if not exist "bin" mkdir "bin"

echo.
echo 🔨 Compilando VLC Organizer Installer (Versão Leve)...
echo 📋 Requer .NET 8.0 Runtime no computador de destino
echo.

:: Navegar para o diretório do projeto
cd VLCOrganizer.Installer

:: Build do projeto (framework-dependent)
echo 📦 Executando dotnet publish (framework-dependent)...
dotnet publish -c Release --self-contained false -o "..\bin"

if %errorlevel% neq 0 (
    echo.
    echo ❌ Erro durante a compilação!
    cd..
    pause
    exit /b 1
)

cd..

:: Verificar se o executável foi criado
if exist "bin\VLCOrganizer.Installer.exe" (
    echo.
    echo ╔══════════════════════════════════════════════════════════════════════╗
    echo ║                         ✅ BUILD CONCLUÍDO! ✅                       ║
    echo ╚══════════════════════════════════════════════════════════════════════╝
    echo.
    echo 🎉 Executável criado com sucesso:
    echo    📁 bin\VLCOrganizer.Installer.exe
    echo.
    
    :: Mostrar tamanho do arquivo
    for %%F in ("bin\VLCOrganizer.Installer.exe") do echo 📊 Tamanho: %%~zF bytes (~%%~zF KB)
    
    echo.
    echo ⚠️  IMPORTANTE: Esta versão requer .NET 8.0 Runtime no computador de destino
    echo 📥 Download: https://dotnet.microsoft.com/download/dotnet/8.0
    echo.
    echo 📋 Próximos passos:
    echo    1. Execute bin\VLCOrganizer.Installer.exe como Administrador
    echo    2. Clique em "Instalar Menu de Contexto"
    echo    3. Teste clicando com botão direito em uma pasta com vídeos
    echo.
) else (
    echo ❌ Erro: Executável não foi criado!
)

echo Pressione qualquer tecla para sair...
pause >nul