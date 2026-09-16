@echo off
setlocal
set "CLOCK_SELF=%~f0"
powershell.exe -NoProfile -Sta -WindowStyle Hidden -ExecutionPolicy Bypass -Command "$clockRaw=[System.IO.File]::ReadAllText($env:CLOCK_SELF,[System.Text.Encoding]::UTF8); $clockMarker='__CLOCK_POWERSHELL__'; $clockStart=$clockRaw.LastIndexOf($clockMarker); if($clockStart -lt 0){throw 'Clock code missing'}; $clockCode=$clockRaw.Substring($clockStart+$clockMarker.Length); try { & ([ScriptBlock]::Create($clockCode)) -Taskbar -HideLauncherConsole } catch { Add-Type -AssemblyName PresentationFramework; [void][System.Windows.MessageBox]::Show($_.ToString(),'Clock startup error') }"
exit /b
__CLOCK_POWERSHELL__
param([switch]$SelfTest, [switch]$Taskbar, [switch]$SimpleCheck, [switch]$HideLauncherConsole, [string]$SettingsPath = '')
$ErrorActionPreference = 'Stop'
if ($HideLauncherConsole) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class DigitalClockConsole {
    [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr window, int command);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr window);
}
"@
    $launcherWindow = [DigitalClockConsole]::GetConsoleWindow()
    if ($launcherWindow -ne [IntPtr]::Zero) {
        [void][DigitalClockConsole]::ShowWindow($launcherWindow, 0)
        if ([DigitalClockConsole]::IsWindowVisible($launcherWindow)) {
            [void][DigitalClockConsole]::ShowWindow($launcherWindow, 0)
        }
    }
}
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
$script:scalePercent = 100
$script:taskbarMode = [bool]$Taskbar
$script:manualPosition = $false
$script:positionPath = $(if ($SettingsPath) {
    $SettingsPath
} else {
    Join-Path (Join-Path $env:LOCALAPPDATA 'DigitalClockWidget') 'taskbar-position-visible.json'
})
if (-not $SelfTest) {
    $mutexName = $(if ($script:taskbarMode) {
        'Local\DigitalClockWidget.TaskbarTray'
    } else {
        'Local\DigitalClockWidget.Desktop'
    })
    $script:instanceMutex = New-Object System.Threading.Mutex($false,$mutexName)
    if (-not $script:instanceMutex.WaitOne(0)) {
        Write-Output '時計は既に起動しています。'
        exit 2
    }
}
$script:segmentPoints = @(
    '3,0 17,0 19,2 17,4 3,4 1,2',
    '17,3 19,1 21,3 21,15 19,17 17,15',
    '17,20 19,18 21,20 21,33 19,35 17,33',
    '3,32 17,32 19,34 17,36 3,36 1,34',
    '0,20 2,18 4,20 4,33 2,35 0,33',
    '0,3 2,1 4,3 4,15 2,17 0,15',
    '3,16 17,16 19,18 17,20 3,20 1,18'
)
$script:masks = @('abcdef','bc','abdeg','abcdg','bcfg','acdfg',
                  'acdefg','abc','abcdefg','abcdfg')
$script:digits = @()
$script:onBrush = New-Object System.Windows.Media.SolidColorBrush(
    [System.Windows.Media.Color]::FromRgb(231,244,255))
$script:offBrush = New-Object System.Windows.Media.SolidColorBrush(
    [System.Windows.Media.Color]::FromArgb(65,38,52,62))

function Convert-Points([string]$text) {
    $points = New-Object System.Windows.Media.PointCollection
    foreach ($pair in $text.Split(' ')) {
        $xy = $pair.Split(',')
        $x = [double]::Parse($xy[0], [Globalization.CultureInfo]::InvariantCulture)
        $y = [double]::Parse($xy[1], [Globalization.CultureInfo]::InvariantCulture)
        $points.Add((New-Object System.Windows.Point($x,$y)))
    }
    return ,$points
}

function Add-Digit($face, [double]$x, [double]$y, [double]$size) {
    $group = New-Object System.Windows.Controls.Canvas
    $group.Width = 22
    $group.Height = 36
    $group.RenderTransform = New-Object System.Windows.Media.ScaleTransform($size,$size)
    [System.Windows.Controls.Canvas]::SetLeft($group,$x)
    [System.Windows.Controls.Canvas]::SetTop($group,$y)
    $shapes = @()
    foreach ($points in $script:segmentPoints) {
        $polygon = New-Object System.Windows.Shapes.Polygon
        $polygon.Points = Convert-Points $points
        $polygon.Fill = $script:offBrush
        [void]$group.Children.Add($polygon)
        $shapes += $polygon
    }
    [void]$face.Children.Add($group)
    $script:digits += ,$shapes
}

