@echo off
chcp 65001 >nul
title Git 代理一键切换

:: 检查当前代理状态
for /f "tokens=*" %%i in ('git config --global --get http.proxy 2^>nul') do set CURRENT_PROXY=%%i

if "%CURRENT_PROXY%"=="" (
    echo ==========================================
    echo [当前状态] 直连模式
    echo [正在切换] 开启 Clash 代理 (端口 7897)...
    git config --global http.proxy http://127.0.0.1:7897
    git config --global https.proxy http://127.0.0.1:7897
    echo [成功] 已开启代理！
    echo ==========================================
) else (
    echo ==========================================
    echo [当前状态] 代理模式 (%CURRENT_PROXY%)
    echo [正在切换] 关闭代理，恢复直连...
    git config --global --unset http.proxy
    git config --global --unset https.proxy
    echo [成功] 已关闭代理！
    echo ==========================================
)

pause