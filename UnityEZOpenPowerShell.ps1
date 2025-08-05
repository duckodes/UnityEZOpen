# Unity 編輯器路徑
$unityExe = "C:\Program Files\Unity\Hub\Editor\2022.3.44f1\Editor\Unity.exe"
$projectsFile = Join-Path $PSScriptRoot "Setup.txt"

if (!(Test-Path $projectsFile)) {
    Write-Host "錯誤：找不到專案清單檔案 '$projectsFile'" -ForegroundColor Red
    Read-Host "按任意鍵退出"
    exit
}

# 解析專案清單
$projects = @()
foreach ($line in Get-Content $projectsFile) {
    if ($line -match "^(.*?)\|(.*?)$") {
        $name = $matches[1].Trim()
        $basePath = $matches[2].Trim()
        $unityPath = $basePath
        $slnPath = Join-Path $unityPath "Unity.sln"

        # Unity Version
        $versionFile = Join-Path $unityPath "ProjectSettings\ProjectVersion.txt"
        $unityVersion = "未知版本"
        if (Test-Path $versionFile) {
            $versionLine = Select-String "m_EditorVersion" $versionFile -ErrorAction SilentlyContinue
            if ($versionLine) {
                $unityVersion = ($versionLine.Line -split ":")[1].Trim()
            }
        }

        # Bundle Version（取最後一段）
        $playerFile = Join-Path $unityPath "ProjectSettings\ProjectSettings.asset"
        $bundleVersion = "未知版本"
        if (Test-Path $playerFile) {
            $bundleLine = Select-String "bundleVersion:" $playerFile -ErrorAction SilentlyContinue
            if ($bundleLine) {
                $tokens = $bundleLine.Line -split "\s+"
                $bundleVersion = $tokens[-1].Trim()
            }
        }

        # Git Branch
        $branch = "未知分支"
        try {
            $branch = git -C $basePath rev-parse --abbrev-ref HEAD
        } catch {
            $branch = "無法取得分支"
        }

        $projects += [PSCustomObject]@{
            Name          = $name
            Path          = $unityPath
            Sln           = $slnPath
            UnityVersion  = $unityVersion
            BundleVersion = $bundleVersion
            Branch        = $branch
        }
    }
}

# 顯示選單
$index = 0
function ShowMenu {
    Clear-Host
    Write-Host "===== Unity 專案清單 =====`n"
    for ($i = 0; $i -lt $projects.Count; $i++) {
        $p = $projects[$i]
        $selected = ($i -eq $index)
        $prefix = if ($selected) {">"} else {" "}
        if ($selected) {
            Write-Host "$prefix [$($i + 1)] $($p.Name)" -ForegroundColor Cyan
            Write-Host "    Unity版本： $($p.UnityVersion)" -ForegroundColor Cyan
            Write-Host "    bundleVersion： $($p.BundleVersion)" -ForegroundColor Cyan
            Write-Host "    git分支： $($p.Branch)`n" -ForegroundColor Cyan
        } else {
            Write-Host "$prefix [$($i + 1)] $($p.Name)"
            Write-Host "    Unity版本： $($p.UnityVersion)"
            Write-Host "    bundleVersion： $($p.BundleVersion)"
            Write-Host "    git分支： $($p.Branch)`n"
        }
    }
    Write-Host "↑↓ 選擇項目，Enter 啟動"
}

[console]::TreatControlCAsInput = $true
$selectionMade = $false
while (-not $selectionMade) {
    ShowMenu
    $key = [console]::ReadKey($true).Key
    switch ($key) {
        "UpArrow"   { if ($index -gt 0) { $index-- } }
        "DownArrow" { if ($index -lt $projects.Count - 1) { $index++ } }
        "Enter"     { $selectionMade = $true }
    }
}

# 執行專案
$selected = $projects[$index]
Write-Host "`n啟動專案：$($selected.Name)"
Start-Process $unityExe -ArgumentList "-projectPath `"$($selected.Path)`""
if (Test-Path $selected.Sln) {
    Start-Process $selected.Sln
} else {
    Write-Host "未找到 Unity.sln 檔案"
}