function Add-Dot($face, [double]$x, [double]$y) {
    $dot = New-Object System.Windows.Shapes.Polygon
    $dot.Points = Convert-Points '1,0 3,0 4,2 3,4 1,4 0,2'
    $dot.Fill = $script:onBrush
    [System.Windows.Controls.Canvas]::SetLeft($dot,$x)
    [System.Windows.Controls.Canvas]::SetTop($dot,$y)
    [void]$face.Children.Add($dot)
}

function Add-Control($root, [string]$label, [double]$top, [string]$tip) {
    $border = New-Object System.Windows.Controls.Border
    $border.Width = 12
    $border.Height = 11
    $border.CornerRadius = New-Object System.Windows.CornerRadius(2)
    $border.Background = New-Object System.Windows.Media.SolidColorBrush(
        [System.Windows.Media.Color]::FromArgb(220,40,40,40))
    $border.Cursor = [System.Windows.Input.Cursors]::Hand
    $border.ToolTip = $tip
    $border.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $border.VerticalAlignment = [System.Windows.VerticalAlignment]::Top
    $border.Margin = New-Object System.Windows.Thickness(0,$top,2,0)
    $text = New-Object System.Windows.Controls.TextBlock
    $text.Text = $label
    $text.FontFamily = New-Object System.Windows.Media.FontFamily('Arial')
    $text.FontSize = 11
    $text.Foreground = [System.Windows.Media.Brushes]::White
    $text.TextAlignment = [System.Windows.TextAlignment]::Center
    $text.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $border.Child = $text
    [void]$root.Children.Add($border)
    return $border
}

function Update-Clock {
    $now = Get-Date
    $values = @(
        ([int][math]::Floor($now.Hour/10)), ($now.Hour % 10),
        ([int][math]::Floor($now.Minute/10)), ($now.Minute % 10),
        ([int][math]::Floor($now.Second/10)), ($now.Second % 10)
    )
    for ($d=0; $d -lt 6; $d++) {
        $mask = $script:masks[$values[$d]]
        for ($s=0; $s -lt 7; $s++) {
            $script:digits[$d][$s].Fill =
                $(if ($mask.Contains('abcdefg'[$s])) {
                    $script:onBrush
                  } else {
                    $script:offBrush
                  })
        }
    }
}

function Update-Scale {
    $factor = $script:scalePercent / 100.0
    $script:root.LayoutTransform =
        New-Object System.Windows.Media.ScaleTransform($factor,$factor)
    $script:plus.Opacity = $(if ($script:scalePercent -eq 200) {0.4} else {1})
    $script:minus.Opacity = $(if ($script:scalePercent -eq 100) {0.4} else {1})
    if ($script:taskbarMode) {
        if ($script:manualPosition) {
            Clamp-Position
        } else {
            Update-TaskbarPosition
        }
        Raise-Clock
    }
}

function Clamp-Position {
    $left = [System.Windows.SystemParameters]::VirtualScreenLeft
    $top = [System.Windows.SystemParameters]::VirtualScreenTop
    $right = $left + [System.Windows.SystemParameters]::VirtualScreenWidth
    $bottom = $top + [System.Windows.SystemParameters]::VirtualScreenHeight
    $width = 154 * $script:scalePercent / 100.0
    $height = 40 * $script:scalePercent / 100.0
    $script:clockWindow.Left = [math]::Max($left,
        [math]::Min($script:clockWindow.Left,$right - $width))
    $script:clockWindow.Top = [math]::Max($top,
        [math]::Min($script:clockWindow.Top,$bottom - $height))
}

function Load-Position {
    if (-not $script:taskbarMode -or
        -not (Test-Path -LiteralPath $script:positionPath)) { return }
    try {
        $record = Get-Content -LiteralPath $script:positionPath -Raw |
            ConvertFrom-Json
        $left = [double]$record.Left
        $top = [double]$record.Top
        if ([double]::IsNaN($left) -or [double]::IsNaN($top) -or
            [double]::IsInfinity($left) -or [double]::IsInfinity($top)) {
            return
        }
        $script:clockWindow.Left = $left
        $script:clockWindow.Top = $top
        $script:manualPosition = $true
        Clamp-Position
    } catch {}
}

function Save-Position {
    if (-not $script:taskbarMode -or -not $script:manualPosition) { return }
    try {
        $folder = Split-Path -Parent $script:positionPath
        [void](New-Item -ItemType Directory -Path $folder -Force)
        $record = [pscustomobject]@{
            Left = [math]::Round($script:clockWindow.Left,2)
            Top = [math]::Round($script:clockWindow.Top,2)
        }
        $record | ConvertTo-Json -Compress |
            Set-Content -LiteralPath $script:positionPath -Encoding UTF8
    } catch {}
}

