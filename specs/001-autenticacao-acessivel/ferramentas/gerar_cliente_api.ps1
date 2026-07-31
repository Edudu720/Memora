# Gera o cliente Dart da API de autenticação (T005, decisão R8).
#
# O contrato em contracts/openapi.yaml é a fonte da verdade. Este script gera o
# cliente `dart-dio` a partir dele. O código gerado NUNCA é editado à mão: se o
# contrato mudar, rode este script de novo.
#
# Uso (de qualquer diretório):
#   powershell -File specs/001-autenticacao-acessivel/ferramentas/gerar_cliente_api.ps1
#
# Requisitos: Java 21 (o mesmo do backend). O OpenAPI Generator é baixado do
# Maven Central na primeira execução e fica em cache local.

param(
    # Destino do cliente gerado, relativo à raiz do repositório.
    [string]$Saida = 'app/lib/services/api'
)

$ErrorActionPreference = 'Stop'

# Versão fixada: todos da equipe geram exatamente o mesmo código.
$VersaoGerador = '7.14.0'

$RaizRepo = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$Contrato = Join-Path $RaizRepo 'specs\001-autenticacao-acessivel\contracts\openapi.yaml'
if ([System.IO.Path]::IsPathRooted($Saida)) {
    $Destino = $Saida
} else {
    $Destino = Join-Path $RaizRepo $Saida
}

# --- Java -------------------------------------------------------------------

$Java = 'C:\Program Files\Java\jdk-21\bin\java.exe'
if (-not (Test-Path $Java)) {
    $comando = Get-Command java -ErrorAction SilentlyContinue
    if ($null -eq $comando) {
        throw 'Java não encontrado. Instale o JDK 21 ou ajuste o caminho neste script.'
    }
    $Java = $comando.Source
}

# --- OpenAPI Generator (cache local) ----------------------------------------

$PastaCache = Join-Path $env:LOCALAPPDATA 'Memora\ferramentas'
$Jar = Join-Path $PastaCache "openapi-generator-cli-$VersaoGerador.jar"

if (-not (Test-Path $Jar)) {
    New-Item -ItemType Directory -Force $PastaCache | Out-Null
    $Url = "https://repo1.maven.org/maven2/org/openapitools/openapi-generator-cli/$VersaoGerador/openapi-generator-cli-$VersaoGerador.jar"
    Write-Output "Baixando OpenAPI Generator $VersaoGerador do Maven Central..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $Url -OutFile $Jar -UseBasicParsing
}

# --- Geração ----------------------------------------------------------------

Write-Output "Contrato : $Contrato"
Write-Output "Destino  : $Destino"

# Espaço no caminho do repositório derrubava a geração, e não há forma de passar
# o caminho absoluto que agrade os dois estágios do gerador: ele valida a entrada
# como URI (onde espaço é ilegal) e depois a abre como caminho de arquivo (onde
# "file:///...%20..." não existe). Acontece com qualquer pessoa cujo usuário do
# Windows tenha nome composto.
#
# A saída é não dar caminho nenhum: rodamos de dentro da pasta do contrato e
# passamos só o nome do arquivo. O destino continua absoluto porque `-o` é
# tratado como caminho comum, sem o estágio de URI.
Push-Location (Split-Path -Parent $Contrato)
try {
    & $Java -jar $Jar generate `
        -i (Split-Path -Leaf $Contrato) `
        -g dart-dio `
        -o $Destino `
        --additional-properties "pubName=memora_api,pubDescription=Cliente gerado da API do Memora - nao editar a mao,serializationLibrary=json_serializable"
} finally {
    Pop-Location
}

if ($LASTEXITCODE -ne 0) {
    throw "Geração falhou com código $LASTEXITCODE"
}

# --- Correção do piso do SDK no pubspec gerado ------------------------------
#
# O template do dart-dio declara `sdk: '>=3.5.0 <4.0.0'`, e essa versão de
# linguagem não conhece *null-aware elements* (`?valor` dentro de literal de
# coleção). O `json_serializable` atual emite exatamente essa sintaxe, então o
# pacote gerado não compila contra o próprio pubspec gerado.
#
# A R8 proíbe editar o cliente à mão — e é justamente por isso que o ajuste mora
# aqui: faz parte da geração, roda igual para todo mundo e sobrevive à próxima
# regeração. O piso acompanha o do aplicativo, que é quem consome este pacote,
# para não existirem duas versões mínimas de Dart no repositório.

$PubspecDoApp = Join-Path $RaizRepo 'app\pubspec.yaml'
$PubspecGerado = Join-Path $Destino 'pubspec.yaml'

# O pubspec do aplicativo tem duas linhas `sdk:`: a restrição de versão em
# `environment:` e o `sdk: flutter` da dependência do próprio Flutter. Só a
# primeira interessa, e o descarte é por valor, não por posição.
$RestricaoDoApp = (Select-String -Path $PubspecDoApp -Pattern '^\s*sdk:\s*(\S.*)$').Matches `
    | ForEach-Object { $_.Groups[1].Value.Trim() } `
    | Where-Object { $_ -ne 'flutter' } `
    | Select-Object -First 1

if (-not $RestricaoDoApp) {
    throw "Não consegui ler a restrição de SDK de $PubspecDoApp"
}

# Gravado sem BOM: `Set-Content -Encoding utf8` do PowerShell 5.1 escreveria um,
# e BOM em pubspec.yaml confunde parser de YAML.
$Ajustado = (Get-Content $PubspecGerado -Raw) -replace "(?m)^(\s*sdk:\s*).+$", "`${1}$RestricaoDoApp"
[System.IO.File]::WriteAllText($PubspecGerado, $Ajustado, [System.Text.UTF8Encoding]::new($false))

Write-Output "Piso do SDK alinhado ao do aplicativo: $RestricaoDoApp"

Write-Output ''
Write-Output 'Cliente gerado. Próximos passos (T027):'
Write-Output '  cd app; flutter pub get; dart run build_runner build --delete-conflicting-outputs'
