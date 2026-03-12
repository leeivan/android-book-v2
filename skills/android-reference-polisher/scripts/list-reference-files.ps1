param()

$root = Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..\reference')

Get-ChildItem -Path $root -Recurse -File -Include *.pdf,*.zip |
    Sort-Object FullName |
    Select-Object FullName, Extension
