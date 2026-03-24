[CmdletBinding()]
param(
    [string]$ReferenceRoot = '',
    [string]$OutputPath = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

if ([string]::IsNullOrWhiteSpace($ReferenceRoot)) {
    $ReferenceRoot = Join-Path $scriptRoot '..\reference'
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $scriptRoot 'reference-content-index.tsv'
}

function Normalize-Preview {
    param(
        [AllowNull()]
        [string]$Text,
        [int]$MaxLength = 320
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ''
    }

    $normalized = $Text -replace '<[^>]+>', ' '
    $normalized = $normalized -replace '\s+', ' '
    $normalized = $normalized.Trim()

    if ($normalized.Length -gt $MaxLength) {
        return $normalized.Substring(0, $MaxLength) + '...'
    }

    return $normalized
}

function Test-AuxiliaryArtifact {
    param(
        [string]$RelativePath,
        [string]$TitleHint,
        [string]$Preview
    )

    $joined = @($RelativePath, $TitleHint, $Preview) -join ' '
    return $joined -match '(?i)get more|get latest|torrent|facebook|uploads will cease|support needed|kickass|ahashare|btsdl|demonoid|visit me'
}

function Test-LowQualityTitle {
    param([string]$Title)

    if ([string]::IsNullOrWhiteSpace($Title)) {
        return $true
    }

    if ($Title -match '(?i)\.(pdf|epub|eps|jpg|png)$') {
        return $true
    }

    if ($Title -match '^[0-9._-]+$') {
        return $true
    }

    return $false
}

function Get-TopLevelGroup {
    param([string]$RelativePath)

    $parts = $RelativePath -split '[\\/]'
    if ($parts.Length -gt 0) {
        return $parts[0]
    }

    return ''
}

function Get-TextFilePreview {
    param([string]$Path)

    $lines = Get-Content -Path $Path -ErrorAction SilentlyContinue |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Select-Object -First 12

    return Normalize-Preview ($lines -join ' | ')
}

function Get-HtmlPreview {
    param([string]$Path)

    $raw = Get-Content -Path $Path -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return ''
    }

    $withoutScripts = [regex]::Replace($raw, '<script[\s\S]*?</script>', ' ', 'IgnoreCase')
    $withoutStyles = [regex]::Replace($withoutScripts, '<style[\s\S]*?</style>', ' ', 'IgnoreCase')
    $plain = [regex]::Replace($withoutStyles, '<[^>]+>', ' ')
    return Normalize-Preview $plain
}

function Get-EpubPreview {
    param([string]$Path)

    $tmp = Join-Path $env:TEMP ([System.IO.Path]::GetRandomFileName() + '.txt')

    try {
        & pandoc $Path -t plain -o $tmp | Out-Null

        $headingLines = Get-Content -Path $tmp -ErrorAction SilentlyContinue |
            Where-Object {
                $_ -match '^[0-9]+\.' -or
                $_ -match '^Chapter\b' -or
                $_ -match '^Part\b'
            } |
            Select-Object -First 20

        if ($headingLines) {
            return Normalize-Preview ($headingLines -join ' | ')
        }

        $fallback = Get-Content -Path $tmp -ErrorAction SilentlyContinue |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            Select-Object -First 12

        return Normalize-Preview ($fallback -join ' | ')
    }
    catch {
        return ''
    }
    finally {
        if (Test-Path $tmp) {
            Remove-Item $tmp -Force -ErrorAction SilentlyContinue
        }
    }
}

function Read-PdfAsciiPrefix {
    param(
        [string]$Path,
        [int]$ByteCount = 1048576
    )

    $stream = [System.IO.File]::OpenRead($Path)

    try {
        $count = [Math]::Min($ByteCount, [int]$stream.Length)
        $buffer = New-Object byte[] $count
        [void]$stream.Read($buffer, 0, $count)
        return [System.Text.Encoding]::ASCII.GetString($buffer)
    }
    finally {
        $stream.Dispose()
    }
}

function Unescape-PdfLiteral {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return ''
    }

    $unescaped = $Value -replace '\\\(', '(' -replace '\\\)', ')' -replace '\\\\', '\'
    return Normalize-Preview $unescaped
}

function Get-PdfMetadata {
    param([string]$Path)

    $ascii = Read-PdfAsciiPrefix -Path $Path
    $titleMatch = [regex]::Match($ascii, '/Title\((?<value>(?:\\.|[^)])*)\)')
    $authorMatch = [regex]::Match($ascii, '/Author\((?<value>(?:\\.|[^)])*)\)')

    $title = if ($titleMatch.Success) { Unescape-PdfLiteral $titleMatch.Groups['value'].Value } else { '' }
    $author = if ($authorMatch.Success) { Unescape-PdfLiteral $authorMatch.Groups['value'].Value } else { '' }

    return [pscustomobject]@{
        Title  = $title
        Author = $author
    }
}

if (-not (Test-Path $ReferenceRoot)) {
    throw "Reference root not found: $ReferenceRoot"
}

$referenceRootFull = (Resolve-Path $ReferenceRoot).Path
$rows = New-Object System.Collections.Generic.List[object]

Get-ChildItem -Path $referenceRootFull -Recurse -File | Sort-Object FullName | ForEach-Object {
    $fullPath = $_.FullName
    $relativePath = $fullPath.Substring($referenceRootFull.Length).TrimStart('\')
    $extension = $_.Extension.ToLowerInvariant()
    $topLevelGroup = Get-TopLevelGroup -RelativePath $relativePath

    $extractMode = ''
    $titleHint = ''
    $authorHint = ''
    $preview = ''
    $isAuxiliary = $false

    switch ($extension) {
        '.epub' {
            $extractMode = 'epub_headings'
            $preview = Get-EpubPreview -Path $fullPath
        }
        '.txt' {
            $extractMode = 'text_preview'
            $preview = Get-TextFilePreview -Path $fullPath
        }
        '.html' {
            $extractMode = 'html_preview'
            $preview = Get-HtmlPreview -Path $fullPath
        }
        '.pdf' {
            $extractMode = 'pdf_metadata'
            $meta = Get-PdfMetadata -Path $fullPath
            $titleHint = $meta.Title
            $authorHint = $meta.Author
            $preview = Normalize-Preview (($meta.Title, $meta.Author | Where-Object { $_ }) -join ' | ')
        }
        default {
            $extractMode = 'file_only'
        }
    }

    if ([string]::IsNullOrWhiteSpace($titleHint)) {
        $titleHint = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
    }

    if (Test-LowQualityTitle -Title $titleHint) {
        if (-not [string]::IsNullOrWhiteSpace($topLevelGroup)) {
            $titleHint = $topLevelGroup
        }
    }

    $isAuxiliary = Test-AuxiliaryArtifact -RelativePath $relativePath -TitleHint $titleHint -Preview $preview

    $rows.Add([pscustomobject]@{
        RelativePath = $relativePath
        Group        = $topLevelGroup
        Extension    = $extension
        ExtractMode  = $extractMode
        IsAuxiliary  = $isAuxiliary
        TitleHint    = $titleHint
        AuthorHint   = $authorHint
        Preview      = $preview
    }) | Out-Null
}

$rows | Export-Csv -Path $OutputPath -Delimiter "`t" -NoTypeInformation
Write-Output "Wrote $($rows.Count) rows to $OutputPath"
