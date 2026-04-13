@echo off
title --- PUSH CARTE NABIL ---
echo.
echo    [ CARTE NABIL - PUSH et BUILD GitHub Actions ]
echo    Envoi du code vers GitHub...
echo.

cd /d c:\Users\user\Desktop\mimo6\carte-nabil

git add .
git commit -m "Carte Nabil: mise a jour application"
git push -u origin master

echo.
echo ==========================================
echo   Code envoye ! Lancement de la surveillance...
echo ==========================================
python watch_build.py
echo.
pause
