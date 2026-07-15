-- ============================================================================
-- LOGISTICS OPERATIONS DATABASE — SCHEMA DDL
-- Author: Senior Data Engineer
-- Database: SQLite / MySQL / PostgreSQL compatible
-- ============================================================================

-- ─── Drop existing tables (idempotent) ──────────────────────────────────────
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS drivers;


-- ─── Customers Table ────────────────────────────────────────────────────────
CREATE TABLE customers (
    customer_id     VARCHAR(9)   PRIMARY KEY,
    customer_name   VARCHAR(50)  NOT NULL,
    is_repeat       BOOLEAN      DEFAULT FALSE,
    total_orders    INT          DEFAULT 0,
    total_spent     DECIMAL(12,2) DEFAULT 0.00,
    first_order_date DATE,
    last_order_date  DATE
);


-- ─── Drivers Table ──────────────────────────────────────────────────────────
CREATE TABLE drivers (
    driver_id       VARCHAR(7)   PRIMARY KEY,
    driver_name     VARCHAR(50)  NOT NULL,
    total_deliveries INT         DEFAULT 0,
    avg_rating      DECIMAL(3,1) DEFAULT 0.0,
    total_distance_km DECIMAL(10,1) DEFAULT 0.0
);


-- ─── Orders Table (Main Fact Table) ─────────────────────────────────────────
CREATE TABLE orders (
    order_id                VARCHAR(10)  PRIMARY KEY,
    order_date              DATE         NOT NULL,
    order_time              TIME         NOT NULL,
    customer_id             VARCHAR(9)   NOT NULL,
    customer_name           VARCHAR(50)  NOT NULL,
    city                    VARCHAR(30)  NOT NULL,
    pickup_area             VARCHAR(50)  NOT NULL,
    delivery_area           VARCHAR(50)  NOT NULL,
    driver_id               VARCHAR(7)   NOT NULL,
    driver_name             VARCHAR(50)  NOT NULL,
    vehicle_type            VARCHAR(15)  NOT NULL,
    distance_km             DECIMAL(5,1),
    estimated_delivery_min  INT,
    actual_delivery_min     INT,
    order_status            VARCHAR(15)  NOT NULL DEFAULT 'Pending',
    cancellation_reason     VARCHAR(100),
    order_value             DECIMAL(10,2) NOT NULL,
    delivery_fee            DECIMAL(8,2),
    total_revenue           DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    payment_mode            VARCHAR(10)  NOT NULL,
    rating                  DECIMAL(2,1),
    is_repeat_customer      BOOLEAN      DEFAULT FALSE,

    -- Constraints
    CONSTRAINT chk_status CHECK (order_status IN ('Delivered', 'Cancelled', 'In-Transit', 'Returned')),
    CONSTRAINT chk_vehicle CHECK (vehicle_type IN ('Bike', 'Auto', 'Mini Truck', 'Truck')),
    CONSTRAINT chk_payment CHECK (payment_mode IN ('UPI', 'Card', 'Cash', 'Wallet')),
    CONSTRAINT chk_rating  CHECK (rating IS NULL OR (rating >= 1.0 AND rating <= 5.0)),

    -- Foreign Keys
    CONSTRAINT fk_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_driver   FOREIGN KEY (driver_id)   REFERENCES drivers(driver_id)
);


-- ─── Indexes for Analytics Performance ──────────────────────────────────────
CREATE INDEX idx_orders_date       ON orders(order_date);
CREATE INDEX idx_orders_city       ON orders(city);
CREATE INDEX idx_orders_driver     ON orders(driver_id);
CREATE INDEX idx_orders_customer   ON orders(customer_id);
CREATE INDEX idx_orders_status     ON orders(order_status);
CREATE INDEX idx_orders_vehicle    ON orders(vehicle_type);
CREATE INDEX idx_orders_date_city  ON orders(order_date, city);
CREATE INDEX idx_orders_date_status ON orders(order_date, order_status);


-- ─── Load Data (SQLite example) ─────────────────────────────────────────────
-- .mode csv
-- .import logistics_orders.csv orders

-- For MySQL:
-- LOAD DATA INFILE 'logistics_orders.csv'
-- INTO TABLE orders
-- FIELDS TERMINATED BY ','
-- ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS;

-- ============================================================================
-- Populate dimension tables from fact table
-- ============================================================================

INSERT INTO customers (customer_id, customer_name, is_repeat, total_orders, total_spent, first_order_date, last_order_date)
SELECT
    customer_id,
    MAX(customer_name),
    CASE WHEN COUNT(*) > 1 THEN TRUE ELSE FALSE END,
    COUNT(*),
    SUM(total_revenue),
    MIN(order_date),
    MAX(order_date)
FROM orders
GROUP BY customer_id;

INSERT INTO drivers (driver_id, driver_name, total_deliveries, avg_rating, total_distance_km)
SELECT
    driver_id,
    MAX(driver_name),
    COUNT(*),
    ROUND(AVG(rating), 1),
    ROUND(SUM(COALESCE(distance_km, 0)), 1)
FROM orders
GROUP BY driver_id;
