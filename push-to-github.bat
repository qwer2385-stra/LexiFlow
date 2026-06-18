@echo off
chcp 65001 >nul 2>nul
title LexiFlow GitHub 推送
echo ========================================
echo    LexiFlow 一键推送到 GitHub
echo ========================================
echo.

:: 检查 Git 是否安装
where git >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Git is not installed
    echo.
    echo Please install Git from: https://git-scm.com/download/win
    echo Install with default options, then run this script again.
    echo.
    pause
    exit
)

echo [OK] Git is installed
echo.

:: 配置用户信息
git config --global user.name "qwer2385-stra"
git config --global user.email "qwer2385-stra@users.noreply.github.com"

:: 进入脚本所在目录
cd /d "%~dp0"

:: 初始化仓库
if not exist .git (
    git init
    git branch -m main
)

:: 添加文件
echo Adding files...
git add -A

:: 提交
echo Creating commit...
git commit -m "Initial commit: LexiFlow" 2>nul

:: 配置远程仓库
git remote remove origin 2>nul
git remote add origin https://github.com/qwer2385-stra/LexiFlow.git

:: 推送
echo.
echo Pushing to GitHub...
echo Note: Enter password without seeing any characters displayed
echo Password: jy6Mrmg5Dav37t@
echo.

git push -u origin main

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo   Push successful!
    echo ========================================
    echo.
    echo Next step: Wait 10 minutes, then download IPA at:
    echo https://github.com/qwer2385-stra/LexiFlow/actions
) else (
    echo.
    echo ========================================
    echo   Push failed!
    echo ========================================
    echo.
    echo Possible reasons:
    echo 1. Cannot connect to GitHub (may need VPN)
    echo 2. Wrong password
    echo 3. GitHub repository does not exist
)

echo.
echo Press any key to exit...
pause >nul
