# QUICK SUMMARY - Unused Tables & Columns Analysis

## Top-Level Stats

| Metric | Count |
|--------|-------|
| **Total Tables Analyzed** | 31 |
| **Completely Unused Tables** | 5 |
| **Tables with Unused Columns** | 19 |
| **Total Unused Columns** | 115 |

---

## Unused Tables (Delete These)

1. **Card Param** - Field parameter, never used
2. **Current Age** - Age range generator, never used
3. **GW Target** - Gameweek target selector, never used
4. **Player Comparison** - Calculation group, never used
5. **UK County map** - Geographic data, never used

---

## Biggest Column Cleanup Opportunities

| Table | Unused Columns | Impact |
|-------|----------------|--------|
| **Player Totals** | 65 | HIGH - Biggest opportunity |
| **World Map** | 10 | MEDIUM |
| **Act Plan** | 8 | MEDIUM |
| **Ita Data** | 6 | LOW |
| **Destinations** | 4 | LOW |
| **Gameweeks** | 4 | LOW |

---

## Quick Wins (Highest ROI)

### 1. Delete 5 Unused Tables
- **Effort:** 5 minutes
- **Impact:** Cleaner field list, reduced complexity

### 2. Clean Player Totals Table (65 columns)
- **Effort:** 10 minutes
- **Impact:** 20-30% model size reduction, faster refresh

### 3. Remove Test Tables
- FakeVis, ThermoTest, Parameter
- **Effort:** 2 minutes
- **Impact:** Cleaner model

---

## Player Totals - Major Cleanup Needed

**Current:** 85 columns
**Used:** 20 columns
**Unused:** 65 columns (76% waste!)

### Categories of Unused Columns:
- Expected stats (xG, xA, xGC, etc.) - 10 columns
- Ranking columns (influence_rank, threat_rank, etc.) - 15 columns
- Set piece data (corners, penalties orders) - 6 columns
- Player metadata (photo, Image Url, first_name, etc.) - 8 columns
- Status/fitness data - 5 columns
- Transfer data (transfers_in, transfers_out) - 2 columns
- Other API fields - 19 columns

---

## Important Notes

### DO NOT DELETE These Columns (False Positives)
- **Team ID.Club ID** - Used in relationships
- **Team ID.Team** - Used in Power Query
- **Team ID.Team Abr** - Used in visuals

### Keep for Sorting
- Ordinal columns in Views, Transfers, Selected %
- These enable proper sort order

---

## Expected Benefits

| Benefit | Estimate |
|---------|----------|
| **Model Size Reduction** | 20-30% |
| **Refresh Time Improvement** | 15-25% |
| **Cleaner Field List** | 115 fewer fields |
| **Maintenance** | Easier to understand |

---

## Next Steps

1. **Review** this analysis with team
2. **Backup** the .pbip file
3. **Delete** 5 unused tables
4. **Edit** Player Totals query to remove 65 columns
5. **Test** all visuals still work
6. **Measure** performance improvements

---

## Files Generated

1. `analyze_unused_tables_columns.ps1` - PowerShell analysis script
2. `unused_tables_columns_report.txt` - Detailed text report
3. `COMPREHENSIVE_UNUSED_ANALYSIS_REPORT.md` - Full analysis with recommendations
4. `QUICK_SUMMARY.md` - This file

---

**Total Cleanup Effort:** ~30 minutes
**Expected Performance Gain:** 20-30% smaller model, faster refresh
**Risk Level:** Low (with proper testing)
