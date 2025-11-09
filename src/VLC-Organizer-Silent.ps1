# =============================================================================
# VLC Organizer Silent v2.0 - Versão Silenciosa
# =============================================================================
param(
    [Parameter(Mandatory=$true)]
    [string]$PlaylistPath
)

# Importar o organizador principal
$scriptRoot = Split-Path $MyInvocation.ScriptName -Parent
$mainOrganizerPath = Join-Path $scriptRoot "VLCOrganizer.ps1"

# Verificar se o organizador principal existe
if (-not (Test-Path $mainOrganizerPath)) {
    Write-Error "Organizador principal não encontrado: $mainOrganizerPath"
    exit 1
}

try {
    # Dot source do organizador principal
    . $mainOrganizerPath
    
    # Executar em modo silencioso
    Start-VLCOrganizer -Path $PlaylistPath -Silent $true -NoVLC $false
}
catch {
    # Log de erro silencioso (apenas para arquivo de log se configurado)
    $errorMsg = "Erro na execução silenciosa: $($_.Exception.Message)"
    
    # Tentar logar no arquivo se existir configuração
    $configPath = Join-Path (Split-Path $scriptRoot -Parent) "config\settings.json"
    if (Test-Path $configPath) {
        try {
            $config = Get-Content $configPath -Raw | ConvertFrom-Json
            if ($config.logging.enabled) {
                $logPath = Join-Path (Split-Path $scriptRoot -Parent) $config.logging.logFile
                $logDir = Split-Path $logPath -Parent
                if (-not (Test-Path $logDir)) {
                    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
                }
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Add-Content -Path $logPath -Value "[$timestamp] [ERROR] $errorMsg" -Encoding UTF8
            }
        }
        catch {
            # Falhou ao logar, mas não podemos mostrar erro em modo silencioso
        }
    }
    
    exit 1
}