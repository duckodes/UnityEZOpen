Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$unityExe = "C:\Program Files\Unity\Hub\Editor\2022.3.44f1\Editor\Unity.exe"
$projectsFile = Join-Path $PSScriptRoot "Setup.txt"

if (!(Test-Path $projectsFile)) {
    [System.Windows.Forms.MessageBox]::Show("找不到專案清單檔案：$projectsFile")
    exit
}

# 讀取專案清單
$projects = @()
Get-Content $projectsFile | ForEach-Object {
    $parts = $_ -split '\|'
    if ($parts.Count -ge 2) {
        $name = $parts[0].Trim()
        $path = $parts[1].Trim()

        # Git 分支
        $branch = "未知分支"
        try {
            $branch = git -C $path rev-parse --abbrev-ref HEAD
        } catch {
            $branch = "無法取得分支（確認路徑與 Git 專案）"
        }

        # Submodule 分支
        <#$submoduleInfo = git -C $path submodule
        $subName = "unknown未知名稱"
        $subBranch = "unknown未知分支"
        $submoduleInfo | ForEach-Object {
            $parts = $_ -split '\s+'
            $fullPath = $parts[1]
            $subName = Split-Path $fullPath -Leaf
            if ($_ -match '\((.*?)\)$') {
                $subBranch = $matches[1]
            } else {
                $subBranch = "unknown未知分支"
            }
        }#>

        # Unity 版本
        $unityVersion = "未知版本"
        $versionFile = Join-Path $path "ProjectSettings\ProjectVersion.txt"
        if (Test-Path $versionFile) {
            $lines = Get-Content $versionFile
            foreach ($line in $lines) {
                if ($line -match "m_EditorVersion:\s*(.+)$") {
                    $unityVersion = $matches[1].Trim()
                    break
                }
            }
        }

        # bundleVersion
        $bundleVersion = "未知版本"
        $playerFile = Join-Path $path "ProjectSettings\ProjectSettings.asset"
        if (Test-Path $playerFile) {
            $lines = Get-Content $playerFile
            foreach ($line in $lines) {
                if ($line -match "^\s*bundleVersion:\s*(.+)$") {
                    $bundleVersion = $matches[1].Trim()
                    break
                }
            }
        }

        $projects += [PSCustomObject]@{
            Name = $name
            Path = $path
            Branch = $branch
            UnityVersion = $unityVersion
            BundleVersion = $bundleVersion
            SubName = $subName
            SubBranch = $subBranch
        }
    }
}

# UI 設定
$form = New-Object System.Windows.Forms.Form
$form.Text = "Unity 專案選單"
$form.Size = New-Object System.Drawing.Size(700, [Math]::Min(130 + ($projects.Count * 60), 800))
$form.StartPosition = "CenterScreen"
$form.Topmost = $true
$form.AutoScroll = $true
$form.BackColor = [System.Drawing.Color]::FromArgb(0,90,158)
$form.SizeGripStyle = [System.Windows.Forms.SizeGripStyle]::Hide
#$form.FormBorderStyle = "None"
$form.Add_Deactivate({
    $form.Close()
})
$form.ShowInTaskbar = $false

# 設定視窗圖標
$iconPath = Join-Path $PSScriptRoot "UnityEZOpenForm.ico"
if (Test-Path $iconPath) {
    $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($iconPath)
}

# 關閉按鈕
$closeBtn = New-Object System.Windows.Forms.Button
<#$closeBtn.Text = "×"
$closeBtn.Size = New-Object System.Drawing.Size(50, 35)
$closeBtnXOffset = $form.ClientSize.Width - $closeBtn.ClientSize.Width * 0.7
$closeBtn.Location = New-Object System.Drawing.Point($closeBtnXOffset, 1)
$closeBtn.Font = New-Object System.Drawing.Font("Microsoft JhengHei", 18)
$closeBtn.BackColor = [System.Drawing.Color]::White
$closeBtn.ForeColor = [System.Drawing.Color]::FromArgb(150,150,150)
$closeBtn.FlatStyle = 'Flat'
$closeBtn.FlatAppearance.BorderSize = 0
$closeBtn.Add_Click({
    $form.Close()
})
$form.Controls.Add($closeBtn)#>

$yOffset = 10
foreach ($proj in $projects) {
    $btn = New-Object System.Windows.Forms.Button
    $text = "$($proj.Name)`nUnity版本：$($proj.UnityVersion)`nBundleVersion：$($proj.BundleVersion)`nGit分支：$($proj.Branch)"# + "`nSubmodule分支($($proj.SubName))：$($proj.SubBranch)"
    $lineCount = ($text -split "`n").Count
    $btnHeight = $lineCount * 20 + 10

    $btn.Text = $text
    $btn.Size = New-Object System.Drawing.Size(660, $btnHeight)
    $btn.Location = New-Object System.Drawing.Point(10, $yOffset)
    $btn.Font = New-Object System.Drawing.Font("Microsoft JhengHei", 10, [System.Drawing.FontStyle]::Bold)
    $btn.BackColor = [System.Drawing.Color]::FromArgb(52,152,219)
    $btn.FlatAppearance.BorderSize = 0

    # 美化按鈕樣式
    $btn.ForeColor = [System.Drawing.Color]::White
    $btn.FlatStyle = 'Flat'

    # 把每個 $proj 存到按鈕的 Tag 屬性
    $btn.Tag = $proj

    $btn.Add_Click({
        param($sender, $eventArgs)
        $projData = $sender.Tag  # 從 sender 拿回對應專案資料

        Start-Process $unityExe -ArgumentList "-projectPath `"$($projData.Path)`""
        $slnPath = Join-Path $projData.Path "Unity.sln"
        if (Test-Path $slnPath) {
            Start-Process $slnPath
        }
        $form.Close()
    })

    $form.Controls.Add($btn)
    $yOffset += ($btnHeight + 10)
    # 置中所有按鈕
    $form.Add_Resize({
        $totalHeight = 0

        foreach ($ctrl in $form.Controls) {
            if ($ctrl -is [System.Windows.Forms.Button] -and $ctrl -ne $closeBtn) {
                $ctrl.Width = $form.ClientSize.Width - 20

                # 抓顯示所需高度（TextRenderer 預測顯示效果）
                $textSize = [System.Windows.Forms.TextRenderer]::MeasureText(
                    $ctrl.Text,
                    $ctrl.Font,
                    [System.Drawing.Size]::new($ctrl.Width, 9999),
                    [System.Windows.Forms.TextFormatFlags]::WordBreak
                )

                # 使用 Font.Height 或指定的單行高計算行數
                $lineHeight = $ctrl.Font.Height
                $lineCount = [math]::Ceiling($textSize.Height / $lineHeight)

                # 最小限制：若沒有換行，也至少顯示一行
                if ($lineCount -lt 1) { $lineCount = 1 }

                $ctrl.Height = $lineCount * $lineHeight + 10
                $totalHeight += $ctrl.Height + 10
            }
        }

        # 垂直置中排列
        $startY = [Math]::Max(10, ($form.ClientSize.Height - $totalHeight) / 2)
        foreach ($ctrl in $form.Controls) {
            if ($ctrl -is [System.Windows.Forms.Button]) {
                if ($ctrl -ne $closeBtn) {
                    $ctrl.Left = ($form.ClientSize.Width - $ctrl.Width) / 2
                    $ctrl.Top  = $startY
                }
                $startY += $ctrl.Height + 10
            }
        }
    })
}

$form.ShowDialog()