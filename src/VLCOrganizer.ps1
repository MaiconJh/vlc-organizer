# =============================================================================
# VLC Organizer v2.0 - Organizador Inteligente de Playlists
# =============================================================================
param(
    [Parameter(Mandatory=$true)]
    [string]$PlaylistPath,
    
    [switch]$Silent,
    [switch]$Verbose,
    [string]$ConfigPath = "",
    [switch]$NoVLC
)

# =============================================================================
# CONFIGURAÇÕES E INICIALIZAÇÃO
# =============================================================================

$ErrorActionPreference = "Stop"
$script:Config = $null
$script:Logger = $null

# Função para carregar configurações
function Initialize-Config {
    param([string]$ConfigPath)
    
    # Determinar caminho do config
    $scriptRoot = Split-Path $MyInvocation.ScriptName -Parent
    $defaultConfigPath = Join-Path (Split-Path $scriptRoot -Parent) "config\settings.json"
    
    $configFile = if ($ConfigPath) { $ConfigPath } else { $defaultConfigPath }
    
    if (-not (Test-Path $configFile)) {
        Write-Warning "Arquivo de configuração não encontrado: $configFile"
        Write-Warning "Usando configurações padrão..."
        return Get-DefaultConfig
    }
    
    try {
        $configContent = Get-Content $configFile -Raw -Encoding UTF8
        return $configContent | ConvertFrom-Json
    }
    catch {
        Write-Error "Erro ao carregar configurações: $($_.Exception.Message)"
        return Get-DefaultConfig
    }
}

# Configurações padrão caso não exista arquivo
function Get-DefaultConfig {
    return @{
        files = @{
            supportedExtensions = @(".mp4", ".mkv", ".avi", ".mov", ".wmv", ".flv", ".webm")
            playlistName = "playlist_organizada.xspf"
        }
        vlc = @{
            possiblePaths = @(
                "C:\Program Files\VideoLAN\VLC\vlc.exe",
                "C:\Program Files (x86)\VideoLAN\VLC\vlc.exe"
            )
        }
        parsing = @{
            seasonPatterns = @("S(\d+)E(\d+)", "Season\s*(\d+).*Episode\s*(\d+)")
            genericFolders = @("Temp", "Download", "Anime", "Videos", "Downloads")
        }
        ui = @{
            colors = @{
                success = "Green"
                error = "Red"
                warning = "Yellow" 
                info = "Cyan"
                highlight = "Magenta"
            }
        }
    }
}

# =============================================================================
# SISTEMA DE LOG
# =============================================================================

class VLCLogger {
    [string]$LogPath
    [bool]$Enabled
    [bool]$Silent
    [bool]$Verbose
    
    VLCLogger([bool]$Silent, [bool]$Verbose, [string]$LogPath) {
        $this.Silent = $Silent
        $this.Verbose = $Verbose
        $this.LogPath = $LogPath
        $this.Enabled = [bool]$LogPath
        
        if ($this.Enabled -and $LogPath) {
            $logDir = Split-Path $LogPath -Parent
            if ($logDir -and -not (Test-Path $logDir)) {
                New-Item -ItemType Directory -Path $logDir -Force | Out-Null
            }
        }
    }
    
    [void] Log([string]$Level, [string]$Message, [string]$Color = "White") {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logMessage = "[$timestamp] [$Level] $Message"
        
        # Log para arquivo
        if ($this.Enabled -and $this.LogPath) {
            Add-Content -Path $this.LogPath -Value $logMessage -Encoding UTF8
        }
        
        # Log para console
        if (-not $this.Silent) {
            if ($Level -eq "VERBOSE" -and -not $this.Verbose) {
                return
            }
            Write-Host $Message -ForegroundColor $Color
        }
    }
    
    [void] Success([string]$Message) { $this.Log("INFO", $Message, "Green") }
    [void] Error([string]$Message) { $this.Log("ERROR", $Message, "Red") }
    [void] Warning([string]$Message) { $this.Log("WARN", $Message, "Yellow") }
    [void] Info([string]$Message) { $this.Log("INFO", $Message, "Cyan") }
    [void] Highlight([string]$Message) { $this.Log("INFO", $Message, "Magenta") }
    [void] Verbose([string]$Message) { $this.Log("VERBOSE", $Message, "Gray") }
}

