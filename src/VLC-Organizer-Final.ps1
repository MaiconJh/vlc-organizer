# Organizador Final de Playlist VLC - Versao Corrigida
param(
    [Parameter(Mandatory=$true)]
    [string]$PlaylistPath
)

function Extract-SeriesInfo {
    param([string]$filename)
    
    $nameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($filename)
    
    # Normalização baseada na pasta + técnicas do Seanime
    function Get-SeriesFromContext {
        param([string]$filePath, [string]$extractedName)
        
        # Usar nome da pasta como base (resolve problema "New Saga" vs "Tsuyokute New Saga")
        $folderName = Split-Path $filePath -Parent | Split-Path -Leaf
        
        # Se o nome da pasta contém informações da série, usar ela como base
        # Mas não usar pastas "container" genéricas como "Anime", "Videos", etc.
        if ($folderName -notmatch '^\d{4}$' -and 
            $folderName -notmatch '^Temp|Download|New Folder|Anime|Videos|Movies|Series|Downloads$') {
            $seriesName = $folderName
        } else {
            # Caso contrário, usar o nome extraído do arquivo
            $seriesName = $extractedName
        }
        
        # Aplicar técnicas do Seanime para normalização
        # Remove indicadores de temporada/season
        $normalized = $seriesName -replace '\s*S\d+\s*$', ''
        $normalized = $normalized -replace '\s*Season\s*\d+\s*$', ''
        $normalized = $normalized -replace '\s*Part\s*\d+\s*$', ''
        $normalized = $normalized -replace '\s*\d+ª\s*Temporada\s*$', ''
        $normalized = $normalized -replace '\s*2ª\s*Temporada\s*$', ''
        $normalized = $normalized -replace '\s*3ª\s*Temporada\s*$', ''
        
        # Limpeza de caracteres especiais (técnica Seanime)
        $normalized = $normalized -replace '\s*:\s*', ' - '
        $normalized = $normalized -replace '\s*-\s*', ' - '
        $normalized = $normalized -replace '\s+', ' '
        $normalized = $normalized -replace '[^\w\s\-\.]', ''
        
        # Remover tags de release comuns
        $normalized = $normalized -replace '\[.*?\]', ''
        $normalized = $normalized -replace '\(.*?\)', ''
        
        return $normalized.Trim()
    }
    
    # Series.SxxExx.Title (padrão Dr.STONE.S04E13)
    if ($nameWithoutExt -match '^(.+?)\.S(\d+)E(\d+)') {
        $extractedName = $Matches[1].Trim() -replace '\.', ' '
        $seriesName = Get-SeriesFromContext $filename $extractedName
        return [PSCustomObject]@{
            Series = $seriesName
            Season = [int]$Matches[2]
            Episode = [int]$Matches[3]
            FullPath = $filename
            SortKey = "{0}_{1:D2}_{2:D3}" -f $seriesName, [int]$Matches[2], [int]$Matches[3]
        }
    }
    
    # [Release] Series Sx - Episode (padrão Erai-raws)
    if ($nameWithoutExt -match '^\[([^\]]+)\]\s*(.+?)\s*S(\d+)\s*-\s*(\d+)') {
        $extractedName = $Matches[2].Trim()
        $seriesName = Get-SeriesFromContext $filename $extractedName
        return [PSCustomObject]@{
            Series = $seriesName
            Season = [int]$Matches[3]
            Episode = [int]$Matches[4]
            FullPath = $filename
            SortKey = "{0}_{1:D2}_{2:D3}" -f $seriesName, [int]$Matches[3], [int]$Matches[4]
        }
    }
    
    # [Release] Series - SxxExx (padrão Judas)
    if ($nameWithoutExt -match '^\[([^\]]+)\]\s*(.+?)\s*-\s*S(\d+)E(\d+)') {
        $extractedName = $Matches[2].Trim()
        $seriesName = Get-SeriesFromContext $filename $extractedName
        return [PSCustomObject]@{
            Series = $seriesName
            Season = [int]$Matches[3]
            Episode = [int]$Matches[4]
            FullPath = $filename
            SortKey = "{0}_{1:D2}_{2:D3}" -f $seriesName, [int]$Matches[3], [int]$Matches[4]
        }
    }
    
    # [Release]Series_Name_Episode (formato [EA]Silent_Witch_01)
    if ($nameWithoutExt -match '^\[([^\]]+)\](.+?)_(\d+)_') {
        $extractedName = $Matches[2].Trim() -replace '_', ' '
        $seriesName = Get-SeriesFromContext $filename $extractedName
        
        # Detectar temporada do contexto da pasta (técnica Seanime)
        $folderName = Split-Path $filename -Parent | Split-Path -Leaf
        $season = 1
        if ($folderName -match '(?i)2ª\s*Temporada|Season\s*2|S2') {
            $season = 2
        } elseif ($folderName -match '(?i)3ª\s*Temporada|Season\s*3|S3') {
            $season = 3
        }
        
        return [PSCustomObject]@{
            Series = $seriesName
            Season = $season
            Episode = [int]$Matches[3]
            FullPath = $filename
            SortKey = "{0}_{1:D2}_{2:D3}" -f $seriesName, $season, [int]$Matches[3]
        }
    }
    
    # [Release]Series_Name_Episode (formato [EA]Silent_Witch_01)
    if ($nameWithoutExt -match '^\[([^\]]+)\](.+?)_(\d+)_') {
        $extractedName = $Matches[2].Trim() -replace '_', ' '
        $seriesName = Get-SeriesFromContext $filename $extractedName
        
        # Detectar temporada do contexto da pasta (técnica Seanime)
        $folderName = Split-Path $filename -Parent | Split-Path -Leaf
        $season = 1
        if ($folderName -match '(?i)2ª\s*Temporada|Season\s*2|S2') {
            $season = 2
        } elseif ($folderName -match '(?i)3ª\s*Temporada|Season\s*3|S3') {
            $season = 3
        }
        
        return [PSCustomObject]@{
            Series = $seriesName
            Season = $season
            Episode = [int]$Matches[3]
            FullPath = $filename
            SortKey = "{0}_{1:D2}_{2:D3}" -f $seriesName, $season, [int]$Matches[3]
        }
    }
    
    # [Release] Series - Episode (técnica universal do Seanime)
    if ($nameWithoutExt -match '^\[([^\]]+)\]\s*(.+?)\s*-\s*(\d+)') {
        $extractedName = $Matches[2].Trim()
        $seriesName = Get-SeriesFromContext $filename $extractedName
        
        # Detectar temporada do contexto da pasta (técnica do Seanime)
        $folderName = Split-Path $filename -Parent | Split-Path -Leaf
        $season = 1
        if ($folderName -match '(?i)2ª\s*Temporada|Season\s*2|S2') {
            $season = 2
        } elseif ($folderName -match '(?i)3ª\s*Temporada|Season\s*3|S3') {
            $season = 3
        }
        
        return [PSCustomObject]@{
            Series = $seriesName
            Season = $season
            Episode = [int]$Matches[3]
            FullPath = $filename
            SortKey = "{0}_{1:D2}_{2:D3}" -f $seriesName, $season, [int]$Matches[3]
        }
    }
    
    # Padrão genérico (usar contexto da pasta)
    $seriesName = Get-SeriesFromContext $filename $nameWithoutExt
    return [PSCustomObject]@{
        Series = $seriesName
        Season = 1
        Episode = 0
        FullPath = $filename
        SortKey = $seriesName
    }
}

