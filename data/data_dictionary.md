# Data Dictionary — Logistics Operations Dataset

## Overview
- **File**: `logistics_orders.csv`
- **Records**: 50,000 delivery orders
- **Date Range**: January 2023 — December 2024
- **Geography**: 25 Indian cities

---

## Column Definitions

| # | Column | Data Type | Description | Example |
|---|--------|-----------|-------------|---------|
| 1 | `order_id` | VARCHAR(10) | Unique order identifier | `ORD-00001` |
| 2 | `order_date` | DATE | Date when order was placed | `2023-06-15` |
| 3 | `order_time` | TIME | Time when order was placed (HH:MM:SS) | `14:23:45` |
| 4 | `customer_id` | VARCHAR(9) | Unique customer identifier | `CUST-0042` |
| 5 | `customer_name` | VARCHAR(50) | Customer's full name | `Aarav Sharma` |
| 6 | `city` | VARCHAR(30) | City where delivery occurred | `Mumbai` |
| 7 | `pickup_area` | VARCHAR(50) | Pickup locality/area | `Andheri` |
| 8 | `delivery_area` | VARCHAR(50) | Drop-off locality/area | `Bandra` |
| 9 | `driver_id` | VARCHAR(7) | Driver identifier | `DRV-042` |
| 10 | `driver_name` | VARCHAR(50) | Driver's full name | `Rohan Patel` |
| 11 | `vehicle_type` | VARCHAR(15) | Type of delivery vehicle | `Bike`, `Auto`, `Mini Truck`, `Truck` |
| 12 | `distance_km` | FLOAT | Delivery distance in kilometers | `7.3` |
| 13 | `estimated_delivery_min` | INT | Expected delivery time in minutes | `28` |
| 14 | `actual_delivery_min` | INT (nullable) | Actual delivery time in minutes (NULL if cancelled) | `34` |
| 15 | `order_status` | VARCHAR(15) | Current status of the order | `Delivered`, `Cancelled`, `In-Transit`, `Returned` |
| 16 | `cancellation_reason` | VARCHAR(100) (nullable) | Reason for cancellation (NULL if not cancelled) | `Customer requested cancellation` |
| 17 | `order_value` | FLOAT | Value of goods/items in INR | `850.50` |
| 18 | `delivery_fee` | FLOAT (nullable) | Delivery charge in INR | `88.40` |
| 19 | `total_revenue` | FLOAT | Total revenue (order_value + delivery_fee); 0 if cancelled | `938.90` |
| 20 | `payment_mode` | VARCHAR(10) | Payment method used | `UPI`, `Card`, `Cash`, `Wallet` |
| 21 | `rating` | FLOAT (nullable) | Customer rating 1.0–5.0 (NULL if not rated/cancelled) | `4.5` |
| 22 | `is_repeat_customer` | BOOLEAN | Whether this is a returning customer | `True` / `False` |

---

## Value Distributions

### Vehicle Types
| Vehicle | Weight | Typical Distance | Typical Order Value |
|---------|--------|-----------------|-------------------|
| Bike | 35% | 1–15 km | ₹100–₹3,000 |
| Auto | 25% | 2–25 km | ₹200–₹8,000 |
| Mini Truck | 25% | 3–40 km | ₹500–₹25,000 |
| Truck | 15% | 5–50 km | ₹1,000–₹80,000 |

### Order Statuses
| Status | Approximate % | Description |
|--------|--------------|-------------|
| Delivered | ~82% | Successfully delivered |
| Cancelled | ~8% | Order cancelled (reason provided) |
| In-Transit | ~5% | Currently being delivered |
| Returned | ~5% | Delivered but returned |

### Payment Modes
| Mode | Weight |
|------|--------|
| UPI | 40% |
| Card | 25% |
| Cash | 20% |
| Wallet | 15% |

### Peak Order Hours
- Morning surge: 10:00–12:00
- Lunch peak: 12:00–14:00
- Evening peak: 18:00–21:00
- Low activity: 00:00–06:00

### City Distribution
Top 5 cities account for ~56% of all orders: Mumbai (14%), Delhi (13%), Bangalore (12%), Hyderabad (9%), Chennai (8%)

---

## Missing Values
- `actual_delivery_min`: NULL for all cancelled orders
- `cancellation_reason`: NULL for non-cancelled orders
- `rating`: NULL for cancelled/in-transit orders; ~2% additional random nulls
- `distance_km`: ~2% random nulls
- `delivery_fee`: ~2% random nulls

---

## Notes
- All monetary values are in Indian Rupees (INR)
- Dates follow ISO 8601 format (YYYY-MM-DD)
- The dataset includes seasonal patterns with higher order volumes in Q4 (festive season)
- Weekend cancellation rates are slightly elevated
