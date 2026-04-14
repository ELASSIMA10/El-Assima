@echo off
title --- ENVOI ZONE 14 ---
echo.
echo    [ ASSIMA-10 : MISE A JOUR ZONE 14 ]
echo.

:: Se placer dans le bon dossier
cd /d %~dp0

echo 1. Preparation des fichiers...
git add .

echo 2. Creation de la mise a jour...
git commit -m "Mise a jour ZONE 14: Scanner et Liste"

echo 3. Envoi vers GitHub...
git push origin master

echo.
echo ==========================================
echo   TERMINE !
echo   Compilations lancees sur GitHub Actions.
echo ==========================================
echo.
pause
