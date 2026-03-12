param(
    [Parameter(Mandatory = $true)]
    [string]$PdfPath,
    [string]$OutFile
)

$resolvedPdf = Resolve-Path $PdfPath -ErrorAction Stop

if (-not $OutFile) {
    $OutFile = [System.IO.Path]::ChangeExtension($resolvedPdf, '.txt')
}

$pdftotext = Get-Command pdftotext -ErrorAction SilentlyContinue
$mutool = Get-Command mutool -ErrorAction SilentlyContinue

if ($pdftotext) {
    & $pdftotext.Source -layout -enc UTF-8 $resolvedPdf $OutFile
    Write-Output $OutFile
    exit 0
}

if ($mutool) {
    & $mutool.Source draw -F text -o $OutFile $resolvedPdf
    Write-Output $OutFile
    exit 0
}

Write-Error "No supported PDF text extractor is available. Install pdftotext or mutool, or provide extracted text manually. Do not paraphrase from the file name alone."
exit 1
