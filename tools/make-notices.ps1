# Builds licenses/THIRD-PARTY-NOTICES.txt (and copies LGPL-3.0.txt, GPL-3.0.txt) from Qt's own
# qt_attribution.json files for the third-party code that this Qt build bundles into the Android app,
# plus the NDK's libc++. Run again after a Qt update (versions and texts change):
#   powershell -ExecutionPolicy Bypass -File tools\make-notices.ps1
param([string]$OutDir = "$PSScriptRoot\..\licenses")
$src = "C:\Qt\6.12.0\Src"   # Qt sources on this machine (Maintenance Tool: component "Sources")
$jsons = @(
    "qtbase\src\3rdparty\freetype", "qtbase\src\3rdparty\harfbuzz-ng", "qtbase\src\3rdparty\libpng",
    "qtbase\src\3rdparty\libjpeg", "qtbase\src\3rdparty\pcre2", "qtbase\src\3rdparty\double-conversion",
    "qtbase\src\3rdparty\sha3", "qtbase\src\3rdparty\tinycbor", "qtbase\src\3rdparty\md4c",
    "qtimageformats\src\3rdparty\libwebp", "qtimageformats\src\3rdparty\libtiff",
    "qtdeclarative\src\3rdparty\masm"
)
New-Item -ItemType Directory -Force $OutDir | Out-Null
$sb = New-Object System.Text.StringBuilder
$line = "=" * 78
[void]$sb.AppendLine("FaceZapper - Hinweise zu Drittanbieter-Software / Third-party notices")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("FaceZapper verwendet Qt 6.12 (The Qt Company Ltd. und andere) unter der GNU LGPL v3")
[void]$sb.AppendLine("(siehe LGPL-3.0.txt und GPL-3.0.txt). Qt enthaelt die folgenden Bibliotheken anderer Autoren.")
[void]$sb.AppendLine("")
foreach ($dir in $jsons) {
    $jsonPath = Join-Path $src "$dir\qt_attribution.json"
    $entries = Get-Content $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($e in @($entries)) {
        [void]$sb.AppendLine($line)
        [void]$sb.AppendLine("$($e.Name)$(if ($e.Version) { ' ' + $e.Version })")
        [void]$sb.AppendLine("Lizenz / License: $($e.License)")
        foreach ($c in @($e.Copyright)) { if ($c) { [void]$sb.AppendLine($c) } }
        [void]$sb.AppendLine($line)
        $files = @()
        if ($e.LicenseFile) { $files += $e.LicenseFile }
        if ($e.LicenseFiles) { $files += $e.LicenseFiles }
        foreach ($f in $files) {
            $p = Join-Path (Join-Path $src $dir) $f
            if (Test-Path $p) { [void]$sb.AppendLine((Get-Content $p -Raw -Encoding UTF8).TrimEnd()); [void]$sb.AppendLine("") }
            else { Write-Warning "missing license file: $p" }
        }
    }
}
# C++ runtime from the Android NDK
[void]$sb.AppendLine($line)
[void]$sb.AppendLine("LLVM libc++ (libc++_shared.so, Android NDK r27c)")
[void]$sb.AppendLine("Lizenz / License: Apache License v2.0 with LLVM Exceptions")
[void]$sb.AppendLine("Copyright (c) 2009-2019 by the contributors listed in CREDITS.TXT (LLVM Project)")
[void]$sb.AppendLine($line)
[void]$sb.AppendLine((Get-Content "$src\qtbase\LICENSES\Apache-2.0.txt" -Raw -Encoding UTF8).TrimEnd())
[void]$sb.AppendLine("")
[void]$sb.AppendLine("---- LLVM Exceptions to the Apache 2.0 License ----")
[void]$sb.AppendLine("As an exception, if, as a result of your compiling your source code, portions of this Software are")
[void]$sb.AppendLine("embedded into an Object form of such source code, you may redistribute such embedded portions in such")
[void]$sb.AppendLine("Object form without complying with the conditions of Sections 4(a), 4(b) and 4(d) of the License.")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("In addition, if you combine or link compiled forms of this Software with software that is licensed under")
[void]$sb.AppendLine("the GPLv2 (""Combined Software"") and if a court of competent jurisdiction determines that the patent")
[void]$sb.AppendLine("provision (Section 3), the indemnity provision (Section 9) or other Section of the License conflicts with")
[void]$sb.AppendLine("the conditions of the GPLv2, you may retroactively and prospectively choose to deem waived or otherwise")
[void]$sb.AppendLine("exclude such Section(s) of the License, but only in their entirety and only with respect to the Combined")
[void]$sb.AppendLine("Software.")
[System.IO.File]::WriteAllText("$OutDir\THIRD-PARTY-NOTICES.txt", $sb.ToString(), (New-Object System.Text.UTF8Encoding $false))
Copy-Item "$src\qtbase\LICENSES\LGPL-3.0-only.txt" "$OutDir\LGPL-3.0.txt" -Force
Copy-Item "$src\qtbase\LICENSES\GPL-3.0-only.txt" "$OutDir\GPL-3.0.txt" -Force
Get-ChildItem $OutDir | Select-Object Name, Length
