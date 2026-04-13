@echo off
echo.
echo  [42m [ ASSIMA-10 : SYNC & BUILD GITHUB ] [0m
echo.

:: Detect changes
git add .
git commit -m "Manual Push: %date% %time%"

:: Force push to both main and master to ensure trigger
echo.
echo [*] Envoi vers GitHub...
git push origin master:master --force
git push origin master:main --force

echo.
echo [OK] Code envoye ! Le build demarre sur GitHub.
echo.
echo Ouvrez ce lien pour voir le build :
echo https://github.com/djenadimohamedamine-code/carte-nabil/actions
echo.
pause