function Raise-Clock {
    if (-not $script:taskbarMode -or -not $script:clockWindow.IsVisible) {
        return
    }
    $script:clockWindow.Topmost = $true
}

function Update-TaskbarPosition {
    if ($script:manualPosition) { return }
    $work = [System.Windows.SystemParameters]::WorkArea
    $screenWidth = [System.Windows.SystemParameters]::PrimaryScreenWidth
    $screenHeight = [System.Windows.SystemParameters]::PrimaryScreenHeight
    $width = 154 * $script:scalePercent / 100.0
    $height = 40 * $script:scalePercent / 100.0

    if ($work.Bottom -lt $screenHeight - 1) {
        $script:clockWindow.Left = [math]::Max(0,$screenWidth - $width - 2)
        $script:clockWindow.Top = [math]::Max(0,$work.Bottom - $height - 2)
    } elseif ($work.Top -gt 1) {
        $script:clockWindow.Left = [math]::Max(0,$screenWidth - $width - 2)
        $script:clockWindow.Top = $work.Top + 2
    } elseif ($work.Right -lt $screenWidth - 1) {
        $script:clockWindow.Left = [math]::Max(0,$work.Right - $width - 2)
        $script:clockWindow.Top = [math]::Max(0,$screenHeight - $height - 2)
    } elseif ($work.Left -gt 1) {
        $script:clockWindow.Left = $work.Left + 2
        $script:clockWindow.Top = [math]::Max(0,$screenHeight - $height - 2)
    } else {
        $script:clockWindow.Left = [math]::Max(0,$screenWidth - $width - 2)
        $script:clockWindow.Top = [math]::Max(0,$screenHeight - $height - 2)
    }
}

function Change-Scale([int]$delta) {
    $next = $script:scalePercent + $delta
    if ($next -lt 100 -or $next -gt 200) { return }
    $script:scalePercent = $next
    Update-Scale
    if ($script:manualPosition) { Save-Position }
}

function Show-Clock {
    if ($script:clockWindow.Dispatcher.CheckAccess()) {
        [void]$script:clockWindow.Activate()
        Raise-Clock
    } else {
        [void]$script:clockWindow.Dispatcher.BeginInvoke([Action]{
            [void]$script:clockWindow.Activate()
            Raise-Clock
        })
    }
}

function Close-Clock {
    if ($script:clockWindow.Dispatcher.CheckAccess()) {
        $script:clockWindow.Close()
    } else {
        [void]$script:clockWindow.Dispatcher.BeginInvoke([Action]{
            $script:clockWindow.Close()
        })
    }
}

function Reset-ClockPosition {
    $action = [Action]{
        $script:manualPosition = $false
        Remove-Item -LiteralPath $script:positionPath -ErrorAction SilentlyContinue
        Update-TaskbarPosition
        Show-Clock
    }
    if ($script:clockWindow.Dispatcher.CheckAccess()) {
        $action.Invoke()
    } else {
        [void]$script:clockWindow.Dispatcher.BeginInvoke($action)
    }
}

$script:clockWindow = New-Object System.Windows.Window
$script:clockWindow.Title = 'デジタル時計'
$script:clockWindow.WindowStyle = [System.Windows.WindowStyle]::None
$script:clockWindow.ResizeMode = [System.Windows.ResizeMode]::NoResize
$script:clockWindow.AllowsTransparency = $true
$script:clockWindow.Background = [System.Windows.Media.Brushes]::Transparent
$script:clockWindow.ShowInTaskbar = $true
$script:clockWindow.SizeToContent = [System.Windows.SizeToContent]::WidthAndHeight
$script:clockWindow.WindowStartupLocation =
    [System.Windows.WindowStartupLocation]::CenterScreen
if ($script:taskbarMode) {
    $script:clockWindow.ShowInTaskbar = $false
    $script:clockWindow.Topmost = $true
    $script:clockWindow.WindowStartupLocation =
        [System.Windows.WindowStartupLocation]::Manual
}

$script:root = New-Object System.Windows.Controls.Grid
$script:root.Width = 154
$script:root.Height = 40
$plate = New-Object System.Windows.Controls.Border
$plate.Width = 154
$plate.Height = 40
$plate.CornerRadius = New-Object System.Windows.CornerRadius(3)
$plate.Background = New-Object System.Windows.Media.SolidColorBrush(
    [System.Windows.Media.Color]::FromArgb(179,0,0,0))
$plate.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
$plate.VerticalAlignment = [System.Windows.VerticalAlignment]::Top
[void]$script:root.Children.Add($plate)

