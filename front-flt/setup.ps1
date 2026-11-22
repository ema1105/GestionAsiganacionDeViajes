# Arranque del proyecto GAV Flutter (Windows). Ejecutar una sola vez: setup.bat
Set-Location $PSScriptRoot

function Paso($msg) { Write-Host "`n=== $msg ===" -ForegroundColor Cyan }
function Check($nombre) {
  if ($LASTEXITCODE -ne 0) { Write-Host "FALLO: $nombre (codigo $LASTEXITCODE)" -ForegroundColor Red; exit $LASTEXITCODE }
}

Paso '1/5 Generando carpetas de plataforma (no sobrescribe lib/, test/ ni pubspec.yaml)'
flutter create . --project-name gav_app --org com.gav --platforms android,ios,web
Check 'flutter create'

Paso '2/5 Ajustando AndroidManifest (INTERNET + HTTP en debug)'
$main = 'android\app\src\main\AndroidManifest.xml'
if (Test-Path $main) {
  $c = Get-Content $main -Raw
  if ($c -notmatch 'android.permission.INTERNET') {
    $c = $c -replace '(<manifest[^>]*>)', "`$1`r`n    <uses-permission android:name=`"android.permission.INTERNET`"/>"
    Set-Content $main $c -NoNewline -Encoding UTF8
    Write-Host 'INTERNET agregado al manifest principal'
  }
}
$debug = 'android\app\src\debug\AndroidManifest.xml'
if (Test-Path $debug) {
  $c = Get-Content $debug -Raw
  if ($c -notmatch 'usesCleartextTraffic') {
    $c = $c -replace '</manifest>', "    <application android:usesCleartextTraffic=`"true`" />`r`n</manifest>"
    Set-Content $debug $c -NoNewline -Encoding UTF8
    Write-Host 'Trafico HTTP habilitado solo en debug'
  }
}

Paso '3/5 Configuracion de VS Code (F5)'
New-Item -ItemType Directory -Force -Path '.vscode' | Out-Null
@'
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "GAV (dev)",
      "request": "launch",
      "type": "dart",
      "program": "lib/main.dart",
      "args": ["--dart-define-from-file=env/dev.json"]
    },
    {
      "name": "GAV Web (dev, puerto 5000)",
      "request": "launch",
      "type": "dart",
      "program": "lib/main.dart",
      "deviceId": "chrome",
      "args": ["--dart-define-from-file=env/web.json", "--web-port=5000"]
    }
  ]
}
'@ | Set-Content '.vscode\launch.json' -Encoding UTF8

Paso '4/5 Descargando dependencias'
flutter pub get
Check 'flutter pub get'

Paso '5/5 Analisis y tests'
flutter analyze
flutter test

Write-Host "`nListo. Abre la carpeta en VS Code y presiona F5 (GAV (dev))." -ForegroundColor Green
