# Step 1 of the translation check (see README.md): writes only-<lang>.txt (id<TAB>translation, no German)
# for the blind back-translators, and all.json with German + all translations for make-xlsx.ps1.
param([string]$WorkDir = "$PSScriptRoot\..\..\Stuff(gitignored)\translation-check")
$ErrorActionPreference = 'Stop'
$root = "$PSScriptRoot\..\..\i18n"
New-Item -ItemType Directory -Force $WorkDir | Out-Null
$out = (Resolve-Path $WorkDir).Path
$langs = 'en','es','fr','it','nl','pt_BR'
$rows = [System.Collections.ArrayList]::new()
foreach ($lang in $langs) {
    [xml]$ts = [System.IO.File]::ReadAllText("$root\FaceZapper_$lang.ts", [System.Text.Encoding]::UTF8)
    $i = 0
    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($ctx in $ts.TS.context) {
        foreach ($m in $ctx.message) {
            $tr = $m.SelectSingleNode('translation')
            $nf = $tr.SelectNodes('numerusform')
            if ($nf.Count -gt 0) { $text = ($nf | ForEach-Object { $_.InnerText }) -join ' || ' }
            else { $text = $tr.InnerText }
            if ($lang -eq 'en') {
                [void]$rows.Add([ordered]@{ id = $i; ctx = $ctx.name; comment = "$($m.SelectSingleNode('comment').InnerText)"; de = $m.SelectSingleNode('source').InnerText })
            }
            $rows[$i][$lang] = $text
            $lines.Add("$i`t" + ($text -replace "`r?`n", '\n'))
            $i++
        }
    }
    [System.IO.File]::WriteAllLines("$out\only-$lang.txt", $lines, [System.Text.UTF8Encoding]::new($false))
}
$rows | ConvertTo-Json -Depth 4 | Set-Content -Encoding utf8 "$out\all.json"
"rows: $($rows.Count)"