# =============================================================================
# CLASSES PRINCIPAIS
# =============================================================================

class SeriesInfo {
    [string]$Series
    [int]$Season
    [int]$Episode
    [string]$FullPath
    [string]$FileName
    [string]$Title
    
    SeriesInfo([string]$Series, [int]$Season, [int]$Episode, [string]$FullPath) {
        $this.Series = $Series
        $this.Season = $Season
        $this.Episode = $Episode
        $this.FullPath = $FullPath
        $this.FileName = Split-Path $FullPath -Leaf
        $this.Title = ""
    }
    
    [string] GetDisplayName() {
        return "S$($this.Season.ToString('D2'))E$($this.Episode.ToString('D2'))"
    }
}

class VLCOrganizer {
    [object]$Config
    [VLCLogger]$Logger
    [string]$WorkingPath
    
    VLCOrganizer([object]$Config, [VLCLogger]$Logger, [string]$Path) {
        $this.Config = $Config
        $this.Logger = $Logger
        $this.WorkingPath = $Path
    }
    
    # Extrair informações da série do nome do arquivo
    [SeriesInfo] ExtractSeriesInfo([string]$filePath) {
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($filePath)
        $this.Logger.Verbose("Analisando arquivo: $fileName")
        
        # Obter nome da série do contexto da pasta
        $seriesName = $this.GetSeriesFromContext($filePath, $fileName)
        $this.Logger.Verbose("Série detectada: $seriesName")
        
        # Extrair temporada e episódio
        $season = 1
        $episode = 1
        
        foreach ($pattern in $this.Config.parsing.seasonPatterns) {
            if ($fileName -match $pattern) {
                $season = [int]$matches[1]
                $episode = [int]$matches[2]
                $this.Logger.Verbose("Padrão encontrado: S${season}E${episode}")
                break
            }
        }
        
        return [SeriesInfo]::new($seriesName, $season, $episode, $filePath)
    }
    
    # Determinar nome da série baseado no contexto
    [string] GetSeriesFromContext([string]$filePath, [string]$extractedName) {
        $folderName = Split-Path (Split-Path $filePath -Parent) -Leaf
        
        # Verificar se a pasta não é genérica
        $isGenericFolder = $false
        foreach ($generic in $this.Config.parsing.genericFolders) {
            if ($folderName -match "^$generic$|^\d{4}$") {
                $isGenericFolder = $true
                break
            }
        }
        
        $seriesName = if (-not $isGenericFolder) { $folderName } else { $extractedName }
        
        # Aplicar limpeza de nome
        foreach ($pattern in $this.Config.parsing.seriesCleanup) {
            $seriesName = $seriesName -replace $pattern, ''
        }
        
        return $seriesName.Trim()
    }
    
    # Obter todos os arquivos de vídeo
    [array] GetVideoFiles() {
        $extensions = $this.Config.files.supportedExtensions -join '|'
        $pattern = "\.($(extensions -replace '\.', ''))$"
        
        $files = Get-ChildItem -Path $this.WorkingPath -Recurse -File | 
                 Where-Object { $_.Extension -match $pattern }
        
        $this.Logger.Info("Encontrados $($files.Count) arquivos de vídeo")
        return $files
    }
    
    # Organizar arquivos em playlist
    [array] OrganizePlaylist() {
        $this.Logger.Info("=== Organizador de Playlist VLC v2.0 ===")
        $this.Logger.Info("Pasta: $($this.WorkingPath)")
        
        $videoFiles = $this.GetVideoFiles()
        
        if ($videoFiles.Count -eq 0) {
            $this.Logger.Error("Nenhum arquivo de vídeo encontrado")
            return @()
        }
        
        # Processar cada arquivo
        $organizedFiles = @()
        foreach ($file in $videoFiles) {
            $info = $this.ExtractSeriesInfo($file.FullName)
            $organizedFiles += $info
            
            $this.Logger.Verbose("  -> Série: $($info.Series)")
            $this.Logger.Verbose("  -> Episódio: $($info.GetDisplayName())")
        }
        
        # Ordenar por série, temporada e episódio
        $sortedFiles = $organizedFiles | Sort-Object Series, Season, Episode
        
        $this.Logger.Highlight("=== ORDEM FINAL DA PLAYLIST ===")
        $count = 1
        foreach ($file in $sortedFiles) {
            $this.Logger.Info("$count. $($file.Series) - $($file.GetDisplayName())")
            $this.Logger.Verbose("    $($file.FileName)")
            $count++
        }
        
        return $sortedFiles
    }
    
