# TurkiyeMesajlasma platformu kurulum betiği

Write-Host "Docker servisinin çalışıp çalışmadığı kontrol ediliyor..." -ForegroundColor Cyan
$dockerStatus = docker info 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Hata: Docker çalışmıyor. Lütfen Docker Desktop'ı başlatın." -ForegroundColor Red
    exit 1
}

Write-Host "Konteynerler docker-compose ile başlatılıyor..." -ForegroundColor Cyan
# Çalıştırma dizinini devops klasörü olarak ayarla
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$devopsDir = Split-Path -Parent $scriptPath
Set-Location -Path $devopsDir

docker-compose up -d

Write-Host "Veritabanlarının hazır olması bekleniyor (Bu işlem birkaç dakika sürebilir)..." -ForegroundColor Yellow

# CockroachDB kontrolü
$retries = 30
while ($retries -gt 0) {
    docker exec -i cockroachdb cockroach sql --insecure -e "SELECT 1;" >$null 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "CockroachDB hazır!" -ForegroundColor Green
        break
    }
    Start-Sleep -Seconds 2
    $retries--
}

# ScyllaDB kontrolü
$retries = 30
while ($retries -gt 0) {
    docker exec -i scylladb cqlsh -e "DESCRIBE KEYSPACES;" >$null 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "ScyllaDB hazır!" -ForegroundColor Green
        break
    }
    Start-Sleep -Seconds 5
    $retries--
}

# ClickHouse kontrolü
$retries = 30
while ($retries -gt 0) {
    docker exec -i clickhouse clickhouse-client -q "SELECT 1;" >$null 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "ClickHouse hazır!" -ForegroundColor Green
        break
    }
    Start-Sleep -Seconds 2
    $retries--
}

Write-Host "Veritabanı başlangıç betikleri çalıştırılıyor..." -ForegroundColor Cyan

# CockroachDB script'ini çalıştır
Get-Content "$scriptPath\init-cockroachdb.sql" | docker exec -i cockroachdb cockroach sql --insecure
if ($LASTEXITCODE -eq 0) { Write-Host "CockroachDB yapılandırması tamamlandı." -ForegroundColor Green }

# ScyllaDB script'ini çalıştır
Get-Content "$scriptPath\init-scylladb.cql" | docker exec -i scylladb cqlsh
if ($LASTEXITCODE -eq 0) { Write-Host "ScyllaDB yapılandırması tamamlandı." -ForegroundColor Green }

# ClickHouse script'ini çalıştır
Get-Content "$scriptPath\init-clickhouse.sql" | docker exec -i clickhouse clickhouse-client
if ($LASTEXITCODE -eq 0) { Write-Host "ClickHouse yapılandırması tamamlandı." -ForegroundColor Green }

Write-Host "Kurulum başarıyla tamamlandı!" -ForegroundColor Green
Write-Host "Bağlantı Bilgileri:" -ForegroundColor Yellow
Write-Host " - Gateway WS: localhost:8080"
Write-Host " - CockroachDB: localhost:26257 (UI: localhost:8080)"
Write-Host " - ScyllaDB: localhost:9042"
Write-Host " - ClickHouse: localhost:9000 (HTTP: localhost:8123)"
