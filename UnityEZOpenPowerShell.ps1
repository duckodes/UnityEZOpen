# Unity �s�边���|
$unityExe = "C:\Program Files\Unity\Hub\Editor\2022.3.44f1\Editor\Unity.exe"
$projectsFile = Join-Path $PSScriptRoot "Setup.txt"

if (!(Test-Path $projectsFile)) {
    Write-Host "���~�G�䤣��M�ײM���ɮ� '$projectsFile'" -ForegroundColor Red
    Read-Host "�����N��h�X"
    exit
}

# �ѪR�M�ײM��
$projects = @()
foreach ($line in Get-Content $projectsFile) {
    if ($line -match "^(.*?)\|(.*?)$") {
        $name = $matches[1].Trim()
        $basePath = $matches[2].Trim()
        $unityPath = $basePath
        $slnPath = Join-Path $unityPath "Unity.sln"

        # Unity Version
        $versionFile = Join-Path $unityPath "ProjectSettings\ProjectVersion.txt"
        $unityVersion = "��������"
        if (Test-Path $versionFile) {
            $versionLine = Select-String "m_EditorVersion" $versionFile -ErrorAction SilentlyContinue
            if ($versionLine) {
                $unityVersion = ($versionLine.Line -split ":")[1].Trim()
            }
        }

        # Bundle Version�]���̫�@�q�^
        $playerFile = Join-Path $unityPath "ProjectSettings\ProjectSettings.asset"
        $bundleVersion = "��������"
        if (Test-Path $playerFile) {
            $bundleLine = Select-String "bundleVersion:" $playerFile -ErrorAction SilentlyContinue
            if ($bundleLine) {
                $tokens = $bundleLine.Line -split "\s+"
                $bundleVersion = $tokens[-1].Trim()
            }
        }

        # Git Branch
        $branch = "��������"
        try {
            $branch = git -C $basePath rev-parse --abbrev-ref HEAD
        } catch {
            $branch = "�L�k���o����"
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

# ��ܿ��
$index = 0
function ShowMenu {
    Clear-Host
    Write-Host "===== Unity �M�ײM�� =====`n"
    for ($i = 0; $i -lt $projects.Count; $i++) {
        $p = $projects[$i]
        $selected = ($i -eq $index)
        $prefix = if ($selected) {">"} else {" "}
        if ($selected) {
            Write-Host "$prefix [$($i + 1)] $($p.Name)" -ForegroundColor Cyan
            Write-Host "    Unity�����G $($p.UnityVersion)" -ForegroundColor Cyan
            Write-Host "    bundleVersion�G $($p.BundleVersion)" -ForegroundColor Cyan
            Write-Host "    git����G $($p.Branch)`n" -ForegroundColor Cyan
        } else {
            Write-Host "$prefix [$($i + 1)] $($p.Name)"
            Write-Host "    Unity�����G $($p.UnityVersion)"
            Write-Host "    bundleVersion�G $($p.BundleVersion)"
            Write-Host "    git����G $($p.Branch)`n"
        }
    }
    Write-Host "���� ��ܶ��ءAEnter �Ұ�"
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

# ����M��
$selected = $projects[$index]
Write-Host "`n�ҰʱM�סG$($selected.Name)"
Start-Process $unityExe -ArgumentList "-projectPath `"$($selected.Path)`""
if (Test-Path $selected.Sln) {
    Start-Process $selected.Sln
} else {
    Write-Host "����� Unity.sln �ɮ�"
}