[CmdletBinding()]
param()

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

$ErrorActionPreference = 'Stop'
$downloadUrl = 'https://devffin.github.io/dl/ytlccv/latest.zip'
$tempZip = Join-Path ([System.IO.Path]::GetTempPath()) ('ytlccv-{0}.zip' -f ([guid]::NewGuid()))

function Write-Banner {
    Write-Host ''
    Write-Host '========================================' -ForegroundColor DarkCyan
    Write-Host '          YTLCCV Installer' -ForegroundColor Cyan
    Write-Host '========================================' -ForegroundColor DarkCyan
    Write-Host ''
}

function Read-ExtractionPath {
    do {
        $path = Read-Host 'Folder where YTLCCV should be extracted'

        if ([string]::IsNullOrWhiteSpace($path)) {
            Write-Host 'Please enter a folder path.' -ForegroundColor Yellow
            continue
        }

        try {
            $resolvedPath = [System.IO.Path]::GetFullPath($path)

            if (Test-Path -LiteralPath $resolvedPath -PathType Leaf) {
                throw 'The path points to a file, not a folder.'
            }

            if (-not (Test-Path -LiteralPath $resolvedPath -PathType Container)) {
                New-Item -ItemType Directory -Path $resolvedPath -Force | Out-Null
                Write-Host "Created folder: $resolvedPath" -ForegroundColor DarkGray
            }

            return $resolvedPath
        }
        catch {
            Write-Host "Invalid path: $($_.Exception.Message)" -ForegroundColor Red
        }
    } while ($true)
}

function Test-MatchingFileStructure {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ArchivePath,
        [Parameter(Mandatory = $true)]
        [string]$DestinationPath
    )

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($ArchivePath)
    $archivePaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    try {
        foreach ($entry in $archive.Entries) {
            $entryPath = $entry.FullName.Replace('\', '/').TrimStart('/')
            if ([string]::IsNullOrWhiteSpace($entryPath)) {
                continue
            }

            $isDirectory = $entry.FullName.EndsWith('/') -or $entry.FullName.EndsWith('\')
            if (-not $isDirectory) {
                [void]$archivePaths.Add($entryPath)
            }

            $directoryPath = if ($isDirectory) { $entryPath.TrimEnd('/') } else { [System.IO.Path]::GetDirectoryName($entryPath.Replace('/', [System.IO.Path]::DirectorySeparatorChar)) }
            while (-not [string]::IsNullOrWhiteSpace($directoryPath)) {
                [void]$archivePaths.Add($directoryPath.Replace('\', '/'))
                $parent = [System.IO.Path]::GetDirectoryName($directoryPath)
                if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $directoryPath) {
                    break
                }
                $directoryPath = $parent
            }
        }
    }
    finally {
        $archive.Dispose()
    }

    $destinationRoot = [System.IO.Path]::GetFullPath($DestinationPath)
    if (-not $destinationRoot.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
        $destinationRoot += [System.IO.Path]::DirectorySeparatorChar
    }

    $destinationItems = @(Get-ChildItem -LiteralPath $DestinationPath -Force -Recurse)
    foreach ($item in $destinationItems) {
        $relativePath = $item.FullName.Substring($destinationRoot.Length).Replace('\', '/')
        if (-not $archivePaths.Contains($relativePath)) {
            return $false
        }
    }

    return $true
}

Write-Banner
$destination = Read-ExtractionPath

try {
    Write-Host 'Downloading YTLCCV...' -ForegroundColor Yellow
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tempZip -UseBasicParsing
    Write-Host 'Download complete.' -ForegroundColor Green

    $existingItems = @(Get-ChildItem -LiteralPath $destination -Force -Recurse)
    if ($existingItems.Count -gt 0 -and -not (Test-MatchingFileStructure -ArchivePath $tempZip -DestinationPath $destination)) {
        throw 'The destination folder contains files or folders that do not match the YTLCCV installation structure. Choose an empty folder or the existing YTLCCV folder.'
    }

    Write-Host "Extracting to: $destination" -ForegroundColor Yellow
    Expand-Archive -LiteralPath $tempZip -DestinationPath $destination -Force
    Write-Host ''
    Write-Host 'Installation completed successfully!' -ForegroundColor Green
}
catch {
    Write-Host ''
    Write-Host "Installation failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
finally {
    if (Test-Path -LiteralPath $tempZip) {
        Remove-Item -LiteralPath $tempZip -Force -ErrorAction SilentlyContinue
    }
}
