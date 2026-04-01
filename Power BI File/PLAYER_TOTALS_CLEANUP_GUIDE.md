# Player Totals Table - Column Cleanup Guide

## Overview
The **Player Totals** table is the largest opportunity for optimization with **65 unused columns** out of 85 total (76% waste).

---

## Columns to KEEP (20 columns)

These columns are actively used in visuals, DAX formulas, or relationships:

### Identity & Classification (5)
- **id** - Player unique identifier (used in relationships)
- **element_type** - Position type (used in relationships, visuals)
- **team** - Team ID (used in relationships)
- **Name** - Player display name (used throughout)
- **Pos** - Position abbreviation (used in visuals, DAX)

### Performance Metrics (6)
- **total_points** - Total fantasy points
- **minutes** - Minutes played
- **goals_scored** - Goals scored
- **assists** - Assists
- **clean_sheets** - Clean sheets
- **yellow_cards** - Yellow cards
- **bonus** - Bonus points
- **penalties_saved** - Penalties saved (for goalkeepers)

### Transfer & Selection Data (3)
- **selected_by_percent** - Ownership percentage
- **transfers_in_event** - Transfers in current gameweek
- **transfers_out_event** - Transfers out current gameweek

### Pricing (1)
- **Cost** - Player cost (calculated)

### Display (1)
- **web_name** - Short player name

**Total KEEP: 20 columns**

---

## Columns to REMOVE (65 columns)

### Expected Stats (10 columns)
Remove these unless you plan to add xG/xA analysis:
- expected_goals
- expected_assists
- expected_goal_involvements
- expected_goals_conceded
- expected_goals_per_90
- expected_assists_per_90
- expected_goals_conceded_per_90

### Influence/Creativity/Threat (ICT) Stats (13 columns)
Remove these unless using ICT analysis:
- influence
- creativity
- threat
- ict_index
- bps (bonus point system)
- influence_rank
- influence_rank_type
- creativity_rank
- creativity_rank_type
- threat_rank
- threat_rank_type
- ict_index_rank
- ict_index_rank_type

### Set Piece Taking (6 columns)
Remove unless analyzing set piece takers:
- corners_and_indirect_freekicks_order
- corners_and_indirect_freekicks_text
- direct_freekicks_order
- direct_freekicks_text
- penalties_order
- penalties_text

### Player Status/Fitness (7 columns)
Remove unless displaying injury info:
- chance_of_playing_next_round
- chance_of_playing_this_round
- status
- FitFlag
- Fitness
- Custom (fitness calculation)

### Form & Ranking (5 columns)
Remove unless using form-based analysis:
- form
- form_rank
- points_per_game
- points_per_game_rank

### Player Names (3 columns)
Remove - already have Name and web_name:
- first_name
- second_name
- Name Count (used in name generation)

### Images (2 columns)
Remove unless displaying player photos:
- photo
- Image Url

### Price Changes (6 columns)
Remove unless tracking price movements:
- cost_change_event
- cost_change_event_fall
- cost_change_start
- cost_change_start_fall
- Cost Short (duplicate)
- Cost M (duplicate, formatted string)

### Transfer Stats (2 columns)
Remove - already have transfers_in_event/out_event:
- transfers_in (season total)
- transfers_out (season total)

### Value Stats (2 columns)
Remove unless using value analysis:
- value_form
- value_season

### Miscellaneous (9 columns)
Remove these rarely-used fields:
- code (internal code)
- team_code (duplicate team identifier)
- squad_number (squad number)
- special (special player flag)
- dreamteam_count (dream team selections)
- in_dreamteam (in current dream team)
- event_points (points in last event)
- ep_this (expected points this GW)
- ep_next (expected points next GW)

### Detailed Stats (Not Used) (4 columns)
Remove if not analyzing detailed match stats:
- goals_conceded
- own_goals
- penalties_missed
- red_cards
- saves

**Total REMOVE: 65 columns**

---

## Implementation in Power Query

### Current Query End
Your query currently ends with something like:
```m
#"Changed Type" = Table.TransformColumnTypes(...)
```

### Add This Step
Add a final step to select only the columns you want to keep:

```m
#"Select Used Columns" = Table.SelectColumns(
    #"Changed Type",
    {
        "id",
        "element_type",
        "team",
        "Name",
        "Pos",
        "total_points",
        "minutes",
        "goals_scored",
        "assists",
        "clean_sheets",
        "yellow_cards",
        "bonus",
        "penalties_saved",
        "selected_by_percent",
        "transfers_in_event",
        "transfers_out_event",
        "Cost",
        "web_name"
    }
)
in
    #"Select Used Columns"
```

---

## Alternative: Keep Some "Maybe Useful" Columns

If you want to keep some columns for potential future use, consider this moderate cleanup (removes 50, keeps 35):

### Additional Columns to Consider Keeping

**Form & Performance (3):**
- form (recent form score)
- points_per_game (average points per game)

**Expected Stats (3):**
- expected_goals
- expected_assists
- expected_goals_conceded

**Status (2):**
- status (availability status)
- Fitness (fitness percentage)

**This would give you 25 essential + 8 "nice to have" = 33 columns instead of 85**
**Reduction: 52 columns (61% reduction) vs 65 columns (76% reduction)**

---

## Testing Checklist

After making changes, verify:

- [ ] All visuals on all pages still render
- [ ] Player names display correctly
- [ ] Team filters work
- [ ] Position filters work
- [ ] Points calculations are correct
- [ ] Transfer metrics display
- [ ] Cost/pricing displays correctly
- [ ] No error messages in visuals
- [ ] Data refresh completes successfully
- [ ] File size has decreased

---

## Expected Impact

| Metric | Before | After (Full Cleanup) | After (Moderate) |
|--------|--------|---------------------|------------------|
| Columns | 85 | 20 | 33 |
| Reduction | - | 76% | 61% |
| Estimated Model Size Impact | Baseline | -25% | -18% |
| Refresh Time Impact | Baseline | -20% | -12% |

---

## Rollback Plan

If issues occur after cleanup:

1. **Undo in Power Query:**
   - Remove the `Select Used Columns` step
   - Refresh to restore all columns

2. **Restore from Backup:**
   - Close Power BI without saving
   - Open your backup .pbip file

3. **Partial Rollback:**
   - Add back specific columns you need
   - Refresh and retest

---

## Next Steps

1. **Backup** your current .pbip file
2. **Open** Power Query Editor
3. **Find** the "Player Totals" query
4. **Add** the column selection step (code above)
5. **Close & Apply**
6. **Test** all visuals
7. **Save** if everything works
8. **Measure** the performance improvement

---

**Estimated Time:** 10 minutes
**Risk Level:** Low (easily reversible)
**Reward:** 20-25% model size reduction from this one change alone
