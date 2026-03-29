-- Enable UUID extension (optional but useful)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =========================
-- USERS TABLE
-- =========================
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role VARCHAR(50) DEFAULT 'Tenant',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_role
	CHECK (role IN ('Admin','Manager','Tenant'))
);

-- =========================
-- PROPERTIES TABLE
-- =========================
CREATE TABLE properties (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150),
    address TEXT NOT NULL,
    city VARCHAR(100),
    property_type VARCHAR(50),
    owner_name VARCHAR(150) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================
-- ROOMS TABLE
-- =========================
CREATE TABLE rooms (
    id SERIAL PRIMARY KEY,
    property_id INT NOT NULL,
    room_number VARCHAR(50) NOT NULL,
    type VARCHAR(50),
    rent_amount NUMERIC(12,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'available',
    floor INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_property
        FOREIGN KEY (property_id)
        REFERENCES properties(id)
        ON DELETE CASCADE
);

-- =========================
-- LEASES TABLE
-- =========================
CREATE TABLE leases (
    id SERIAL PRIMARY KEY,
    room_id INT NOT NULL,
    user_id INT,
    tenant_name VARCHAR(150), -- can later be replaced with tenant_id
    start_date DATE NOT NULL,
    end_date DATE,
    rent_amount NUMERIC(12,2) NOT NULL,
    deposit_amount NUMERIC(12,2),
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_room
        FOREIGN KEY (room_id)
        REFERENCES rooms(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE SET NULL
);

-- =========================
-- PAYMENTS TABLE
-- =========================
CREATE TABLE payments (
    id SERIAL PRIMARY KEY,
    lease_id INT NOT NULL,
    user_id INT,
    amount NUMERIC(12,2) NOT NULL,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    payment_method VARCHAR(50),
    transaction_reference VARCHAR(100) NOT NULL,
    status VARCHAR(50) DEFAULT 'Not paid',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_lease
        FOREIGN KEY (lease_id)
        REFERENCES leases(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_payment_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE SET NULL
);

-- =========================
-- MAINTENANCE REQUESTS TABLE
-- =========================
CREATE TABLE requests (
    id SERIAL PRIMARY KEY,
    property_id INT NOT NULL,
    room_id INT NOT NULL,
    user_id INT,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    priority VARCHAR(50) DEFAULT 'medium',
    status VARCHAR(50) DEFAULT 'open',
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP,

    CONSTRAINT fk_request_property
        FOREIGN KEY (property_id)
        REFERENCES properties(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_request_room
        FOREIGN KEY (room_id)
        REFERENCES rooms(id)
        ON DELETE SET NULL,

    CONSTRAINT fk_request_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE SET NULL
);

-- =========================
-- AUDIT LOGS TABLE
-- =========================
CREATE TABLE audit_logs (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    action VARCHAR(50) NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    record_id INT,
    old_value JSONB,
    new_value JSONB,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_audit_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE SET NULL
);

-- =========================
-- INDEXES (FOR PERFORMANCE)
-- =========================
CREATE INDEX idx_rooms_property_id ON rooms(property_id);
CREATE INDEX idx_leases_room_id ON leases(room_id);
CREATE INDEX idx_payments_lease_id ON payments(lease_id);
CREATE INDEX idx_requests_property_id ON requests(property_id);
CREATE INDEX idx_audit_user_id ON audit_logs(user_id);



CREATE OR REPLACE FUNCTION audit_trigger_function()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id INT;
BEGIN
    -- Try to extract user_id if the column exists
    IF TG_OP = 'DELETE' THEN
        IF to_jsonb(OLD) ? 'user_id' THEN
            v_user_id := (to_jsonb(OLD)->>'user_id')::INT;
        ELSE
            v_user_id := NULL;
        END IF;

        INSERT INTO audit_logs(user_id, action, table_name, record_id, old_value)
        VALUES (
            v_user_id,
            TG_OP,
            TG_TABLE_NAME,
            OLD.id,
            to_jsonb(OLD)
        );

        RETURN OLD;

    ELSE
        IF to_jsonb(NEW) ? 'user_id' THEN
            v_user_id := (to_jsonb(NEW)->>'user_id')::INT;
        ELSE
            v_user_id := NULL;
        END IF;

        INSERT INTO audit_logs(user_id, action, table_name, record_id, old_value, new_value)
        VALUES (
            v_user_id,
            TG_OP,
            TG_TABLE_NAME,
            NEW.id,
            CASE WHEN TG_OP = 'UPDATE' THEN to_jsonb(OLD) ELSE NULL END,
            to_jsonb(NEW)
        );

        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;


--Triggers

CREATE TRIGGER users_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON users
FOR EACH ROW
EXECUTE FUNCTION audit_trigger_function();


CREATE TRIGGER properties_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON properties
FOR EACH ROW
EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER rooms_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON rooms
FOR EACH ROW
EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER leases_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON leases
FOR EACH ROW
EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER payments_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON payments
FOR EACH ROW
EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER requests_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON requests
FOR EACH ROW
EXECUTE FUNCTION audit_trigger_function();



ALTER TABLE audit_logs ALTER COLUMN user_id DROP NOT NULL;
