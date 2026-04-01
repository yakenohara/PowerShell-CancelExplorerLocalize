<#
    .SYNOPSIS
    Explorer 上のローカライズをキャンセルする

    .DESCRIPTION
    あらかじめ設定されたリストに定義した .ini ファイル内で `LocalizedResourceName=` の定義がある行をコメントアウトする
#>

# =========================
# 設定：対象パス
# =========================
$str_user = $env:USERNAME
$str_userProfile = Join-Path "C:\Users" $str_user

$strarr_paths = @(
    "C:\Users\desktop.ini",
    "$str_userProfile\Contacts\desktop.ini",
    "$str_userProfile\Favorites\desktop.ini",
    "$str_userProfile\AppData\Roaming\Microsoft\Windows\Start Menu\desktop.ini",
    "$str_userProfile\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\desktop.ini",
    "$str_userProfile\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\desktop.ini",
    "$str_userProfile\Downloads\desktop.ini",
    "$str_userProfile\Desktop\desktop.ini",
    "$str_userProfile\Documents\desktop.ini",
    "$str_userProfile\Pictures\desktop.ini",
    "$str_userProfile\Videos\desktop.ini",
    "$str_userProfile\Music\desktop.ini",
    "$str_userProfile\Links\desktop.ini",
    "$str_userProfile\Searches\desktop.ini",
    "$str_userProfile\Saved Games\desktop.ini"
)

# =========================
# カウンタ
# =========================
$int_total = 0
$int_commented = 0
$int_skipped = 0

# =========================
# メイン処理
# =========================
Write-Host "Processing..."

foreach ($str_path in $strarr_paths) {

    Write-Host $str_path
    $int_total++

    try {
        if (-not (Test-Path $str_path)) {
            Write-Warning "File not found: $str_path"
            $int_skipped++
            continue
        }

        # =========================
        # 読み込み
        # =========================
        try {
            [byte[]]$bytes = [System.IO.File]::ReadAllBytes($str_path)

            if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
                $encoding_current = [System.Text.Encoding]::Unicode
            } else {
                $encoding_current = [System.Text.Encoding]::UTF8
            }

            $strarr_lines = [System.IO.File]::ReadAllLines($str_path, $encoding_current)
        }
        catch {
            throw "Read failed: $($_.Exception.Message)"
        }

        # =========================
        # 加工
        # =========================
        $bl_modified = $false

        for ($int_i = 0; $int_i -lt $strarr_lines.Count; $int_i++) {

            if ($strarr_lines[$int_i] -match '^\s*;.*LocalizedResourceName=') {
                continue
            }

            if ($strarr_lines[$int_i] -match '^\s*LocalizedResourceName=') {
                $strarr_lines[$int_i] = ';' + $strarr_lines[$int_i]
                $bl_modified = $true
            }
        }

        if ($bl_modified) {

            # =========================
            # 書き込み（安全版）
            # =========================
            try {
                $str_tempPath = "$str_path.tmp"
                [System.IO.File]::WriteAllLines($str_tempPath, $strarr_lines, $encoding_current)
                Move-Item -Path $str_tempPath -Destination $str_path -Force
            }
            catch {
                throw "Write failed: $($_.Exception.Message)"
            }

            $int_commented++
        }
        else {
            $int_skipped++
        }
    }
    catch {
        Write-Error "Error! processing: $str_path"
        Write-Error $_
        exit 1
    }
}

# =========================
# 結果表示
# =========================
Write-Host "Done!"
Write-Host ""
Write-Host "========RESULT========"
Write-Host ("Total                   : {0}" -f $int_total)
Write-Host ("Number of comment outed : {0}" -f $int_commented)
Write-Host ("Number of skipped       : {0}" -f $int_skipped)
