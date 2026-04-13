@echo off
setlocal enabledelayedexpansion

:: Couleurs (si possible)
echo.
echo  [42m[ ASSIMA-10 : Lancement du Build ] [0m
echo.

:: 1. Verification Git
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Git n'est pas installe ou pas dans le PATH.
    pause
    exit /b
)

:: 2. Preparation du commit
echo [*] Marquage des fichiers...
git add .

set "commit_msg=Build Trigger: %date% %time%"
echo [*] Creation du commit : "!commit_msg!"
git commit -m "!commit_msg!"

:: 3. Push vers GitHub (Master et Main pour securite)
echo [*] Synchronisation avec GitHub...
echo.
git push origin master:main --force
git push origin master:master --force
echo.

:: 4. Lien vers le monitoring
echo [SUCCESS] Push termine ! GitHub Actions a recu l'ordre de build.
echo.
echo [*] Ouverture de la page de monitoring...
start https://github.com/djenadimohamedamine-code/carte-nabil/actions

echo.
echo Appuyez sur une touche pour fermer...
pause >nul
