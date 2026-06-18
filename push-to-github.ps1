# LexiFlow 一键推送脚本
# 自动安装 Git 并推送代码到 GitHub

Write-Host "=== LexiFlow GitHub 推送助手 ===" -ForegroundColor Cyan

# 检查 Git 是否已安装
$gitPath = Get-Command git -ErrorAction SilentlyContinue

if (-not $gitPath) {
    Write-Host "Git 未安装，正在下载..." -ForegroundColor Yellow
    
    # 下载 Git for Windows
    $gitInstaller = "$env:TEMP\Git-2.43.0-64-bit.exe"
    $gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.43.0.windows.1/Git-2.43.0-64-bit.exe"
    
    try {
        Invoke-WebRequest -Uri $gitUrl -OutFile $gitInstaller -UseBasicParsing
        Write-Host "Git 下载完成，正在安装（请稍候，会弹出安装向导）..." -ForegroundColor Yellow
        
        # 静默安装 Git
        Start-Process -FilePath $gitInstaller -ArgumentList "/VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /COMPONENTS=icons,ext\reg\shellhere,assoc,assoc_sh" -Wait
        
        # 刷新环境变量
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        
        Write-Host "Git 安装完成！" -ForegroundColor Green
    } catch {
        Write-Host "自动下载失败，请手动下载安装: https://git-scm.com/download/win" -ForegroundColor Red
        Write-Host "安装完成后重新运行此脚本" -ForegroundColor Yellow
        pause
        exit
    }
}

# 再次检查 Git
$gitPath = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitPath) {
    # 尝试常见安装路径
    $possiblePaths = @(
        "C:\Program Files\Git\bin\git.exe",
        "C:\Program Files (x86)\Git\bin\git.exe",
        "$env:LOCALAPPDATA\Programs\Git\bin\git.exe"
    )
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $env:Path += ";$([System.IO.Path]::GetDirectoryName($path))"
            break
        }
    }
}

# 验证 Git 可用
try {
    $gitVersion = git --version 2>&1
    Write-Host "Git 版本: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "Git 安装后需要重启终端，请关闭并重新打开 PowerShell 再运行此脚本" -ForegroundColor Red
    pause
    exit
}

# 设置 Git 用户信息
Write-Host "配置 Git 用户信息..." -ForegroundColor Cyan
git config --global user.name "qwer2385-stra"
git config --global user.email "qwer2385-stra@users.noreply.github.com"

# 获取当前目录
$repoPath = $PSScriptRoot
if (-not $repoPath) {
    $repoPath = Get-Location
}

Set-Location $repoPath
Write-Host "工作目录: $repoPath" -ForegroundColor Gray

# 初始化 Git 仓库（如果没有）
if (-not (Test-Path .git)) {
    Write-Host "初始化 Git 仓库..." -ForegroundColor Cyan
    git init
    git branch -m main
}

# 添加所有文件
Write-Host "添加文件到 Git..." -ForegroundColor Cyan
git add -A

# 提交
Write-Host "创建提交..." -ForegroundColor Cyan
git commit -m "Initial commit: LexiFlow iOS English learning app" 2>&1 | Out-Null

# 添加远程仓库
Write-Host "配置 GitHub 远程仓库..." -ForegroundColor Cyan
git remote remove origin 2>$null
git remote add origin https://github.com/qwer2385-stra/LexiFlow.git

# 推送代码
Write-Host "推送到 GitHub（需要输入密码）..." -ForegroundColor Cyan
Write-Host "提示：输入密码时不会显示字符，直接输入后按回车" -ForegroundColor Yellow
Write-Host "你的 GitHub 密码是: jy6Mrmg5Dav37t@" -ForegroundColor Magenta

# 执行推送
git push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host "" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "推送成功！" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "" -ForegroundColor Green
    Write-Host "接下来:" -ForegroundColor Cyan
    Write-Host "1. 访问 https://github.com/qwer2385-stra/LexiFlow/actions" -ForegroundColor White
    Write-Host "2. 等待约 10 分钟构建完成" -ForegroundColor White
    Write-Host "3. 在 Actions 页面下载 IPA 文件" -ForegroundColor White
    Write-Host "" -ForegroundColor Green
} else {
    Write-Host "推送失败，请检查网络或密码是否正确" -ForegroundColor Red
}

Write-Host "按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
