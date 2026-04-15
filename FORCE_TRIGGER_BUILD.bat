@echo off
setlocal
echo 🚀 [ FORCE TRIGGER BUILD : ASSIMA-10 ] 🚀
echo.

:: Tentative de detection de git si non present dans le PATH
where git >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Git n'est pas dans le PATH standard.
    echo [*] Recherche dans les emplacements communs...
    
    if exist "C:\Program Files\Git\bin\git.exe" (
        set "GIT_PATH=C:\Program Files\Git\bin\git.exe"
    ) else if exist "C:\Program Files (x86)\Git\bin\git.exe" (
        set "GIT_PATH=C:\Program Files (x86)\Git\bin\git.exe"
    ) else if exist "%LocalAppData%\Programs\Git\bin\git.exe" (
        set "GIT_PATH=%LocalAppData%\Programs\Git\bin\git.exe"
    ) else (
        echo [ERROR] Git n'a pas pu etre localise automatiquement.
        echo Veuillez installer Git ou l'ajouter au PATH systeme.
        pause
        exit /b
    )
    echo [+] Git trouve ici : !GIT_PATH!
) else (
    set "GIT_PATH=git"
)

echo [*] Nettoyage...
"%GIT_PATH%" gc --prune=now --quiet

echo [*] Ajout des fichiers...
"%GIT_PATH%" add .

set "MYDATE=%date% %time%"
echo [*] Commit de force...
"%GIT_PATH%" commit -m "🚀 Force Build - %MYDATE%" || echo [INFO] Aucun changement a committer.

echo [*] Push force (Master)...
"%GIT_PATH%" push origin master:master --force

echo [*] Push force (Main)...
"%GIT_PATH%" push origin master:main --force

echo.
echo ✅ [ TERMINE ] Le build GitHub Actions est lance !
echo Suivez-le ici : https://github.com/djenadimohamedamine-code/carte-nabil/actions
echo.
pause
