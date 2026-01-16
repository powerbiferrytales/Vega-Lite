# PowerShell script to check unused measures for references

$unusedMeasures = @(
    'Price per Point', 'Cost', 'Form Base', 'Appearances# last 10 GW',
    'Appearances last 10 GW', 'Return % last 10 GW', 'Return #', 'Blank No',
    'Blank', 'Appearances', 'pts 2 months', 'average mins',
    'Played in Prev 10 GW TopN', 'Points last 10 GW', 'PPG last 10 GW',
    'Assists', 'Minutes by GW', 'Count of Pos', 'Selected % GW', 'Pts vs Target',
    'Target', 'Target2', 'Target%', 'Labels Top1', 'Total Pts_MaxRound',
    'total pts diff', 'Total Pts_MaxRoundcum', 'Pts Pos %', 'sel%_',
    'goals_conceded  1', 'round ', 'Selected MAX GW', 'Pts by GW', 'Hide Filter',
    'RoundCounts', 'Goals Threshold', 'Pts all rounds', 'sel%',
    'Transfers Selected', 'Selected M', 'SPN', 'DateRange', 'Name title',
    'SizeTextFilter', 'GW Target Value', 'Life Expectancy', 'Current_Age',
    '24', '25', 'X_max', 'X_min'
)

$tablesPath = "Deneb.SemanticModel\definition\tables"
$visualsPath = "Deneb.Report\definition\pages"

$referencedInDAX = @{}
$referencedInVisuals = @{}
$safeToDelete = @()

Write-Host "Checking measures..." -ForegroundColor Yellow
Write-Host ""

# Check each measure
foreach ($measure in $unusedMeasures) {
    $measurePattern = "\[$measure\]"
    $foundInDAX = $false
    $foundInVisuals = $false

    # Check in .tmdl files (DAX code)
    $tmdlFiles = Get-ChildItem -Path $tablesPath -Filter "*.tmdl" -Recurse
    foreach ($file in $tmdlFiles) {
        $content = Get-Content $file.FullName -Raw

        # Count how many times the measure appears - if it's only in its own definition, it's 1 time
        $matches = ([regex]::Matches($content, [regex]::Escape("[$measure]"))).Count

        # If it appears more than once in any file, it's being referenced
        if ($matches -gt 1 -or ($matches -eq 1 -and $content -notmatch "measure\s+[`'`"]?$([regex]::Escape($measure))[`'`"]?\s*=")) {
            $foundInDAX = $true
            if (-not $referencedInDAX.ContainsKey($measure)) {
                $referencedInDAX[$measure] = @()
            }
            $referencedInDAX[$measure] += $file.Name
        }
    }

    # Check in visual.json files
    $visualFiles = Get-ChildItem -Path $visualsPath -Filter "visual.json" -Recurse
    foreach ($file in $visualFiles) {
        $content = Get-Content $file.FullName -Raw
        if ($content -match [regex]::Escape($measure)) {
            $foundInVisuals = $true
            if (-not $referencedInVisuals.ContainsKey($measure)) {
                $referencedInVisuals[$measure] = @()
            }
            $referencedInVisuals[$measure] += $file.FullName
        }
    }

    # If not referenced anywhere, it's safe to delete
    if (-not $foundInDAX -and -not $foundInVisuals) {
        $safeToDelete += $measure
    }
}

# Output results
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "MEASURES REFERENCED IN DAX CODE (MUST KEEP):" -ForegroundColor Red
Write-Host "=" * 80 -ForegroundColor Cyan
foreach ($measure in $referencedInDAX.Keys | Sort-Object) {
    Write-Host "$measure" -ForegroundColor Yellow
    foreach ($file in $referencedInDAX[$measure]) {
        Write-Host "  - $file" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "MEASURES REFERENCED IN VISUALS (MUST KEEP):" -ForegroundColor Red
Write-Host "=" * 80 -ForegroundColor Cyan
foreach ($measure in $referencedInVisuals.Keys | Sort-Object) {
    Write-Host "$measure" -ForegroundColor Yellow
    foreach ($file in $referencedInVisuals[$measure]) {
        Write-Host "  - $file" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "=" * 80 -ForegroundColor Green
Write-Host "MEASURES SAFE TO DELETE:" -ForegroundColor Green
Write-Host "=" * 80 -ForegroundColor Green
foreach ($measure in $safeToDelete | Sort-Object) {
    Write-Host "- $measure" -ForegroundColor Green
}

Write-Host ""
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "SUMMARY:" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "Total unused measures checked: $($unusedMeasures.Count)"
Write-Host "Referenced in DAX: $($referencedInDAX.Keys.Count)"
Write-Host "Referenced in Visuals: $($referencedInVisuals.Keys.Count)"
Write-Host "Safe to delete: $($safeToDelete.Count)" -ForegroundColor Green

# Output safe to delete list to file
$safeToDelete | Out-File "safe_to_delete.txt" -Encoding UTF8
Write-Host ""
Write-Host "Safe to delete list saved to: safe_to_delete.txt" -ForegroundColor Green
