-- Transport Management System Database

-- Create the database
DROP DATABASE IF EXISTS transport_management;
CREATE DATABASE transport_management;
USE transport_management;

-- 1. Vehicle Types Table
CREATE TABLE vehicle_types (
    type_id INT AUTO_INCREMENT PRIMARY KEY,
    type_name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(200),
    max_capacity_kg DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) COMMENT 'Stores different types of vehicles in the fleet';

-- 2. Vehicles Table
CREATE TABLE vehicles (
    vehicle_id INT AUTO_INCREMENT PRIMARY KEY,
    registration_number VARCHAR(20) NOT NULL UNIQUE,
    type_id INT NOT NULL,
    make VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    year INT NOT NULL,
    acquisition_date DATE NOT NULL,
    current_status ENUM('active', 'maintenance', 'retired') DEFAULT 'active',
    last_maintenance_date DATE,
    next_maintenance_date DATE,
    CONSTRAINT fk_vehicle_type FOREIGN KEY (type_id) 
        REFERENCES vehicle_types(type_id) ON DELETE RESTRICT
) COMMENT 'Main table for all vehicles in the fleet';

-- 3. Drivers Table
CREATE TABLE drivers (
    driver_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    license_number VARCHAR(30) NOT NULL UNIQUE,
    license_type VARCHAR(20) NOT NULL,
    license_expiry DATE NOT NULL,
    contact_number VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    hire_date DATE NOT NULL,
    status ENUM('active', 'on_leave', 'terminated') DEFAULT 'active',
    CHECK (license_expiry > hire_date)
) COMMENT 'Stores all driver information';

-- 4. Driver Qualifications Junction Table (M-M relationship)
CREATE TABLE driver_qualifications (
    driver_id INT NOT NULL,
    vehicle_type_id INT NOT NULL,
    certification_date DATE NOT NULL,
    certifying_authority VARCHAR(100),
    PRIMARY KEY (driver_id, vehicle_type_id),
    CONSTRAINT fk_driver_qual FOREIGN KEY (driver_id) 
        REFERENCES drivers(driver_id) ON DELETE CASCADE,
    CONSTRAINT fk_vehicle_type_qual FOREIGN KEY (vehicle_type_id) 
        REFERENCES vehicle_types(type_id) ON DELETE CASCADE
) COMMENT 'Tracks which drivers are qualified for which vehicle types';

-- 5. Customers Table
CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    company_name VARCHAR(100) NOT NULL,
    contact_person VARCHAR(100),
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    address TEXT NOT NULL,
    tax_id VARCHAR(30),
    customer_since DATE NOT NULL,
    credit_limit DECIMAL(12,2),
    status ENUM('active', 'inactive', 'suspended') DEFAULT 'active'
) COMMENT 'Customer information for shipments';

-- 6. Routes Table
CREATE TABLE routes (
    route_id INT AUTO_INCREMENT PRIMARY KEY,
    origin VARCHAR(100) NOT NULL,
    destination VARCHAR(100) NOT NULL,
    distance_km DECIMAL(8,2) NOT NULL,
    estimated_duration_min INT NOT NULL,
    standard_fare DECIMAL(10,2) NOT NULL,
    UNIQUE KEY unique_route (origin, destination),
    CHECK (distance_km > 0),
    CHECK (estimated_duration_min > 0)
) COMMENT 'Standard routes for shipments';

-- 7. Shipments Table
CREATE TABLE shipments (
    shipment_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    route_id INT NOT NULL,
    vehicle_id INT,
    driver_id INT,
    shipment_date DATETIME NOT NULL,
    estimated_arrival DATETIME NOT NULL,
    actual_arrival DATETIME,
    status ENUM('pending', 'in_transit', 'delivered', 'cancelled') DEFAULT 'pending',
    weight_kg DECIMAL(8,2) NOT NULL,
    special_instructions TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_shipment_customer FOREIGN KEY (customer_id) 
        REFERENCES customers(customer_id) ON DELETE RESTRICT,
    CONSTRAINT fk_shipment_route FOREIGN KEY (route_id) 
        REFERENCES routes(route_id) ON DELETE RESTRICT,
    CONSTRAINT fk_shipment_vehicle FOREIGN KEY (vehicle_id) 
        REFERENCES vehicles(vehicle_id) ON DELETE SET NULL,
    CONSTRAINT fk_shipment_driver FOREIGN KEY (driver_id) 
        REFERENCES drivers(driver_id) ON DELETE SET NULL,
    CHECK (estimated_arrival > shipment_date),
    CHECK (actual_arrival IS NULL OR actual_arrival >= shipment_date)
) COMMENT 'Main table tracking all shipments';

-- 8. Maintenance Records Table
CREATE TABLE maintenance_records (
    maintenance_id INT AUTO_INCREMENT PRIMARY KEY,
    vehicle_id INT NOT NULL,
    maintenance_type ENUM('routine', 'repair', 'inspection') NOT NULL,
    maintenance_date DATE NOT NULL,
    completion_date DATE NOT NULL,
    cost DECIMAL(10,2) NOT NULL,
    description TEXT NOT NULL,
    service_provider VARCHAR(100),
    next_maintenance_date DATE,
    CONSTRAINT fk_maintenance_vehicle FOREIGN KEY (vehicle_id) 
        REFERENCES vehicles(vehicle_id) ON DELETE CASCADE,
    CHECK (completion_date >= maintenance_date),
    CHECK (cost >= 0)
) COMMENT 'Tracks all vehicle maintenance activities';

-- 9. Driver Assignments Table
CREATE TABLE driver_assignments (
    assignment_id INT AUTO_INCREMENT PRIMARY KEY,
    driver_id INT NOT NULL,
    vehicle_id INT NOT NULL,
    assignment_date DATE NOT NULL,
    end_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT,
    CONSTRAINT fk_assignment_driver FOREIGN KEY (driver_id) 
        REFERENCES drivers(driver_id) ON DELETE CASCADE,
    CONSTRAINT fk_assignment_vehicle FOREIGN KEY (vehicle_id) 
        REFERENCES vehicles(vehicle_id) ON DELETE CASCADE,
    CHECK (end_date IS NULL OR end_date >= assignment_date)
) COMMENT 'Tracks which drivers are assigned to which vehicles';

-- 10. Shipment Tracking Table
CREATE TABLE shipment_tracking (
    tracking_id INT AUTO_INCREMENT PRIMARY KEY,
    shipment_id INT NOT NULL,
    checkpoint_name VARCHAR(100) NOT NULL,
    checkpoint_time DATETIME NOT NULL,
    location VARCHAR(100) NOT NULL,
    status_update VARCHAR(200),
    CONSTRAINT fk_tracking_shipment FOREIGN KEY (shipment_id) 
        REFERENCES shipments(shipment_id) ON DELETE CASCADE
) COMMENT 'Detailed tracking history for shipments';

-- Create indexes for performance
CREATE INDEX idx_vehicle_status ON vehicles(current_status);
CREATE INDEX idx_shipment_status ON shipments(status);
CREATE INDEX idx_shipment_dates ON shipments(shipment_date, estimated_arrival);
CREATE INDEX idx_driver_license ON drivers(license_number);
CREATE INDEX idx_vehicle_reg ON vehicles(registration_number);
