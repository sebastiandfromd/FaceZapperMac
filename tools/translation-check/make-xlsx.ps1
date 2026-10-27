# Step 3 of the translation check (see README.md): builds the Excel table (needs Excel, via COM)
# from all.json, context.txt and the back-*.txt / backchanged-*.txt files in the work folder.
param([string]$WorkDir = "$PSScriptRoot\..\..\Stuff(gitignored)\translation-check",
      [string]$OutFile = "$PSScriptRoot\..\..\Stuff(gitignored)\FaceZapper-translations-backcheck.xlsx")
$ErrorActionPreference = 'Stop'
$d = (Resolve-Path $WorkDir).Path
$outFile = [IO.Path]::GetFullPath($OutFile)
$langs = @(
    @{ code = 'en'; name = 'English' }, @{ code = 'es'; name = 'Spanish' }, @{ code = 'fr'; name = 'French' },
    @{ code = 'it'; name = 'Italian' }, @{ code = 'nl'; name = 'Dutch' }, @{ code = 'pt_BR'; name = 'Portuguese (BR)' })

$rows = Get-Content "$d\all.json" -Raw -Encoding utf8 | ConvertFrom-Json
$ctx = Get-Content "$PSScriptRoot\context.txt" -Encoding utf8
$back = @{}
foreach ($l in $langs) {
    $m = @{}
    foreach ($line in (Get-Content "$d\back-$($l.code).txt" -Encoding utf8)) {
        $p = $line -split "`t", 2
        if ($p.Count -eq 2) { $m[[int]$p[0]] = $p[1] -replace '\\n', "`n" }
    }
    # newer back-translations of revised texts override the first round
    $changed = @{}
    $bc = "$d\backchanged-$($l.code).txt"
    if (Test-Path $bc) {
        foreach ($line in (Get-Content $bc -Encoding utf8)) {
            $p = $line -split "`t", 2
            if ($p.Count -eq 2) { $m[[int]$p[0]] = $p[1] -replace '\\n', "`n"; $changed[[int]$p[0]] = $true }
        }
    }
    $back[$l.code] = $m
    $l.changed = $changed
}

$nCols = 2 + 2 * $langs.Count
$data = New-Object 'object[,]' ($rows.Count + 1), $nCols
$data[0,0] = 'Context'; $data[0,1] = 'German (original)'
for ($j = 0; $j -lt $langs.Count; $j++) {
    $data[0, (2 + 2*$j)] = $langs[$j].name
    $data[0, (3 + 2*$j)] = "$($langs[$j].name) → German (blind back-translation)"
}
for ($i = 0; $i -lt $rows.Count; $i++) {
    $r = $rows[$i]
    $data[($i+1),0] = $ctx[$i]
    $data[($i+1),1] = "$($r.de)"
    for ($j = 0; $j -lt $langs.Count; $j++) {
        $c = $langs[$j].code
        $data[($i+1), (2 + 2*$j)] = "$($r.$c)"
        $data[($i+1), (3 + 2*$j)] = "$($back[$c][$i])"
    }
}

$xl = New-Object -ComObject Excel.Application
$xl.Visible = $false; $xl.DisplayAlerts = $false
try {
    $wb = $xl.Workbooks.Add()
    $ws = $wb.Worksheets.Item(1)
    $ws.Name = 'Translations'
    $range = $ws.Range($ws.Cells(1,1), $ws.Cells($rows.Count + 1, $nCols))
    $range.NumberFormat = '@'
    # Excel 2007 rejects array assignment with long strings: set cell by cell
    for ($i = 0; $i -le $rows.Count; $i++) { for ($c = 0; $c -lt $nCols; $c++) {
        $ws.Cells.Item($i + 1, $c + 1).Value2 = "$($data[$i,$c])" } }
    $range.WrapText = $true
    $range.VerticalAlignment = -4160   # top
    $range.Borders.LineStyle = 1
    $range.Borders.Color = 0xBFBFBF
    $hdr = $ws.Range($ws.Cells(1,1), $ws.Cells(1,$nCols))
    $hdr.Font.Bold = $true
    $hdr.Interior.Color = 0x7F7F00     # teal (BGR)
    $hdr.Font.Color = 0xFFFFFF
    $ws.Columns.Item(1).ColumnWidth = 34
    $ws.Columns.Item(2).ColumnWidth = 45
    for ($j = 0; $j -lt $langs.Count; $j++) {
        $ws.Columns.Item(3 + 2*$j).ColumnWidth = 45
        $ws.Columns.Item(4 + 2*$j).ColumnWidth = 45
        $ws.Range($ws.Cells(2, 4 + 2*$j), $ws.Cells($rows.Count + 1, 4 + 2*$j)).Interior.Color = 0xF2F2F2
    }
    $ws.Range($ws.Cells(2,2), $ws.Cells($rows.Count + 1, 2)).Interior.Color = 0xDDF5FF   # light yellow for the original
    # revised texts: orange
    for ($j = 0; $j -lt $langs.Count; $j++) {
        foreach ($i in $langs[$j].changed.Keys) {
            $ws.Range($ws.Cells($i + 2, 3 + 2*$j), $ws.Cells($i + 2, 4 + 2*$j)).Interior.Color = 0x9CD7FF
        }
    }
    $note = $ws.Cells($rows.Count + 3, 1)
    $note.Value2 = 'Orange = wording revised after the first back-translation check; the back-translation shown is the new one.'
    $note.Interior.Color = 0x9CD7FF
    $ws.Rows.Item(1).RowHeight = 32
    $ws.Activate()
    $xl.ActiveWindow.SplitRow = 1
    $xl.ActiveWindow.SplitColumn = 2
    $xl.ActiveWindow.FreezePanes = $true
    $range.AutoFilter() | Out-Null
    if (Test-Path $outFile) { Remove-Item $outFile }
    $wb.SaveAs($outFile, 51)
    $wb.Close($false)
} finally {
    $xl.Quit()
    [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($xl)
}
"saved $outFile"
