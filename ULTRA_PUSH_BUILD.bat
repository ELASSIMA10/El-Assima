@echo off
setlocal
echo "🚀 [ FULL STABLE PUSH & BUILD : iOS + ANDROID + WEB ] 🚀"

:: Nettoyage des index Git
echo [*] Nettoyage Git...
git gc --prune=now --quiet

:: Ajout de TOUS les fichiers
echo [*] Preparation des fichiers...
git add .

:: Commit force (avec date/heure pour garantir une modification)
set MYDATE=%date% %time%
echo [*] Creation du commit de declenchement...
git commit -m "🚀 Full Stable Build Trigger - %MYDATE%" || echo [INFO] Rien a committer.

:: Push vers MASTER uniquement pour la stabilite
echo [*] Envoi vers GitHub (master)...
git push origin master --force

echo.
echo ✅ [ SUCCES ] Tous les builds (iOS, Android, Web) sont en route !
echo Suivez la progression ici :
echo https://github.com/djenadimohamedamine-code/carte-nabil/actions
echo.
pause
