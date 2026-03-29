-- USERS (5)
INSERT INTO users (username, email, password_hash, role)
SELECT 
    'user' || g,
    'user' || g || '@test.com',
    'hash' || g,
    CASE 
        WHEN g % 3 = 0 THEN 'Admin'
        WHEN g % 3 = 1 THEN 'Manager'
        ELSE 'Tenant'
    END
FROM generate_series(1,5) g;

-- PROPERTIES (5)
INSERT INTO properties (name, address, owner_name)
SELECT 
    'Property ' || g,
    'Address ' || g,
    'Owner ' || g
FROM generate_series(1,5) g;

-- ROOMS (10)
INSERT INTO rooms (property_id, room_number, type, rent_amount)
SELECT 
    ((g - 1) % 5) + 1,
    'R' || g,
    'Type ' || g,
    1000 + (g * 100)
FROM generate_series(1,10) g;

-- LEASES (10)
INSERT INTO leases (room_id, user_id, tenant_name, start_date, rent_amount)
SELECT 
    ((g - 1) % 10) + 1,
    ((g - 1) % 5) + 1,
    'Tenant ' || g,
    CURRENT_DATE,
    1000 + (g * 50)
FROM generate_series(1,10) g;

-- PAYMENTS (10)
INSERT INTO payments (lease_id, user_id, amount, transaction_reference, payment_method)
SELECT 
    ((g - 1) % 10) + 1,
    ((g - 1) % 5) + 1,
    500 + (g * 20),
    'TXN' || g,
    'M-Pesa'
FROM generate_series(1,10) g;

-- REQUESTS (10)
INSERT INTO requests (property_id, room_id, user_id, title)
SELECT 
    ((g - 1) % 5) + 1,
    ((g - 1) % 10) + 1,
    ((g - 1) % 5) + 1,
    'Issue ' || g
FROM generate_series(1,10) g;




-- DELETE 10 requests
DELETE FROM requests WHERE id IN (
    SELECT id FROM requests ORDER BY id LIMIT 10
);

-- DELETE 5 payments
DELETE FROM payments WHERE id IN (
    SELECT id FROM payments ORDER BY id LIMIT 5
);

-- DELETE 5 leases
DELETE FROM leases WHERE id IN (
    SELECT id FROM leases ORDER BY id LIMIT 5
);

-- DELETE 5 rooms
DELETE FROM rooms WHERE id IN (
    SELECT id FROM rooms ORDER BY id LIMIT 5
);

-- DELETE 5 properties
DELETE FROM properties WHERE id IN (
    SELECT id FROM properties ORDER BY id LIMIT 5
);