    # Criar arquivo XSPF
    [string] CreateXSPFPlaylist([array]$files) {
        $outputPath = Join-Path $this.WorkingPath $this.Config.files.playlistName
        
        $xspfContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<playlist version="1" xmlns="http://xspf.org/ns/0/">
    <title>Playlist Organizada - VLC Organizer</title>
    <creator>VLC Organizer v2.0</creator>
    <trackList>
"@
        
        foreach ($file in $files) {
            $escapedPath = [System.Security.SecurityElement]::Escape($file.FullPath)
            $escapedTitle = [System.Security.SecurityElement]::Escape("$($file.Series) - $($file.GetDisplayName())")
            
            $xspfContent += @"

        <track>
            <location>file:///$($escapedPath -replace '\\', '/')</location>
            <title>$escapedTitle</title>
        </track>
"@
        }
        
        $xspfContent += @"

    </trackList>
</playlist>
"@
        
        Set-Content -Path $outputPath -Value $xspfContent -Encoding UTF8
        $this.Logger.Success("Playlist criada: $outputPath")
        
        return $outputPath
    }
    
    # Encontrar VLC
    [string] FindVLC() {
        foreach ($path in $this.Config.vlc.possiblePaths) {
            $expandedPath = [Environment]::ExpandEnvironmentVariables($path)
            if (Test-Path $expandedPath) {
                $this.Logger.Verbose("VLC encontrado: $expandedPath")
                return $expandedPath
            }
        }
        return ""
    }
    
    # Abrir no VLC
    [void] OpenInVLC([string]$playlistPath) {
        $vlcPath = $this.FindVLC()
        
        if (-not $vlcPath) {
            $this.Logger.Warning("VLC não encontrado nos caminhos padrão")
            $this.Logger.Info("Tentando abrir com programa padrão...")
            Start-Process $playlistPath
            return
        }
        
        try {
            $this.Logger.Info("Abrindo no VLC...")
            Start-Process $vlcPath -ArgumentList "`"$playlistPath`""
            $this.Logger.Success("VLC aberto com playlist organizada!")
            
            # Aguardar um momento e limpar arquivo temporário se necessário
            Start-Sleep -Seconds 2
        }
        catch {
            $this.Logger.Error("Erro ao abrir VLC: $($_.Exception.Message)")
            $this.Logger.Info("Playlist salva em: $playlistPath")
        }
    }
}

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

function Start-VLCOrganizer {
    param(
        [string]$Path,
        [bool]$Silent = $false,
        [bool]$Verbose = $false,
        [string]$ConfigPath = "",
        [bool]$NoVLC = $false
    )
    
    try {
        # Inicializar configurações
        $config = Initialize-Config -ConfigPath $ConfigPath
        
        # Inicializar logger
        $logPath = if ($config.logging.enabled) { 
            Join-Path (Split-Path $MyInvocation.ScriptName -Parent) $config.logging.logFile 
        } else { "" }
        
        $logger = [VLCLogger]::new($Silent, $Verbose, $logPath)
        
        # Criar organizador
        $organizer = [VLCOrganizer]::new($config, $logger, $Path)
        
        # Processar
        $organizedFiles = $organizer.OrganizePlaylist()
        
        if ($organizedFiles.Count -eq 0) {
            return
        }
        
        # Criar playlist
        $playlistPath = $organizer.CreateXSPFPlaylist($organizedFiles)
        
        # Abrir no VLC se solicitado
        if (-not $NoVLC) {
            $organizer.OpenInVLC($playlistPath)
        }
        
        $logger.Success("Processo concluído com sucesso!")
    }
    catch {
        Write-Error "Erro durante execução: $($_.Exception.Message)"
        if ($logger) {
            $logger.Error("Erro durante execução: $($_.Exception.Message)")
        }
        exit 1
    }
}

# =============================================================================
# EXECUÇÃO
# =============================================================================

# Executar se chamado diretamente
if ($MyInvocation.InvocationName -ne '.') {
    Start-VLCOrganizer -Path $PlaylistPath -Silent:$Silent -Verbose:$Verbose -ConfigPath $ConfigPath -NoVLC:$NoVLC
}