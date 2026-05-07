Write-Host "Running Flutter setup/checks in Docker..." -ForegroundColor Cyan

docker compose run --rm flutter flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

docker compose run --rm flutter flutter analyze
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

docker compose run --rm flutter flutter test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Docker workflow completed successfully." -ForegroundColor Green