Write-Host "=== Organizador de Playlist VLC ===" -ForegroundColor Green

# Buscar arquivos de video
$videoExtensions = @("*.mp4", "*.mkv", "*.avi", "*.mov", "*.wmv", "*.flv", "*.webm", "*.m4v")
$videoFiles = @()

foreach ($ext in $videoExtensions) {
    $videoFiles += Get-ChildItem -Path $PlaylistPath -Filter $ext -Recurse | Select-Object -ExpandProperty FullName
}

if ($videoFiles.Count -eq 0) {
    Write-Host "Nenhum arquivo de video encontrado" -ForegroundColor Red
    exit
}

Write-Host "Encontrados $($videoFiles.Count) arquivos" -ForegroundColor Blue
Write-Host ""

# Detectar temporada do contexto da pasta (aplicar a todos)
$folderName = Split-Path $PlaylistPath -Leaf
Write-Host "Nome da pasta: $folderName" -ForegroundColor Gray
$contextSeason = 1
if ($folderName -match '(?i)2.*Temporada|Season.*2|S2') {
    $contextSeason = 2
} elseif ($folderName -match '(?i)3.*Temporada|Season.*3|S3') {
    $contextSeason = 3
}

Write-Host "Pasta detectada como Temporada $contextSeason" -ForegroundColor Magenta
Write-Host ""

