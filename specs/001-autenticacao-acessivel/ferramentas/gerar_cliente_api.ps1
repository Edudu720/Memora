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

# O parser da especificação trata o caminho como URI; barra invertida quebra.
$ContratoUri = $Contrato.Replace('\', '/')

& $Java -jar $Jar generate `
    -i $ContratoUri `
    -g dart-dio `
    -o $Destino `
    --additional-properties "pubName=memora_api,pubDescription=Cliente gerado da API do Memora — não editar à mão,serializationLibrary=json_serializable"

if ($LASTEXITCODE -ne 0) {
    throw "Geração falhou com código $LASTEXITCODE"
}

Write-Output ''
Write-Output 'Cliente gerado. Próximos passos (T027):'
Write-Output '  cd app; flutter pub get; dart run build_runner build --delete-conflicting-outputs'
