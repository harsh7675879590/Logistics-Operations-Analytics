# DAX Measures — Logistics Dashboard
## Complete Measure Library

---

## Core KPI Measures

```dax
// ─── Revenue Measures ───────────────────────────────────────────────────────

Total Revenue = 
SUM(orders[total_revenue])

Total Revenue (Lakhs) = 
DIVIDE([Total Revenue], 100000, 0)

Total Revenue (Cr) = 
DIVIDE([Total Revenue], 10000000, 0)

Revenue MoM Growth % = 
VAR CurrentMonth = [Total Revenue]
VAR PreviousMonth = CALCULATE([Total Revenue], DATEADD(DateTable[Date], -1, MONTH))
RETURN
    DIVIDE(CurrentMonth - PreviousMonth, PreviousMonth, 0) * 100

Revenue YoY Growth % = 
VAR CurrentYear = [Total Revenue]
VAR PreviousYear = CALCULATE([Total Revenue], DATEADD(DateTable[Date], -1, YEAR))
RETURN
    DIVIDE(CurrentYear - PreviousYear, PreviousYear, 0) * 100
```

```dax
// ─── Order Measures ─────────────────────────────────────────────────────────

Total Orders = 
COUNTROWS(orders)

Delivered Orders = 
CALCULATE(COUNTROWS(orders), orders[order_status] = "Delivered")

Cancelled Orders = 
CALCULATE(COUNTROWS(orders), orders[order_status] = "Cancelled")

Returned Orders = 
CALCULATE(COUNTROWS(orders), orders[order_status] = "Returned")

In-Transit Orders = 
CALCULATE(COUNTROWS(orders), orders[order_status] = "In-Transit")
```

```dax
// ─── Delivery Performance ───────────────────────────────────────────────────

Avg Delivery Time = 
AVERAGE(orders[actual_delivery_min])

Median Delivery Time = 
MEDIAN(orders[actual_delivery_min])

On Time Delivery % = 
VAR OnTime = 
    CALCULATE(
        COUNTROWS(orders),
        orders[actual_delivery_min] <= orders[estimated_delivery_min],
        orders[order_status] = "Delivered"
    )
VAR Total = 
    CALCULATE(
        COUNTROWS(orders),
        orders[order_status] = "Delivered",
        NOT(ISBLANK(orders[actual_delivery_min]))
    )
RETURN
    DIVIDE(OnTime, Total, 0) * 100

Avg Delay (min) = 
CALCULATE(
    AVERAGE(orders[delivery_delay_min]),
    orders[delivery_delay_min] > 0
)
```

```dax
// ─── Cancellation Measures ──────────────────────────────────────────────────

Cancellation Rate = 
DIVIDE([Cancelled Orders], [Total Orders], 0) * 100

Cancellation Rate (Previous Period) = 
CALCULATE(
    [Cancellation Rate],
    DATEADD(DateTable[Date], -1, MONTH)
)

Cancellation Rate Change = 
[Cancellation Rate] - [Cancellation Rate (Previous Period)]
```

```dax
// ─── Customer Measures ──────────────────────────────────────────────────────

Unique Customers = 
DISTINCTCOUNT(orders[customer_id])

Avg Order Value = 
AVERAGE(orders[order_value])

Customer Retention Rate = 
VAR RepeatCustomers = 
    CALCULATE(
        DISTINCTCOUNT(orders[customer_id]),
        orders[is_repeat_customer] = TRUE()
    )
VAR TotalCustomers = DISTINCTCOUNT(orders[customer_id])
RETURN
    DIVIDE(RepeatCustomers, TotalCustomers, 0) * 100

Avg Customer Lifetime Value = 
DIVIDE([Total Revenue], [Unique Customers], 0)

New Customers = 
CALCULATE(
    DISTINCTCOUNT(orders[customer_id]),
    orders[customer_order_rank] = 1
)
```

```dax
// ─── Driver Measures ────────────────────────────────────────────────────────

Active Drivers = 
DISTINCTCOUNT(orders[driver_id])

Orders Per Driver = 
DIVIDE([Total Orders], [Active Drivers], 0)

Revenue Per Driver = 
DIVIDE([Total Revenue], [Active Drivers], 0)

Avg Driver Rating = 
AVERAGE(orders[rating])

Driver Utilization % = 
VAR MaxOrdersPerDriver = 
    MAXX(
        SUMMARIZE(orders, orders[driver_id], "DriverOrders", COUNTROWS(orders)),
        [DriverOrders]
    )
VAR AvgOrdersPerDriver = [Orders Per Driver]
RETURN
    DIVIDE(AvgOrdersPerDriver, MaxOrdersPerDriver, 0) * 100
```

```dax
// ─── Revenue Breakdown ──────────────────────────────────────────────────────

Delivery Fee Revenue = 
SUM(orders[delivery_fee])

Order Value Revenue = 
SUM(orders[order_value])

Revenue Per KM = 
DIVIDE([Total Revenue], SUM(orders[distance_km]), 0)

Avg Delivery Fee = 
AVERAGE(orders[delivery_fee])
```

```dax
// ─── Conditional Formatting Measures ────────────────────────────────────────

Revenue Trend Color = 
IF([Revenue MoM Growth %] >= 0, "#10b981", "#ef4444")

Cancellation Alert = 
IF([Cancellation Rate] > 10, "#ef4444", 
   IF([Cancellation Rate] > 7, "#f59e0b", "#10b981"))

Delivery Time Alert = 
IF([Avg Delivery Time] > 40, "#ef4444",
   IF([Avg Delivery Time] > 35, "#f59e0b", "#10b981"))

Rating Color = 
IF([Avg Driver Rating] >= 4, "#10b981",
   IF([Avg Driver Rating] >= 3, "#f59e0b", "#ef4444"))
```

---

## How to Add Measures

1. Click on the **orders** table in the Fields pane
2. Go to **Modeling** → **New Measure**
3. Paste each measure formula
4. Set the format (Currency, Percentage, Number) in the **Measure tools** tab
5. Organize measures into a **Display Folder** called "KPI Measures"

## Measure Formatting

| Measure | Format | Decimals |
|---------|--------|----------|
| Total Revenue | Currency (₹) | 0 |
| Cancellation Rate | Percentage | 1 |
| On Time Delivery % | Percentage | 1 |
| Avg Delivery Time | Number | 1 |
| Avg Order Value | Currency (₹) | 0 |
| Revenue MoM Growth % | Percentage | 1 |