# Analisar arquivos
$parsedFiles = @()
foreach ($file in $videoFiles) {
    $info = Extract-SeriesInfo $file
    
    # Forçar temporada baseada no contexto da pasta apenas se não foi detectada no arquivo
    if ($info.Season -eq 0 -or $info.Season -eq 1) {
        $info.Season = $contextSeason
    }
    $info.SortKey = "{0}_{1:D2}_{2:D3}" -f $info.Series, $info.Season, $info.Episode
    
    $parsedFiles += $info
    
    $fileName = [System.IO.Path]::GetFileName($file)
    Write-Host "Analisando: $fileName" -ForegroundColor Yellow
    Write-Host "  -> Serie: $($info.Series)" -ForegroundColor Cyan
    Write-Host "  -> Episodio: S$($info.Season.ToString('D2'))E$($info.Episode.ToString('D2'))" -ForegroundColor Cyan
    Write-Host ""
}

# Agrupar por série normalizada e depois ordenar por episódio
$groupedFiles = $parsedFiles | Group-Object Series | ForEach-Object {
    $_.Group | Sort-Object Season, Episode
}
$sortedFiles = $groupedFiles | Sort-Object Series, Season, Episode

Write-Host "=== ORDEM FINAL DA PLAYLIST ===" -ForegroundColor Magenta
$count = 1
foreach ($file in $sortedFiles) {
    $fileName = [System.IO.Path]::GetFileName($file.FullPath)
    Write-Host "$count. $($file.Series) - S$($file.Season.ToString('D2'))E$($file.Episode.ToString('D2'))" -ForegroundColor White
    Write-Host "    $fileName" -ForegroundColor Gray
    $count++
}

# Criar playlist XSPF temporária
$tempFolder = [System.IO.Path]::GetTempPath()
$folderName = Split-Path $PlaylistPath -Leaf
$outputPath = Join-Path $tempFolder "VLC_Playlist_$($folderName)_$(Get-Date -Format 'yyyyMMdd_HHmmss').xspf"

$playlistContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<playlist xmlns="http://xspf.org/ns/0/" xmlns:vlc="http://www.videolan.org/vlc/playlist/ns/0/" version="1">
    <title>Playlist Organizada - $folderName</title>
    <trackList>
"@

$trackId = 0
foreach ($file in $sortedFiles) {
    $trackId++
    $uri = [System.Uri]::new($file.FullPath).AbsoluteUri
    $title = "$($file.Series) - S$($file.Season.ToString('D2'))E$($file.Episode.ToString('D2'))"
    
    $playlistContent += @"

        <track>
            <location>$uri</location>
            <title>$title</title>
            <extension application="http://www.videolan.org/vlc/playlist/0">
                <vlc:id>$trackId</vlc:id>
            </extension>
        </track>
"@
}

$playlistContent += @"

    </trackList>
</playlist>
"@

Set-Content -Path $outputPath -Value $playlistContent -Encoding UTF8

Write-Host ""
Write-Host "Playlist criada com sucesso!" -ForegroundColor Green
Write-Host "Abrindo no VLC..." -ForegroundColor Cyan

# Abrir no VLC - Tentar localizar automaticamente
try {
    $vlcPath = $null
    
    # Tentar localizar o VLC automaticamente
    $possiblePaths = @(
        "C:\Program Files\VideoLAN\VLC\vlc.exe",
        "C:\Program Files (x86)\VideoLAN\VLC\vlc.exe"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $vlcPath = $path
            break
        }
    }
    
    if ($vlcPath) {
        Start-Process $vlcPath -ArgumentList "`"$outputPath`""
        Write-Host "VLC aberto com playlist organizada!" -ForegroundColor Green
        
        # Aguardar um momento para o VLC carregar a playlist
        Start-Sleep -Seconds 1
        
        # Remover arquivo temporário
        if (Test-Path $outputPath) {
            Remove-Item $outputPath -Force
            Write-Host "Arquivo temporário removido." -ForegroundColor Gray
        }
    } else {
        Write-Host "Aviso: VLC não encontrado nos caminhos padrão" -ForegroundColor Yellow
        Write-Host "Tentando abrir com programa padrão..." -ForegroundColor Yellow
        Start-Process $outputPath
        Write-Host "Playlist salva em: $outputPath" -ForegroundColor Green
    }
} catch {
    Write-Host "Erro ao abrir VLC: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Playlist salva em: $outputPath" -ForegroundColor Yellow
}