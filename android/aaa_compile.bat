@echo off
cd C:\APPs\Encomendas\encomendas_outubro_2025
echo Limpando...
flutter clean
echo Baixando dependências...
flutter pub get
cd android
echo Compilando...
set JAVA_HOME=C:\Users\User\AppData\Local\Android\Sdk\jdk
./gradlew.bat clean
./gradlew.bat assembleRelease
echo Procurando APK...
cd ..
Get-ChildItem -Path . -Filter "*.apk" -Recurse | Select-Object FullName
pause