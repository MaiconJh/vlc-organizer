@echo off
chcp 65001 >nul

:: =============================================================================
:: VLC Organizer - Menu de Contexto Helper v2.0
:: =============================================================================

:: Obter o diretório onde o script foi executado
set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%.."
set "PASTA=%~1"
set "LOG_FILE=%ROOT_DIR%\logs\menu-contexto.log"

:: Criar diretório de logs se não existir
if not exist "%ROOT_DIR%\logs" mkdir "%ROOT_DIR%\logs"

:: Função de log
set "TIMESTAMP=%date% %time%"
echo [%TIMESTAMP%] === VLC Organizer - Menu de Contexto === >> "%LOG_FILE%"
echo [%TIMESTAMP%] Pasta solicitada: %PASTA% >> "%LOG_FILE%"

:: Verificar se a pasta foi especificada
if "%PASTA%"=="" (
    set "PASTA=%cd%"
    echo Usando pasta atual: %PASTA%
    echo [%TIMESTAMP%] Usando pasta atual: %PASTA% >> "%LOG_FILE%"
) else (
    echo Organizando playlist na pasta: %PASTA%
    echo [%TIMESTAMP%] Pasta especificada: %PASTA% >> "%LOG_FILE%"
)

echo.
echo === VLC Organizer v2.0 ===
echo Analisando pasta: %PASTA%
echo.

:: Executar o organizador principal usando caminho relativo
echo [%TIMESTAMP%] Executando organizador... >> "%LOG_FILE%"
powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "%ROOT_DIR%\src\VLCOrganizer.ps1" -PlaylistPath "%PASTA%" -Verbose

:: Verificar se a playlist foi criada
if exist "%PASTA%\playlist_organizada.xspf" (
    echo Playlist criada com sucesso!
    echo Abrindo no VLC...
    
    :: Tentar localizar o VLC automaticamente
    set "VLC_PATH="
    if exist "C:\Program Files\VideoLAN\VLC\vlc.exe" set "VLC_PATH=C:\Program Files\VideoLAN\VLC\vlc.exe"
    if exist "C:\Program Files (x86)\VideoLAN\VLC\vlc.exe" set "VLC_PATH=C:\Program Files (x86)\VideoLAN\VLC\vlc.exe"
    
    if defined VLC_PATH (
        start "" "%VLC_PATH%" "%PASTA%\playlist_organizada.xspf"
    ) else (
        echo Aviso: VLC nao encontrado nos caminhos padrao
        echo Tentando abrir com programa padrao...
        start "" "%PASTA%\playlist_organizada.xspf"
    )
) else (
    echo Erro: Playlist nao foi criada
    echo [%TIMESTAMP%] ERRO: Playlist não foi criada >> "%LOG_FILE%"
    echo.
    echo Verifique o arquivo de log para mais detalhes:
    echo %LOG_FILE%
    pause
)

echo [%TIMESTAMP%] === Fim da execução === >> "%LOG_FILE%"
echo.
