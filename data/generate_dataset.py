"""
Logistics Operations Dataset Generator
Generates a realistic synthetic logistics dataset with 50,000 delivery records.
Author: Senior Data Engineer
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random
import os
import sys

# ─── Configuration ──────────────────────────────────────────────────────────────
NUM_RECORDS = 50000
NUM_CUSTOMERS = 8000
NUM_DRIVERS = 200
START_DATE = datetime(2023, 1, 1)
END_DATE = datetime(2024, 12, 31)
SEED = 42

np.random.seed(SEED)
random.seed(SEED)

# ─── Indian Cities with Realistic Weights ────────────────────────────────────────
CITIES = {
    'Mumbai': 0.14, 'Delhi': 0.13, 'Bangalore': 0.12, 'Hyderabad': 0.09,
    'Chennai': 0.08, 'Pune': 0.07, 'Kolkata': 0.06, 'Ahmedabad': 0.05,
    'Jaipur': 0.04, 'Lucknow': 0.03, 'Chandigarh': 0.025, 'Kochi': 0.02,
    'Indore': 0.02, 'Nagpur': 0.018, 'Bhopal': 0.015, 'Surat': 0.015,
    'Vadodara': 0.012, 'Coimbatore': 0.012, 'Visakhapatnam': 0.01,
    'Patna': 0.01, 'Thiruvananthapuram': 0.008, 'Guwahati': 0.007,
    'Dehradun': 0.006, 'Mysore': 0.005, 'Noida': 0.005
}

CITY_AREAS = {
    'Mumbai': ['Andheri', 'Bandra', 'Worli', 'Powai', 'Dadar', 'Kurla', 'Goregaon', 'Malad', 'Juhu', 'Borivali'],
    'Delhi': ['Connaught Place', 'Karol Bagh', 'Dwarka', 'Rohini', 'Saket', 'Lajpat Nagar', 'Rajouri Garden', 'Pitampura', 'Janakpuri', 'Vasant Kunj'],
    'Bangalore': ['Koramangala', 'Indiranagar', 'Whitefield', 'HSR Layout', 'Electronic City', 'Jayanagar', 'Marathahalli', 'BTM Layout', 'Hebbal', 'Yelahanka'],
    'Hyderabad': ['Banjara Hills', 'Jubilee Hills', 'Madhapur', 'Gachibowli', 'Kukatpally', 'Ameerpet', 'Secunderabad', 'Hitech City', 'Kondapur', 'LB Nagar'],
    'Chennai': ['T Nagar', 'Adyar', 'Anna Nagar', 'Velachery', 'Mylapore', 'Nungambakkam', 'Porur', 'Tambaram', 'OMR', 'ECR'],
    'Pune': ['Koregaon Park', 'Hinjewadi', 'Kothrud', 'Viman Nagar', 'Wakad', 'Baner', 'Hadapsar', 'Aundh', 'Deccan', 'Magarpatta'],
    'Kolkata': ['Salt Lake', 'Park Street', 'New Town', 'Howrah', 'Dum Dum', 'Gariahat', 'Ballygunge', 'Behala', 'Alipore', 'Esplanade'],
    'Ahmedabad': ['Navrangpura', 'SG Highway', 'Satellite', 'Prahlad Nagar', 'Maninagar', 'Vastrapur', 'Bodakdev', 'Thaltej', 'Bopal', 'Chandkheda'],
    'Jaipur': ['MI Road', 'Malviya Nagar', 'Vaishali Nagar', 'Raja Park', 'Mansarovar', 'Tonk Road', 'C-Scheme', 'Jagatpura', 'Sitapura', 'Sanganer'],
    'Lucknow': ['Hazratganj', 'Gomti Nagar', 'Aliganj', 'Indira Nagar', 'Mahanagar', 'Aminabad', 'Chowk', 'Alambagh', 'Vikas Nagar', 'Jankipuram'],
}

# Default areas for cities not in the detailed map
DEFAULT_AREAS = ['Sector 1', 'Sector 2', 'Sector 3', 'Main Market', 'Civil Lines', 'Industrial Area', 'Railway Station Area', 'University Road', 'Mall Road', 'Ring Road']

VEHICLE_TYPES = ['Bike', 'Auto', 'Mini Truck', 'Truck']
VEHICLE_WEIGHTS = [0.35, 0.25, 0.25, 0.15]

ORDER_STATUSES = ['Delivered', 'Cancelled', 'In-Transit', 'Returned']
STATUS_WEIGHTS = [0.82, 0.08, 0.05, 0.05]

CANCELLATION_REASONS = [
    'Customer requested cancellation',
    'Driver unavailable',
    'Address not found',
    'Customer unreachable',
    'Item damaged during transit',
    'Weather conditions',
    'Vehicle breakdown',
    'Payment failed',
    'Duplicate order',
    'Restaurant/Store closed'
]

PAYMENT_MODES = ['UPI', 'Card', 'Cash', 'Wallet']
PAYMENT_WEIGHTS = [0.40, 0.25, 0.20, 0.15]

FIRST_NAMES = [
    'Aarav', 'Vivaan', 'Aditya', 'Vihaan', 'Arjun', 'Sai', 'Reyansh', 'Ayaan', 'Krishna', 'Ishaan',
    'Ananya', 'Diya', 'Myra', 'Sara', 'Aadhya', 'Isha', 'Kiara', 'Riya', 'Priya', 'Neha',
    'Rohan', 'Karan', 'Rahul', 'Amit', 'Deepak', 'Suresh', 'Rajesh', 'Vikram', 'Manoj', 'Sanjay',
    'Pooja', 'Sneha', 'Swati', 'Meera', 'Kavya', 'Tanvi', 'Nisha', 'Anjali', 'Divya', 'Shreya',
    'Mohit', 'Nikhil', 'Varun', 'Gaurav', 'Harsh', 'Tushar', 'Akash', 'Yash', 'Dev', 'Pranav'
]

LAST_NAMES = [
    'Sharma', 'Verma', 'Gupta', 'Singh', 'Kumar', 'Patel', 'Reddy', 'Nair', 'Iyer', 'Joshi',
    'Mehta', 'Desai', 'Shah', 'Chopra', 'Malhotra', 'Kapoor', 'Bhat', 'Rao', 'Pillai', 'Menon',
    'Das', 'Mukherjee', 'Banerjee', 'Chatterjee', 'Roy', 'Chauhan', 'Thakur', 'Pandey', 'Tiwari', 'Mishra'
]


def generate_name():
    return f"{random.choice(FIRST_NAMES)} {random.choice(LAST_NAMES)}"


def get_areas(city):
    return CITY_AREAS.get(city, DEFAULT_AREAS)


def generate_order_time():
    """Generate order time with realistic peak hours (11-13, 18-21)."""
    hour_weights = [
        1, 0.5, 0.3, 0.2, 0.3, 0.5,   # 00-05 (late night/early morning)
        1.5, 3, 5, 7, 8, 10,            # 06-11 (morning ramp up)
        12, 11, 8, 6, 7, 9,             # 12-17 (afternoon)
        12, 14, 13, 10, 6, 3            # 18-23 (evening peak, then decline)
    ]
    hour = random.choices(range(24), weights=hour_weights, k=1)[0]
    minute = random.randint(0, 59)
    second = random.randint(0, 59)
    return f"{hour:02d}:{minute:02d}:{second:02d}"


def generate_dataset():
    print("🚚 Generating Logistics Operations Dataset...")
    print(f"   Records: {NUM_RECORDS:,}")
    print(f"   Date Range: {START_DATE.date()} to {END_DATE.date()}")
    print()

    # ─── Pre-generate customers and drivers ──────────────────────────────
    customers = {
        f"CUST-{i:04d}": generate_name() for i in range(1, NUM_CUSTOMERS + 1)
    }
    customer_ids = list(customers.keys())

    drivers = {
        f"DRV-{i:03d}": generate_name() for i in range(1, NUM_DRIVERS + 1)
    }
    driver_ids = list(drivers.keys())

    # Track customer order counts for repeat customer flag
    customer_order_count = {}

    city_names = list(CITIES.keys())
    city_weights = list(CITIES.values())

    records = []
    date_range_days = (END_DATE - START_DATE).days

    for i in range(NUM_RECORDS):
        if (i + 1) % 10000 == 0:
            print(f"   ✅ Generated {i + 1:,} / {NUM_RECORDS:,} records")

        # Order ID
        order_id = f"ORD-{i + 1:05d}"

        # Date with seasonal variation (more orders in Q4 and festive months)
        day_offset = random.randint(0, date_range_days)
        order_date = START_DATE + timedelta(days=day_offset)
        month = order_date.month
        # Boost Q4 (Oct-Dec) and reduce Jan-Feb
        if month in [10, 11, 12]:
            if random.random() < 0.15:
                day_offset = random.randint(
                    (datetime(order_date.year, 10, 1) - START_DATE).days,
                    min((datetime(order_date.year, 12, 31) - START_DATE).days, date_range_days)
                )
                order_date = START_DATE + timedelta(days=day_offset)

        order_time = generate_order_time()

        # Customer
        customer_id = random.choice(customer_ids)
        customer_name = customers[customer_id]
        customer_order_count[customer_id] = customer_order_count.get(customer_id, 0) + 1
        is_repeat = customer_order_count[customer_id] > 1

        # City
        city = random.choices(city_names, weights=city_weights, k=1)[0]
        areas = get_areas(city)
        pickup_area = random.choice(areas)
        delivery_area = random.choice([a for a in areas if a != pickup_area] if len(areas) > 1 else areas)

        # Driver
        driver_id = random.choice(driver_ids)
        driver_name = drivers[driver_id]

        # Vehicle type (correlated with order value)
        vehicle_type = random.choices(VEHICLE_TYPES, weights=VEHICLE_WEIGHTS, k=1)[0]

        # Distance (varies by vehicle type)
        if vehicle_type == 'Bike':
            distance_km = round(np.random.lognormal(1.5, 0.5), 1)
            distance_km = min(max(distance_km, 1.0), 15.0)
        elif vehicle_type == 'Auto':
            distance_km = round(np.random.lognormal(2.0, 0.4), 1)
            distance_km = min(max(distance_km, 2.0), 25.0)
        elif vehicle_type == 'Mini Truck':
            distance_km = round(np.random.lognormal(2.5, 0.5), 1)
            distance_km = min(max(distance_km, 3.0), 40.0)
        else:  # Truck
            distance_km = round(np.random.lognormal(2.8, 0.5), 1)
            distance_km = min(max(distance_km, 5.0), 50.0)

        # Delivery times
        base_speed = {'Bike': 2.5, 'Auto': 3.0, 'Mini Truck': 4.0, 'Truck': 5.0}
        estimated_min = int(distance_km * base_speed[vehicle_type] + random.randint(5, 15))

        # Actual delivery time (with realistic delays)
        delay_factor = np.random.choice(
            [0.85, 0.95, 1.0, 1.05, 1.15, 1.3, 1.5, 2.0],
            p=[0.05, 0.15, 0.30, 0.20, 0.15, 0.08, 0.05, 0.02]
        )
        actual_min = max(int(estimated_min * delay_factor), estimated_min - 10)
        actual_min = max(actual_min, 5)  # minimum 5 minutes

        # Order status
        status = random.choices(ORDER_STATUSES, weights=STATUS_WEIGHTS, k=1)[0]

        # Weekend cancellation boost
        if order_date.weekday() >= 5 and status == 'Delivered' and random.random() < 0.03:
            status = 'Cancelled'

        # Cancellation reason
        cancellation_reason = random.choice(CANCELLATION_REASONS) if status == 'Cancelled' else None

        # If cancelled or in-transit, actual delivery time might be null
        if status in ['Cancelled']:
            actual_min = None

        # Order value (varies by vehicle type)
        if vehicle_type == 'Bike':
            order_value = round(np.random.lognormal(5.5, 0.6), 2)
            order_value = min(max(order_value, 100), 3000)
        elif vehicle_type == 'Auto':
            order_value = round(np.random.lognormal(6.0, 0.5), 2)
            order_value = min(max(order_value, 200), 8000)
        elif vehicle_type == 'Mini Truck':
            order_value = round(np.random.lognormal(7.0, 0.6), 2)
            order_value = min(max(order_value, 500), 25000)
        else:  # Truck
            order_value = round(np.random.lognormal(8.0, 0.7), 2)
            order_value = min(max(order_value, 1000), 80000)

        # Delivery fee (based on distance and vehicle)
        base_fee = {'Bike': 30, 'Auto': 50, 'Mini Truck': 100, 'Truck': 200}
        per_km_fee = {'Bike': 8, 'Auto': 12, 'Mini Truck': 18, 'Truck': 25}
        delivery_fee = round(base_fee[vehicle_type] + per_km_fee[vehicle_type] * distance_km, 2)

        # Total revenue
        total_revenue = round(order_value + delivery_fee, 2) if status != 'Cancelled' else 0

        # Payment mode
        payment_mode = random.choices(PAYMENT_MODES, weights=PAYMENT_WEIGHTS, k=1)[0]

        # Rating (only for delivered orders)
        if status == 'Delivered':
            if actual_min and actual_min <= estimated_min:
                rating = round(np.random.choice([4.0, 4.5, 5.0], p=[0.3, 0.4, 0.3]), 1)
            elif actual_min and actual_min <= estimated_min * 1.2:
                rating = round(np.random.choice([3.0, 3.5, 4.0, 4.5], p=[0.15, 0.25, 0.35, 0.25]), 1)
            else:
                rating = round(np.random.choice([1.0, 2.0, 2.5, 3.0, 3.5], p=[0.05, 0.15, 0.25, 0.35, 0.20]), 1)
        elif status == 'Returned':
            rating = round(np.random.choice([1.0, 1.5, 2.0, 2.5], p=[0.3, 0.3, 0.25, 0.15]), 1)
        else:
            rating = None

        records.append({
            'order_id': order_id,
            'order_date': order_date.strftime('%Y-%m-%d'),
            'order_time': order_time,
            'customer_id': customer_id,
            'customer_name': customer_name,
            'city': city,
            'pickup_area': pickup_area,
            'delivery_area': delivery_area,
            'driver_id': driver_id,
            'driver_name': driver_name,
            'vehicle_type': vehicle_type,
            'distance_km': distance_km,
            'estimated_delivery_min': estimated_min,
            'actual_delivery_min': actual_min,
            'order_status': status,
            'cancellation_reason': cancellation_reason,
            'order_value': order_value,
            'delivery_fee': delivery_fee,
            'total_revenue': total_revenue,
            'payment_mode': payment_mode,
            'rating': rating,
            'is_repeat_customer': is_repeat
        })

    df = pd.DataFrame(records)

    # ─── Introduce controlled missing values (~2%) ───────────────────────
    print("\n   🔧 Introducing realistic missing values...")
    missing_cols = ['rating', 'distance_km', 'delivery_fee']
    for col in missing_cols:
        mask = np.random.random(len(df)) < 0.02
        # Don't null out already-null ratings
        if col == 'rating':
            mask = mask & df[col].notna()
        df.loc[mask, col] = None

    # ─── Save to CSV ─────────────────────────────────────────────────────
    output_dir = os.path.dirname(os.path.abspath(__file__))
    output_path = os.path.join(output_dir, 'logistics_orders.csv')
    df.to_csv(output_path, index=False)

    print(f"\n   📦 Dataset saved to: {output_path}")
    print(f"   📊 Shape: {df.shape}")
    print(f"\n   ── Summary ──")
    print(f"   Total Records:     {len(df):,}")
    print(f"   Unique Customers:  {df['customer_id'].nunique():,}")
    print(f"   Unique Drivers:    {df['driver_id'].nunique():,}")
    print(f"   Unique Cities:     {df['city'].nunique()}")
    print(f"   Date Range:        {df['order_date'].min()} → {df['order_date'].max()}")
    print(f"   Total Revenue:     ₹{df['total_revenue'].sum():,.2f}")
    print(f"   Avg Order Value:   ₹{df['order_value'].mean():,.2f}")
    print(f"   Cancellation Rate: {(df['order_status'] == 'Cancelled').mean() * 100:.1f}%")
    print(f"\n   Status Distribution:")
    for status, count in df['order_status'].value_counts().items():
        print(f"     {status}: {count:,} ({count/len(df)*100:.1f}%)")

    print("\n✅ Dataset generation complete!")
    return df


if __name__ == '__main__':
    generate_dataset()
