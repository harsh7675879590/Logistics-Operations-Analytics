# Power BI Dashboard — Build Guide
## Logistics Operations Analytics Dashboard

---

## 1. Setup & Data Import

### Step 1: Open Power BI Desktop
1. Open Power BI Desktop
2. Click **Get Data** → **Text/CSV**
3. Navigate to `powerbi/powerbi_data.csv` and click **Load**

### Step 2: Data Type Configuration
In **Transform Data** (Power Query Editor):

| Column | Set Type To |
|--------|-------------|
| `order_date` | Date |
| `order_time` | Time |
| `order_value` | Decimal Number |
| `delivery_fee` | Decimal Number |
| `total_revenue` | Decimal Number |
| `distance_km` | Decimal Number |
| `rating` | Decimal Number |
| `estimated_delivery_min` | Whole Number |
| `actual_delivery_min` | Whole Number |
| `is_repeat_customer` | True/False |
| `is_delayed` | True/False |

Click **Close & Apply**.

### Step 3: Create Date Table
In **Modeling** → **New Table**:
```dax
DateTable = 
ADDCOLUMNS(
    CALENDARAUTO(),
    "Year", YEAR([Date]),
    "Month", FORMAT([Date], "MMM YYYY"),
    "MonthNum", MONTH([Date]),
    "Quarter", "Q" & QUARTER([Date]),
    "DayOfWeek", FORMAT([Date], "ddd"),
    "DayOfWeekNum", WEEKDAY([Date], 2),
    "IsWeekend", IF(WEEKDAY([Date], 2) >= 6, TRUE(), FALSE())
)
```

Mark as Date Table: **Modeling** → **Mark as Date Table** → Select `Date` column.

Create relationship: `DateTable[Date]` → `orders[order_date]` (Many to One).

---

## 2. Color Theme

Save this as `porter_theme.json` and import via **View** → **Themes** → **Browse for themes**:

```json
{
  "name": "Porter Logistics",
  "dataColors": [
    "#2563eb", "#10b981", "#f59e0b", "#ef4444",
    "#8b5cf6", "#ec4899", "#14b8a6", "#6366f1",
    "#f97316", "#06b6d4"
  ],
  "background": "#0f172a",
  "foreground": "#f8fafc",
  "tableAccent": "#2563eb",
  "visualStyles": {
    "*": {
      "*": {
        "background": [{"color": {"solid": {"color": "#1e293b"}}}],
        "foreground": [{"color": {"solid": {"color": "#f8fafc"}}}]
      }
    }
  }
}
```

---

## 3. Dashboard Layout

### Page 1: Executive Overview

#### Row 1 — KPI Cards (6 cards across the top)

| Card | Measure | Format | Conditional Color |
|------|---------|--------|------------------|
| Total Revenue | `[Total Revenue]` | ₹ #,##0 | Green if > target |
| Total Orders | `[Total Orders]` | #,##0 | Blue |
| Avg Delivery Time | `[Avg Delivery Time]` | #0.0 "min" | Green if < 35 |
| Cancellation Rate | `[Cancellation Rate]` | 0.0% | Red if > 10% |
| On-Time Delivery | `[On Time Delivery %]` | 0.0% | Green if > 85% |
| Avg Order Value | `[Avg Order Value]` | ₹ #,##0 | Blue |

#### Row 2 — Charts (2 columns)

**Left: Revenue Trend** (Line Chart)
- X-axis: `DateTable[Month]`
- Y-axis: `[Total Revenue]`
- Secondary Y-axis: `[Total Orders]`
- Line style: Smooth, area fill

**Right: Orders by City** (Horizontal Bar Chart)
- Y-axis: `orders[city]`
- X-axis: `[Total Orders]`
- Sort: Descending by value
- Data labels: ON

#### Row 3 — Charts (2 columns)

**Left: Delivery Time Trend** (Area Chart)
- X-axis: `DateTable[Month]`
- Y-axis: `[Avg Delivery Time]`
- Add constant line at 35 min (SLA target)
- Color: Gradient blue

**Right: Cancellation by Reason** (Donut Chart)
- Legend: `orders[cancellation_reason]`
- Values: Count of `order_id`
- Filter: `order_status = "Cancelled"`

#### Row 4 — Charts (2 columns)

**Left: Peak Order Hours** (Column Chart)
- X-axis: `orders[order_hour]`
- Y-axis: Count of orders
- Conditional formatting: Highlight peak hours (11-13, 18-21) in blue

**Right: Driver Performance** (Table Visual)
- Columns: `driver_id`, `driver_name`, Total Trips, Avg Rating, On-Time %, Revenue
- Sort: By performance score descending
- Conditional: Data bars on revenue column

---

### Slicers (Top Right)

| Slicer | Column | Style |
|--------|--------|-------|
| Date Range | `DateTable[Date]` | Between slider |
| City | `orders[city]` | Dropdown |
| Vehicle Type | `orders[vehicle_type]` | Buttons |
| Order Status | `orders[order_status]` | Buttons |

---

## 4. Card Formatting Tips

For each KPI card:
1. Remove category label
2. Set display units to **None** (show full numbers)
3. Set font size: Value = **28pt**, Label = **10pt**
4. Add background: Semi-transparent dark (#1e293b, 90% opacity)
5. Round corners: 8px
6. Add subtle shadow
7. Add trend indicator using conditional formatting icons

---

## 5. Final Touches

1. **Page Background**: Set to `#0f172a` (dark navy)
2. **Title Bar**: Add a text box with "🚚 Logistics Operations Dashboard" in white, 20pt
3. **Logo**: Insert the company logo in top-left
4. **Tooltips**: Enable custom tooltips showing detailed breakdowns
5. **Bookmarks**: Create bookmarks for "Overview", "City Drilldown", "Driver Analysis"
6. **Mobile Layout**: Create a separate mobile-optimized layout

---

## 6. Publishing

1. Click **Publish** → Select workspace
2. Set up **Scheduled Refresh** if connecting to live data
3. Create a **Power BI App** for stakeholder distribution
4. Set **Row-Level Security** if needed per city/region