$face = New-Object System.Windows.Controls.Canvas
$face.Width = 136
$face.Height = 36
$face.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
$face.VerticalAlignment = [System.Windows.VerticalAlignment]::Top
$face.Margin = New-Object System.Windows.Thickness(2,2,0,0)
[void]$script:root.Children.Add($face)
Add-Digit $face 0 0 1
Add-Digit $face 24 0 1
Add-Dot $face 50 9
Add-Dot $face 50 24
Add-Digit $face 57 0 1
Add-Digit $face 81 0 1
Add-Digit $face 109 16 0.55
Add-Digit $face 123 16 0.55

$script:close = Add-Control $script:root '×' 2 '終了'
$script:plus = Add-Control $script:root '+' 14 '25％拡大'
$script:minus = Add-Control $script:root '−' 26 '25％縮小'
$script:close.Visibility = [System.Windows.Visibility]::Hidden
$script:root.Add_MouseEnter({
    $script:close.Visibility = [System.Windows.Visibility]::Visible
})
$script:root.Add_MouseLeave({
    $script:close.Visibility = [System.Windows.Visibility]::Hidden
})
$script:close.Add_MouseLeftButtonDown({
    param($sender,$eventArgs)
    $eventArgs.Handled = $true
    $script:clockWindow.Close()
})
$script:plus.Add_MouseLeftButtonDown({
    param($sender,$eventArgs)
    $eventArgs.Handled = $true
    Change-Scale 25
})
$script:minus.Add_MouseLeftButtonDown({
    param($sender,$eventArgs)
    $eventArgs.Handled = $true
    Change-Scale -25
})
$script:clockWindow.Content = $script:root
$script:clockWindow.Add_Loaded({
    if ($script:taskbarMode) {
        Update-TaskbarPosition
        Raise-Clock
    }
})
$script:clockWindow.Add_MouseLeftButtonDown({
    param($sender,$eventArgs)
    if (-not $eventArgs.Handled) {
        if ($script:taskbarMode) { $script:manualPosition = $true }
        try { $script:clockWindow.DragMove() } catch {}
        if ($script:taskbarMode) {
            Clamp-Position
            Save-Position
            Raise-Clock
        }
    }
})

Load-Position
Update-Scale
Update-Clock
$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromMilliseconds(250)
$script:positionTick = 0
$timer.Add_Tick({
    Update-Clock
    if ($script:taskbarMode) {
        $script:positionTick++
        if ($script:positionTick -ge 4) {
            $script:positionTick = 0
            Update-TaskbarPosition
            Raise-Clock
        }
    }
})
$timer.Start()
if ($script:taskbarMode) {
    $script:trayIcon = New-Object System.Windows.Forms.NotifyIcon
    $script:iconStream = [System.IO.MemoryStream]::new(
        [Convert]::FromBase64String('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'))
    $script:trayIcon.Icon = New-Object System.Drawing.Icon(
        $script:iconStream)
    $script:trayIcon.Text = 'デジタル時計'
    $script:trayMenu = New-Object System.Windows.Forms.ContextMenuStrip
    $showItem = $script:trayMenu.Items.Add('時計を前面に表示')
    $resetItem = $script:trayMenu.Items.Add('時計を右下に戻す')
    $exitItem = $script:trayMenu.Items.Add('終了')
    $showItem.Add_Click({ Show-Clock })
    $resetItem.Add_Click({ Reset-ClockPosition })
    $exitItem.Add_Click({ Close-Clock })
    $script:trayIcon.ContextMenuStrip = $script:trayMenu
    $script:trayIcon.Add_DoubleClick({ Show-Clock })
    if (-not $SelfTest) { $script:trayIcon.Visible = $true }
}
if ($SelfTest) {
    if ($SimpleCheck) {
        Write-Output '起動チェックが完了しました。時計を開きます。'
    } else {
        Write-Output ('Ready: digits=' + $script:digits.Count +
            ', panel=' + $script:root.Width + 'x' + $script:root.Height +
            ', background alpha=' + $plate.Background.Color.A +
            ', taskbar=' + $script:taskbarMode +
            ', position=' + $script:clockWindow.Left + ',' + $script:clockWindow.Top +
            ', tray=' + [bool]($script:trayIcon -and $script:trayIcon.Icon))
        if ($script:taskbarMode) {
            1..4 | ForEach-Object { Change-Scale 25 }
            Write-Output ('At 200%: position=' + $script:clockWindow.Left +
                ',' + $script:clockWindow.Top +
                ', size=' + (154*$script:scalePercent/100) + 'x' +
                (40*$script:scalePercent/100))
        }
    }
} else {
    try {
        [void]$script:clockWindow.ShowDialog()
    } finally {
        if ($script:trayIcon) {
            $script:trayIcon.Visible = $false
            $script:trayIcon.Dispose()
            $script:trayMenu.Dispose(); if($script:iconStream){$script:iconStream.Dispose()}
        }
        $script:instanceMutex.ReleaseMutex()
        $script:instanceMutex.Dispose()
    }
}
