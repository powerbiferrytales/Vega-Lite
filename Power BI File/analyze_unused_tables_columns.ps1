# Script to analyze unused tables and columns in Power BI Deneb report
# Base path
$basePath = "C:\Users\ferry\Documents\Power BI Ferry Tales\GitRepo\Vega-Lite\Power BI File"
$tablesPath = "$basePath\Deneb.SemanticModel\definition\tables"
$visualsPath = "$basePath\Deneb.Report\definition\pages"
$relationshipsPath = "$basePath\Deneb.SemanticModel\definition\relationships.tmdl"

# Get all table files
$tableFiles = Get-ChildItem -Path $tablesPath -Filter "*.tmdl"

# Initialize results
$results = @{
    UnusedTables = @()
    TablesWithUnusedColumns = @{}
    AllTables = @{}
}

Write-Host "Found $($tableFiles.Count) tables" -ForegroundColor Cyan
Write-Host ""

# Parse each table and extract columns
foreach ($tableFile in $tableFiles) {
    $tableName = $tableFile.BaseName

    # Skip LocalDateTable and DateTableTemplate (auto-generated)
    if ($tableName -like "LocalDateTable_*" -or $tableName -like "DateTableTemplate_*") {
        Write-Host "Skipping auto-generated table: $tableName" -ForegroundColor Gray
        continue
    }

    $content = Get-Content -Path $tableFile.FullName -Raw

    # Extract all column definitions
    $columns = @()
    $columnMatches = [regex]::Matches($content, "(?m)^\s*column ['`"]?([^'`"\r\n]+)['`"]?\s*$")
    foreach ($match in $columnMatches) {
        $columnName = $match.Groups[1].Value.Trim()
        $columns += $columnName
    }

    $results.AllTables[$tableName] = @{
        Columns = $columns
        ColumnUsage = @{}
    }

    # Initialize column usage tracking
    foreach ($col in $columns) {
        $results.AllTables[$tableName].ColumnUsage[$col] = $false
    }

    Write-Host "Table: $tableName - $($columns.Count) columns" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Analyzing usage in visual.json files..." -ForegroundColor Cyan

# Get all visual.json files
$visualFiles = Get-ChildItem -Path $visualsPath -Recurse -Filter "visual.json"

Write-Host "Found $($visualFiles.Count) visual files" -ForegroundColor Cyan
Write-Host ""

# Search through all visual.json files
foreach ($visualFile in $visualFiles) {
    $content = Get-Content -Path $visualFile.FullName -Raw

    # Check each table
    foreach ($tableName in $results.AllTables.Keys) {
        # Check if table is referenced
        if ($content -match [regex]::Escape($tableName)) {
            if ($results.AllTables[$tableName].Keys -notcontains "UsedInVisuals") {
                $results.AllTables[$tableName]["UsedInVisuals"] = $true
            }
        }

        # Check each column
        foreach ($col in $results.AllTables[$tableName].Columns) {
            # Look for patterns like: [ColumnName] or TableName[ColumnName] or 'TableName'[ColumnName]
            $patterns = @(
                "\[$col\]",
                "$tableName\[$col\]",
                "'$tableName'\[$col\]",
                """$tableName"":\[""$col""\]"
            )

            foreach ($pattern in $patterns) {
                if ($content -match $pattern) {
                    $results.AllTables[$tableName].ColumnUsage[$col] = $true
                    break
                }
            }
        }
    }
}

Write-Host ""
Write-Host "Analyzing usage in .tmdl files (DAX)..." -ForegroundColor Cyan

# Get all .tmdl files in tables directory
$tmdlFiles = Get-ChildItem -Path $tablesPath -Filter "*.tmdl"

foreach ($tmdlFile in $tmdlFiles) {
    $content = Get-Content -Path $tmdlFile.FullName -Raw

    # Check each table
    foreach ($tableName in $results.AllTables.Keys) {
        # Skip checking a table's own file
        if ($tmdlFile.BaseName -eq $tableName) {
            continue
        }

        # Check if table is referenced
        if ($content -match [regex]::Escape($tableName)) {
            if ($results.AllTables[$tableName].Keys -notcontains "UsedInDAX") {
                $results.AllTables[$tableName]["UsedInDAX"] = $true
            }
        }

        # Check each column
        foreach ($col in $results.AllTables[$tableName].Columns) {
            $patterns = @(
                "\[$col\]",
                "$tableName\[$col\]",
                "'$tableName'\[$col\]"
            )

            foreach ($pattern in $patterns) {
                if ($content -match $pattern) {
                    $results.AllTables[$tableName].ColumnUsage[$col] = $true
                    break
                }
            }
        }
    }
}

Write-Host ""
Write-Host "Checking relationships file..." -ForegroundColor Cyan

# Check relationships file
if (Test-Path $relationshipsPath) {
    $relationshipsContent = Get-Content -Path $relationshipsPath -Raw

    foreach ($tableName in $results.AllTables.Keys) {
        if ($relationshipsContent -match [regex]::Escape($tableName)) {
            if ($results.AllTables[$tableName].Keys -notcontains "UsedInRelationships") {
                $results.AllTables[$tableName]["UsedInRelationships"] = $true
            }
        }

        foreach ($col in $results.AllTables[$tableName].Columns) {
            $patterns = @(
                "\[$col\]",
                "$tableName\.$col",
                "'$tableName'\.$col"
            )

            foreach ($pattern in $patterns) {
                if ($relationshipsContent -match $pattern) {
                    $results.AllTables[$tableName].ColumnUsage[$col] = $true
                    break
                }
            }
        }
    }
}

Write-Host ""
Write-Host "===== ANALYSIS COMPLETE =====" -ForegroundColor Green
Write-Host ""

# Determine unused tables and columns
$unusedTablesCount = 0
$unusedColumnsCount = 0

foreach ($tableName in $results.AllTables.Keys) {
    $table = $results.AllTables[$tableName]
    $isUsed = $table.Keys -contains "UsedInVisuals" -or
              $table.Keys -contains "UsedInDAX" -or
              $table.Keys -contains "UsedInRelationships"

    if (-not $isUsed) {
        $results.UnusedTables += $tableName
        $unusedTablesCount++
    } else {
        # Check for unused columns
        $unusedColumns = @()
        foreach ($col in $table.Columns) {
            if (-not $table.ColumnUsage[$col]) {
                $unusedColumns += $col
                $unusedColumnsCount++
            }
        }

        if ($unusedColumns.Count -gt 0) {
            $results.TablesWithUnusedColumns[$tableName] = $unusedColumns
        }
    }
}

# Generate report
Write-Host "==================== UNUSED TABLES ====================" -ForegroundColor Red
Write-Host ""
if ($results.UnusedTables.Count -eq 0) {
    Write-Host "No completely unused tables found!" -ForegroundColor Green
} else {
    foreach ($table in $results.UnusedTables | Sort-Object) {
        Write-Host "  - $table" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "==================== UNUSED COLUMNS BY TABLE ====================" -ForegroundColor Yellow
Write-Host ""

if ($results.TablesWithUnusedColumns.Count -eq 0) {
    Write-Host "No unused columns found!" -ForegroundColor Green
} else {
    foreach ($tableName in $results.TablesWithUnusedColumns.Keys | Sort-Object) {
        $unusedCols = $results.TablesWithUnusedColumns[$tableName]
        Write-Host "$tableName ($($unusedCols.Count) unused columns):" -ForegroundColor Cyan
        foreach ($col in $unusedCols | Sort-Object) {
            Write-Host "    - $col" -ForegroundColor Yellow
        }
        Write-Host ""
    }
}

Write-Host ""
Write-Host "==================== SUMMARY ====================" -ForegroundColor Green
Write-Host "Total tables analyzed: $($results.AllTables.Count)" -ForegroundColor Cyan
Write-Host "Completely unused tables: $unusedTablesCount" -ForegroundColor Red
Write-Host "Total unused columns: $unusedColumnsCount" -ForegroundColor Yellow
Write-Host ""

# Save results to file
$outputPath = "$basePath\unused_tables_columns_report.txt"
$reportContent = @"
POWER BI DENEB REPORT - UNUSED TABLES AND COLUMNS ANALYSIS
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
==============================================================

==================== UNUSED TABLES ====================

"@

if ($results.UnusedTables.Count -eq 0) {
    $reportContent += "No completely unused tables found!`n"
} else {
    foreach ($table in $results.UnusedTables | Sort-Object) {
        $reportContent += "  - $table`n"
    }
}

$reportContent += @"

==================== UNUSED COLUMNS BY TABLE ====================

"@

if ($results.TablesWithUnusedColumns.Count -eq 0) {
    $reportContent += "No unused columns found!`n"
} else {
    foreach ($tableName in $results.TablesWithUnusedColumns.Keys | Sort-Object) {
        $unusedCols = $results.TablesWithUnusedColumns[$tableName]
        $reportContent += "`n$tableName ($($unusedCols.Count) unused columns):`n"
        foreach ($col in $unusedCols | Sort-Object) {
            $reportContent += "    - $col`n"
        }
    }
}

$reportContent += @"

==================== SUMMARY ====================
Total tables analyzed: $($results.AllTables.Count)
Completely unused tables: $unusedTablesCount
Total unused columns: $unusedColumnsCount

==================== RECOMMENDATIONS ====================

UNUSED TABLES:
These tables can be safely deleted as they are not referenced anywhere in the report:

"@

foreach ($table in $results.UnusedTables | Sort-Object) {
    $reportContent += "  - $table.tmdl`n"
}

$reportContent += @"

UNUSED COLUMNS:
These columns can be removed from their respective tables to optimize the data model:
(Note: Review carefully before deletion, especially for columns that might be needed for future use)

"@

foreach ($tableName in $results.TablesWithUnusedColumns.Keys | Sort-Object) {
    $unusedCols = $results.TablesWithUnusedColumns[$tableName]
    $reportContent += "`nTable: $tableName`n"
    foreach ($col in $unusedCols | Sort-Object) {
        $reportContent += "    - $col`n"
    }
}

$reportContent | Out-File -FilePath $outputPath -Encoding UTF8
Write-Host "Report saved to: $outputPath" -ForegroundColor Green
