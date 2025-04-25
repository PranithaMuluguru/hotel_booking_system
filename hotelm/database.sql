-- Users table stores details of all users, including guests and hosts
-- anusha@hp:~/hotelm$ sudo -u postgres psql -d Hotel
-- [sudo] password for anusha: 
-- psql (14.17 (Ubuntu 14.17-0ubuntu0.22.04.1))
-- Type "help" for help.

-- Hotel=# GRANT SELECT, INSERT, UPDATE, DELETE
--   ON TABLE users
--   TO hotel_app;
-- GRANT
-- Hotel=# GRANT USAGE ON SEQUENCE users_user_id_seq TO hotel_app;
-- GRANT
-- Hotel=# GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO hotel_app;
-- ALTER DEFAULT PRIVILEGES IN SCHEMA public
--   GRANT ALL PRIVILEGES ON TABLES TO hotel_app;
-- GRANT
-- ALTER DEFAULT PRIVILEGES
-- Hotel=# GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO hotel_app;
-- ALTER DEFAULT PRIVILEGES IN SCHEMA public
--   GRANT ALL PRIVILEGES ON SEQUENCES TO hotel_app;
-- GRANT
-- ALTER DEFAULT PRIVILEGES
-- Hotel=# \q
DELETE FROM payment_details WHERE payment_status = ;
SELECT
    COALESCE(SUM(pd.payment_amount), 0.00) AS total_spent,
    COUNT(b.booking_id) AS total_bookings,
    COUNT(CASE WHEN b.status = 'confirmed' THEN 1 END) AS confirmed_bookings,
    COUNT(CASE WHEN b.status = 'cancelled' THEN 1 END) AS cancelled_bookings,
    COUNT(CASE WHEN pd.payment_status = 'completed' THEN 1 END) AS successful_payments
FROM bookings b
LEFT JOIN payment_details pd USING (payment_id)
WHERE b.guest_id = 1;
DROP TABLE users CASCADE;
CREATE TABLE users(
	user_id SERIAL PRIMARY KEY NOT NULL,
	user_name VARCHAR(255) UNIQUE NOT NULL,
	password_hashed VARCHAR(255) NOT NULL,
	first_name VARCHAR(225) NOT NULL,
	last_name VARCHAR(225) NOT NULL,
	address TEXT,
	phone_number VARCHAR(20),
	age INTEGER,
	email VARCHAR(255) UNIQUE,
	created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	role text
);

SELECT * FROM users;
-- Enable pgcrypto extension (only required once)
CREATE EXTENSION IF NOT EXISTS pgcrypto;
select * from bookings;
-- Insert user data with hashed passwords
INSERT INTO users (user_id, user_name, password_hashed, first_name, last_name, address, phone_number, age, email, created_at, Role)
VALUES 
(1, 'user1', 'password1', 'John', 'Doe', '123 Main St, Cityville', '111-222-3333', 28, 'user1@example.com', '2025-03-01 08:00:00', 'guest'),
(2, 'user2', 'password2', 'Alice', 'Smith', '456 Oak Ave, Townsville', '222-333-4444', 32, 'user2@example.com', '2025-03-01 08:05:00', 'host'),
(3, 'user3', 'password3', 'Mike', 'Brown', '789 Pine Rd, Villageton', '333-444-5555', 45, 'user3@example.com', '2025-03-01 08:10:00', 'guest'),
(4, 'user4', 'password4', 'Sarah', 'Lee', '101 Maple Blvd, Hamlet', '444-555-6666', 27, 'user4@example.com', '2025-03-01 08:15:00', 'host'),
(5, 'user5', 'password5',  'David', 'Wilson', '202 Birch St, Metro City', '555-666-7777', 36, 'user5@example.com', '2025-03-01 08:20:00', 'guest'),
(6, 'user6', 'password6', 'Emma', 'Johnson', '303 Cedar Dr, Uptown', '666-777-8888', 29, 'user6@example.com', '2025-03-01 08:25:00', 'guest'),
(7, 'user7','password7',  'Liam', 'Williams', '404 Spruce Ln, Downtown', '777-888-9999', 40, 'user7@example.com', '2025-03-01 08:30:00', 'guest'),
(8, 'user8', 'password8',  'Olivia', 'Jones', '505 Elm St, Suburbia', '888-999-0000', 33, 'user8@example.com', '2025-03-01 08:35:00', 'host'),
(9, 'user9', 'password9','Noah', 'Davis', '606 Walnut Ave, Oldtown', '999-000-1111', 22, 'user9@example.com', '2025-03-01 08:40:00', 'guest'),
(10, 'user10', 'password10',  'Ava', 'Martin', '707 Chestnut Rd, Riverside', '000-111-2222', 31, 'user10@example.com', '2025-03-01 08:45:00', 'guest');

INSERT INTO users ( user_name, password_hashed, first_name, last_name, address, phone_number, age, email, created_at, Role)
VALUES 
('user33', 'password33', 'Jp', 'Doe', '123 Main St, Cityville', '111-222-3333', 28, 'user33@example.com', '2025-03-01 08:00:00', 'host');
-- Guests table stores users who book hotels
INSERT INTO users (user_name, password_hashed, first_name, last_name, role)
VALUES ('admin', 'admin123', 'Admin', 'User', 'admin');
select * from users;
CREATE TABLE guest(
	guest_id SERIAL PRIMARY KEY NOT NULL,
	user_id INTEGER NOT NULL  REFERENCES users(user_id) ON DELETE CASCADE
);
SELECT * FROM guest;

-- Hosts table stores users who list hotels

CREATE TABLE host(
	host_id SERIAL PRIMARY KEY NOT NULL,
	user_id INTEGER NOT NULL  REFERENCES users(user_id) ON DELETE CASCADE
);
SELECT * FROM host;

-- Example schema modifications
ALTER TABLE hotel
DROP CONSTRAINT hotel_host_id_fkey,
ADD CONSTRAINT hotel_host_id_fkey
FOREIGN KEY (host_id) REFERENCES host(host_id) ON DELETE CASCADE;

ALTER TABLE rooms
DROP CONSTRAINT rooms_hotel_id_fkey,
ADD CONSTRAINT rooms_hotel_id_fkey
FOREIGN KEY (hotel_id) REFERENCES hotel(hotel_id) ON DELETE CASCADE;

-- Hotels table stores details of hotels listed by hosts

CREATE TABLE hotel(
	hotel_id SERIAL PRIMARY KEY NOT NULL,
	host_id INTEGER NOT NULL REFERENCES host(host_id) ON DELETE CASCADE,
	name VARCHAR(255) UNIQUE NOT NULL,
	address TEXT,
	city TEXT,
	state TEXT,
	phone_number VARCHAR(20),
	email VARCHAR(255) UNIQUE,
	total_rooms INTEGER,
	zip_code INTEGER,
	rating DECIMAL
);

SELECT * FROM hotel;

SELECT *
            FROM discounts 
            ;
-- Enum type for room availability status
CREATE TYPE room_status AS ENUM ('unavailable', 'available');

-- Rooms table stores information about individual hotel rooms

CREATE TABLE Rooms(
	room_id SERIAL PRIMARY KEY NOT NULL,
	room_number INTEGER NOT NULL,
	price DECIMAL,
	capacity INTEGER DEFAULT 1,
	-- status room_status DEFAULT 'available',
	hotel_id INTEGER REFERENCES hotel(hotel_id),
	UNIQUE(hotel_id,room_number)
	
);
ALTER TABLE rooms ADD COLUMN images TEXT[];  -- For PostgreSQL array storage
ALTER TABLE rooms
  DROP COLUMN image_data ;

-- Run this in your PostgreSQL database
ALTER TABLE rooms
ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
select * from rooms;
-- ALTER TABLE Rooms
-- DROP COLUMN status ;
CREATE TYPE room_type as enum ('AC','Non-AC');
ALTER TABLE Rooms
ADD COLUMN room_type TEXT NOT NULL DEFAULT 'Non-AC';

UPDATE Rooms SET room_type = 
	CASE WHEN room_id in (1,2,4,5,7,8) THEN 'AC'
	ELSE 'Non-AC'
	END;


SELECT * FROM rooms;

-- Amenities table stores various room amenities

CREATE TABLE Amenities(
	amenity_id SERIAL PRIMARY KEY NOT NULL,
	name TEXT,
	description TEXT
);

SELECT * FROM amenities;

----------------------------------------
CREATE TABLE hotel_amenity(
	hotel_id INTEGER NOT NULL REFERENCES Hotel(hotel_id),
	amenity_id INTEGER NOT NULL REFERENCES Amenities(amenity_id),
	PRIMARY KEY (hotel_id, amenity_id)
);


CREATE TYPE booking_status AS ENUM ('pending', 'confirmed', 'cancelled');

-- Bookings table stores hotel booking details
DROP TABLE Bookings CASCADE;
CREATE TABLE bookings(
	booking_id SERIAL PRIMARY KEY NOT NULL,
	check_in_date DATE NOT NULL,
	check_out_date DATE NOT NULL,
	total_price DECIMAL,
	status booking_status DEFAULT 'pending',
	booking_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	payment_id INTEGER REFERENCES Payment_details(payment_id),
	room_id INTEGER REFERENCES Rooms(room_id),
	guest_id INTEGER REFERENCES guest(guest_id) ON DELETE CASCADE
);
ALTER TABLE bookings
  DROP CONSTRAINT bookings_room_id_fkey;

ALTER TABLE bookings
  ADD CONSTRAINT bookings_room_id_fkey
    FOREIGN KEY(room_id)
    REFERENCES rooms(room_id)
    ON DELETE SET NULL;

ALTER TABLE bookings DROP COLUMN payment_id;
select * from rooms;
INSERT INTO bookings (check_in_date, check_out_date, total_price, status, booking_date, room_id, guest_id)
VALUES
  ('2025-04-01', '2025-04-05', 600.00, 'confirmed', '2025-03-01 12:00:00',  1, 1),
  ('2025-04-06', '2025-04-09', 450.00, 'confirmed', '2025-03-02 10:30:00',  2, 2),
  ('2025-04-10', '2025-04-15', 750.00, 'pending',   '2025-03-03 11:15:00',  4, 3),
  ('2025-04-16', '2025-04-20', 500.00, 'confirmed', '2025-03-04 09:45:00',  5, 4),
  ('2025-04-21', '2025-04-25', 800.00, 'confirmed', '2025-03-05 14:30:00',  7, 5),
  ('2025-04-26', '2025-04-30', 650.00, 'pending',   '2025-03-06 15:00:00',  8, 6),
  ('2025-05-01', '2025-05-05', 550.00, 'confirmed', '2025-03-07 08:30:00',  3, 7),
  ('2025-05-06', '2025-05-10', 720.00, 'confirmed', '2025-03-08 11:00:00',  6, 1),
  ('2025-05-11', '2025-05-15', 830.00, 'pending',   '2025-03-09 09:15:00',  9, 2),
  ('2025-05-16', '2025-05-20', 910.00, 'confirmed', '2025-03-10 10:00:00',  10, 3);
 INSERT INTO bookings (check_in_date, check_out_date, total_price, status, booking_date, room_id, guest_id)
VALUES
  ('2025-03-01', '2025-03-05', 600.00, 'confirmed', '2025-03-01 12:00:00',  4,14 );
  

select * from bookings;
select * from hotel;
CREATE TABLE Payment_Details (
    payment_id SERIAL PRIMARY KEY NOT NULL,
    payment_date DATE ,
    mode_of_payment VARCHAR(50),
    payment_amount NUMERIC(10, 2) NOT NULL,
    payment_status VARCHAR(20)
);
drop table payment_details CASCADE;
ALTER TABLE Payment_Details
ADD COLUMN booking_id INTEGER REFERENCES Bookings(booking_id) ON DELETE SET NULL;
INSERT INTO Payment_Details (payment_date, mode_of_payment, payment_amount, payment_status,booking_id)
VALUES
  ('2025-03-01', 'Credit Card', 600.00, 'confirmed',1),
  ('2025-03-02', 'Debit Card', 450.00, 'confirmed',2),
  ('2025-03-03', 'Debit card', 750.00, 'pending',3),
  ('2025-03-04', 'Credit Card', 500.00, 'confirmed',4),
  ('2025-03-05', 'Debit Card', 800.00, 'confirmed',5),
  ('2025-03-06', 'Credit card', 650.00, 'pending',6),
  ('2025-03-07', 'Credit Card', 550.00, 'confirmed',7),
  ('2025-03-08', 'Debit Card', 720.00, 'confirmed',8),
  ('2025-03-09', 'Credit Card', 830.00, 'pending',9),
  ('2025-03-10', 'Debit card', 910.00, 'confirmed',10);
INSERT INTO Payment_Details (payment_date, mode_of_payment, payment_amount, payment_status,booking_id)
VALUES
  ('2025-03-01', 'Credit Card', 600.00, 'confirmed',26);
select *  from payment_details;
SELECT DISTINCT mode_of_payment FROM payment_details;
-- Review table stores user reviews for hotels

CREATE TABLE Review(
	review_id SERIAL PRIMARY KEY NOT NULL,
	rating DECIMAL  NOT NULL,
	comment text,
	review_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	booking_id INTEGER REFERENCES Bookings(booking_id),
	guest_id INTEGER REFERENCES guest(guest_id),
	hotel_id INTEGER REFERENCES hotel(hotel_id),
	CONSTRAINT unique_booking_id UNIQUE (booking_id) -- Unique constraint on booking_id

);
drop table review;
SELECT * FROM review;

-- Cancellation table stores booking cancellation details

CREATE TABLE Cancellation(
    cancellation_id  SERIAL PRIMARY KEY,
    Cancellation_date DATE,
	cancellation_reason TEXT,
    Refund_amount DECIMAL(10, 2),
   	booking_id  INTEGER REFERENCES bookings(booking_id) ON DELETE CASCADE
);

SELECT * FROM cancellation;
drop table cancellation;
-- Discounts table stores discount details and promo codes
drop table discounts;
CREATE TABLE Discounts(
    discount_id SERIAL PRIMARY KEY NOT NULL,
    Promo_code VARCHAR(50) NOT NULL,
    discount_amount NUMERIC(10, 2) NOT NULL,
    valid_from DATE NOT NULL,
    valid_until DATE NOT NULL,
    description TEXT,
   	booking_id  INTEGER REFERENCES bookings(booking_id) ON DELETE CASCADE
);
SELECT * FROM discounts;

-- Notifications table stores messages sent to users

CREATE TABLE notifications (
    notification_id SERIAL PRIMARY KEY NOT NULL,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    notification_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
SELECT * FROM notifications;
INSERT INTO notifications (user_id, message) VALUES (1, 'Test message');
-- Hotel images table stores URLs of images for each hotel

-- Login attempts table tracks login activity of users

CREATE TABLE Login_Attempts (
    attempt_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id),
    login_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    login_success BOOLEAN
);

SELECT * FROM login_attempts;


--Inserting values into host
INSERT INTO host(host_id,user_id)
VALUES 
(1,2),
(2,4),
(3,8);
INSERT INTO host(host_id,user_id)
VALUES 
(4,15);
--Inserting values into guest

INSERT INTO guest(guest_id,user_id)
VALUES 
(1,1),
(2,3),
(3,5),
(4,6),
(5,7),
(6,9),
(7,10);
INSERT INTO guest(user_id)
VALUES 

(33);

--Inserting values into hotel
select * from hotel;
select * from rooms;
INSERT INTO hotel(hotel_id, host_id, name, address, city, state, phone_number, email, total_rooms, zip_code, rating)
VALUES 
(1, 1, 'Grand Plaza', '100 Luxury Ave', 'Metropolis', 'State1', '111-222-3333', 'grandplaza@example.com', 120, 12345, 4.5),
(2, 2, 'Sunrise Inn', '200 Ocean Dr', 'Beachside', 'State2', '222-333-4444', 'sunriseinn@example.com', 80, 23456, 4.2),
(3, 3, 'Mountain Retreat', '300 Alpine Rd', 'Highland', 'State3', '333-444-5555', 'mountainretreat@example.com', 50, 34567, 4.8);
INSERT INTO hotel(hotel_id, host_id, name, address, city, state, phone_number, email, total_rooms, zip_code, rating)
VALUES
(4, 3, 'Taj', '300 Alpine Rd', 'Highland', 'State3', '333-444-5555', 'taj@example.com', 50, 34567, 3.8);
INSERT INTO hotel( host_id, name, address, city, state, phone_number, email, total_rooms, zip_code, rating)
VALUES
( 3, 'Queen', 'hyderabad', 'Beachside', 'State4', '352-444-5555', 'queen@example.com', 20, 34367, 4.2);


INSERT INTO rooms(room_id,room_number,price,capacity,hotel_id)
VALUES
(1, 101, 150.00, 2, 1),
(2, 102, 170.00, 2, 1),
(3, 103, 200.00, 3, 1),
(4, 201, 120.00, 2,  2),
(5, 101, 130.00, 2,  2),
(6, 203, 140.00, 2,  2),
(7, 301, 180.00, 3,  3),
(8, 302, 190.00, 3, 3),
(9, 303, 210.00, 4, 3),
(10, 304, 220.00, 4, 3);
INSERT INTO rooms(room_id,room_number,price,capacity,hotel_id)
VALUES
(11, 101, 520.00, 3, 4),
(12, 102, 320.00, 4,  4);
INSERT INTO rooms(room_number,price,capacity,hotel_id)
VALUES
( 11, 520.00, 3, 1);


--Inserting values into amenities

INSERT INTO amenities (amenity_id, name, description)
VALUES 
(1, 'WiFi', 'High-speed wireless internet'),
(2, 'Breakfast', 'Complimentary breakfast'),
(3, 'Pool', 'Outdoor swimming pool'),
(4, 'Gym', 'Well-equipped fitness center'),
(5, 'Spa', 'Relaxing spa services'),
(6, 'Parking', 'Free parking available'),
(7, 'Bar', 'In-house bar and lounge'),
(8, 'Restaurant', 'Fine dining restaurant'),
(9, 'Room Service', '24/7 in-room dining'),
(10, 'Airport Shuttle', 'Free shuttle service');


--Inserting values into room_amenity

INSERT INTO hotel_amenity (hotel_id, amenity_id)
VALUES 
(1,1),--------•⁠  ⁠Grand Plaza has WiFi, Breakfast, Pool
(1,2),
(1,3),
(2,1),----------.•⁠  ⁠Sunrise Inn has WiFi, Gym, Parking
(2,4),
(2,6),
(3,5),-------------•  ⁠Mountain Retreat has Spa, Bar, Restaurant
(3,7),
(3,8),
(4,9),--------------•   Taj has Room Service, Airport Shuttle
(4,10);


--Inserting values into cancellation

INSERT INTO cancellation (booking_id, Cancellation_date, cancellation_reason, Refund_amount)
VALUES
( 1, '2025-03-28', 'Plans changed', 340.00),
( 4, '2025-03-29', 'Emergency cancellation', 450.00),
( 10, '2025-03-30', 'Customer request', 380.00);


--Inserting values into review

INSERT INTO review ( rating, comment, review_date, booking_id, guest_id, hotel_id)
VALUES
( 4.0, 'Very comfortable', '2025-04-13 10:00:00', 2, 2, 1),
( 4.8, 'Loved the mountain view', '2025-03-27 07:30:00', 5, 5, 3),
( 4.2, 'Room was clean and spacious', '2025-03-25 10:20:00', 7, 7, 1),
( 4.0, 'Pleasant experience overall', '2025-03-29 14:10:00', 8, 1, 2);

--Inserting values into discounts
select * from payment_details;
select * from bookings;
INSERT INTO discounts ( Promo_code, discount_amount, valid_from, valid_until, description)
VALUES
( 'DISCOUNT10', 10.00, '2025-04-01', '2025-04-30', 'Spring discount'),
( 'SUMMER15', 15.00, '2025-06-01', '2025-06-30', 'Summer special'),
( 'WINTER20', 20.00, '2025-12-01', '2025-12-31', 'Winter sale'),
( 'FLASH5', 5.00, '2025-03-15', '2025-03-20', 'Flash deal'),
( 'NEWYEAR25', 25.00, '2026-01-01', '2026-01-31', 'New Year offer'),
( 'VIP30', 30.00, '2025-05-01', '2025-05-31', 'VIP discount'),
( 'EARLYBIRD10', 10.00, '2025-07-01', '2025-07-15', 'Early bird offer'),
( 'LASTMIN20', 20.00, '2025-08-01', '2025-08-10', 'Last minute deal'),
( 'EXCLUSIVE15', 15.00, '2025-09-01', '2025-09-30', 'Exclusive offer'),
( 'SEASONAL5', 5.00, '2025-3-01', '2025-3-31', 'Seasonal discount');

--Inserting values into notifications

INSERT INTO notifications(notification_id, user_id, message, notification_date)
VALUES
(1, 1, 'Bookings are open now—reserve your stay today!', '2025-03-01 12:05:00'),
(2, 2, 'New discounts available on your next booking.', '2025-03-01 12:10:00'),
(3, 3, 'Enjoy exclusive deals—book your room now!', '2025-03-02 09:15:00'),
(4, 4, 'Hurry! Special rates available for a limited time.', '2025-03-02 10:20:00'),
(5, 5, 'Reserve your room and save with our latest offers.', '2025-03-03 11:05:00'),
(6, 6, 'Secure your reservation; bookings are officially open!', '2025-03-03 12:30:00'),
(7, 7, 'Check out our new offers and discount promotions.', '2025-03-04 08:45:00'),
(8, 8, 'Experience luxury at affordable prices—book today!', '2025-03-04 09:50:00'),
(9, 9, 'Limited time discount on premium rooms—act fast!', '2025-03-05 14:30:00'),
(10, 10, 'Don’t miss out—special booking rates available now.', '2025-03-05 15:20:00'),
(11, 1, 'Exclusive offer: Book now and enjoy extra perks.', '2025-04-01 12:05:00'),
(12, 2, 'Discover new deals: Discounts available on selected hotels.', '2025-04-01 12:10:00');

--Inserting values into login_attempts

INSERT INTO login_attempts (attempt_id, user_id, login_time, login_success)
VALUES
(1, 1, '2025-03-01 07:55:00', TRUE),
(2, 2, '2025-03-01 08:00:00', TRUE),
(3, 3, '2025-03-01 08:05:00', FALSE),
(4, 4, '2025-03-01 08:10:00', TRUE),
(5, 5, '2025-03-01 08:15:00', TRUE),
(6, 6, '2025-03-01 08:20:00', FALSE),
(7, 7, '2025-03-01 08:25:00', TRUE),
(8, 8, '2025-03-01 08:30:00', TRUE),
(9, 9, '2025-03-01 08:35:00', FALSE),
(10, 10, '2025-03-01 08:40:00', TRUE),
(11, 3, '2025-04-01 08:05:00', TRUE),
(12, 4, '2025-04-01 08:10:00', FALSE),
(13, 5, '2025-04-01 08:15:00', FALSE),
(14, 6, '2025-04-01 08:20:00', TRUE);
INSERT INTO login_attempts ( user_id, login_time, login_success)
VALUES
( 1, '2025-04-23 07:32:00', TRUE);

select * from login_attempts;
-----------------------------------------------------------------------------------------------------


CREATE OR REPLACE FUNCTION get_daily_booking_stats(p_hotel_id INTEGER)
RETURNS TABLE (
    booking_date DATE,
    total_bookings BIGINT,
    total_rooms_occupied BIGINT
) AS $$
BEGIN
    RETURN QUERY
    WITH daily_bookings AS (
        -- Count how many new bookings were made on each check-in date
        SELECT 
            b.check_in_date::DATE AS booking_date,
            COUNT(*) AS total_bookings
        FROM bookings b
        JOIN rooms r ON b.room_id = r.room_id
        WHERE r.hotel_id = p_hotel_id
        GROUP BY b.check_in_date
    ),
    daily_room_occupancy AS (
        -- Count how many rooms were occupied on each date in the range of all bookings
        SELECT 
            gs.booking_date::DATE AS booking_date,
            COUNT(b.booking_id) AS total_rooms_occupied
        FROM generate_series(
            (SELECT MIN(b.check_in_date) FROM bookings b JOIN rooms r ON b.room_id = r.room_id WHERE r.hotel_id = p_hotel_id),
            (SELECT MAX(b.check_out_date) FROM bookings b JOIN rooms r ON b.room_id = r.room_id WHERE r.hotel_id = p_hotel_id),
            INTERVAL '1 day'
        ) AS gs(booking_date)
        LEFT JOIN bookings b 
            ON gs.booking_date >= b.check_in_date 
            AND gs.booking_date < b.check_out_date
            AND b.room_id IN (SELECT room_id FROM rooms WHERE hotel_id = p_hotel_id)
        GROUP BY gs.booking_date
    )
    -- Combine both statistics
    SELECT 
        COALESCE(dbo.booking_date, dro.booking_date) AS booking_date,
        COALESCE(dbo.total_bookings, 0) AS total_bookings,
        COALESCE(dro.total_rooms_occupied, 0) AS total_rooms_occupied
    FROM daily_bookings dbo
    FULL OUTER JOIN daily_room_occupancy dro ON dbo.booking_date = dro.booking_date
    ORDER BY booking_date;
END;
$$ LANGUAGE plpgsql;

-- DROP FUNCTION get_daily_booking_stats;

SELECT * FROM get_daily_booking_stats(2);




--------------USER BOOKING HISTORY-----------------------------------------------------------------------------------------------------
--DROP FUNCTION get_user_booking_history;
CREATE FUNCTION get_user_booking_history(p_guest_id INT) 
RETURNS TABLE (
    booking_id INT,
    hotel_name VARCHAR(20),
    check_in DATE,
    check_out DATE,
    status booking_status
) AS $$
BEGIN
    -- Handle invalid guest_id cases
    IF p_guest_id IS NULL OR p_guest_id <= 0 THEN
        RETURN;
    END IF;

    -- Return user booking history using room_id to derive hotel_id
    RETURN QUERY
    SELECT 
        b.booking_id, 
        COALESCE(h.name, 'Unknown Hotel') AS hotel_name, 
        b.check_in_date, 
        b.check_out_date, 
        b.status
    FROM bookings b
    LEFT JOIN rooms r ON b.room_id = r.room_id  -- Join with rooms to get hotel_id
    LEFT JOIN hotel h ON r.hotel_id = h.hotel_id  -- Join with hotel to get hotel_name
    WHERE b.guest_id = p_guest_id
    ORDER BY b.booking_date DESC;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM get_user_booking_history(1);






-------------GET AVAILABLE ROOMS BY LOCATION-----------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_available_rooms_by_location(
    p_city TEXT,
    p_check_in_date DATE DEFAULT NULL,
    p_check_out_date DATE DEFAULT NULL,
    p_min_price DECIMAL DEFAULT 0,
    p_max_price DECIMAL DEFAULT 99999,
    p_min_capacity INTEGER DEFAULT 1,
    p_min_rating DECIMAL DEFAULT 0
)
RETURNS TABLE(
    room_id INTEGER,
    hotel_name TEXT,
    room_number INTEGER,
    room_type TEXT,
    price DECIMAL,
    capacity INTEGER,
    hotel_rating DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.room_id,
        h.name::TEXT AS hotel_name, -- Cast to TEXT
        r.room_number,
        r.room_type::TEXT AS room_type, -- Cast to TEXT
        r.price,
        r.capacity,
        h.rating
    FROM rooms r
    INNER JOIN hotel h ON r.hotel_id = h.hotel_id
    WHERE 
        lower(trim(h.city)) = lower(trim(p_city))
    AND COALESCE(r.price, 0) BETWEEN p_min_price AND p_max_price
    AND COALESCE(r.capacity, 0) >= p_min_capacity
    AND COALESCE(h.rating, 0) >= p_min_rating
        AND (
            p_check_in_date IS NULL OR p_check_out_date IS NULL OR NOT EXISTS (
                SELECT 1 
                FROM bookings b 
                WHERE b.room_id = r.room_id
                AND b.status IN ('pending', 'confirmed') -- Exclude cancelled bookings
                AND (p_check_in_date < b.check_out_date AND p_check_out_date > b.check_in_date)
            )
        )
    ORDER BY r.price ASC; -- Sort by price
END;
$$ LANGUAGE plpgsql;


select * from get_available_rooms_by_location('Palakkad',NULL,NULL,0,1000,0);

---------CAN BOOK ROOM--------------------------------------------------------------------------------------------------------------------



CREATE OR REPLACE FUNCTION can_book_room(
    p_room_id INTEGER,
    p_check_in_date DATE,
    p_check_out_date DATE
)
RETURNS BOOLEAN AS $$
DECLARE
    is_available BOOLEAN;
BEGIN
    -- Check if the room is available for the given dates
    SELECT COUNT(*) = 0 INTO is_available
    FROM bookings
    WHERE room_id = p_room_id
    AND status NOT IN ('cancelled')  -- Ignore cancelled bookings
    AND (p_check_in_date < check_out_date AND p_check_out_date > check_in_date);

    RETURN is_available; -- TRUE if available, FALSE if booked
END;
$$ LANGUAGE plpgsql;
select * from can_book_room(10,'2025-08-15','2025-08-20');


---------CALCULATE TOTAL COST--------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION calculate_total_cost(p_booking_id INTEGER, p_promo_code TEXT) 
RETURNS NUMERIC AS $$ 
DECLARE 
    total_days INTEGER; 
    room_rate NUMERIC; 
    total_cost NUMERIC; 
    discount NUMERIC := 0; -- Discount amount 
    promo_valid BOOLEAN := FALSE; 
BEGIN 
    -- Get the number of days for the booking 
    SELECT (check_out_date - check_in_date) 
    INTO total_days 
    FROM bookings 
    WHERE booking_id = p_booking_id; 

    -- Default to 1 day if dates are NULL or invalid
    IF total_days IS NULL OR total_days <= 0 THEN
        total_days := 1;
    END IF;

    -- Get the room price 
    SELECT price 
    INTO room_rate 
    FROM rooms 
    WHERE room_id = (SELECT room_id FROM bookings WHERE booking_id = p_booking_id); 

    -- Default to 0 if room_rate is NULL
    IF room_rate IS NULL THEN
        room_rate := 0;
    END IF;

    -- Calculate total cost before discount 
    total_cost := total_days * room_rate; 

    -- Check if the provided promo code is valid 
    SELECT d.discount_amount, 
           (CURRENT_DATE BETWEEN d.valid_from AND d.valid_until) 
    INTO discount, promo_valid 
    FROM discounts d 
    WHERE d.promo_code = p_promo_code 
    LIMIT 1; 

    -- Apply discount if promo code is valid 
    IF promo_valid THEN 
        total_cost := total_cost - discount; 
    END IF; 

    -- Ensure total cost is not negative
    IF total_cost < 0 THEN
        total_cost := 0;
    END IF;

    RETURN total_cost; 
END; 
$$ LANGUAGE plpgsql;


-- Test the function
SELECT calculate_total_cost(28, 'LASTMIN20');



--------------update_review-----------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION update_review(
    p_booking_id INTEGER,
    p_guest_id INTEGER,
    p_hotel_id INTEGER,
    p_rating DECIMAL,
    p_comment TEXT
)
RETURNS TEXT AS $$
DECLARE
    checkout_date TIMESTAMP;
BEGIN
    -- Get the checkout date for the booking
    SELECT check_out_date INTO checkout_date
    FROM bookings
    WHERE booking_id = p_booking_id;

    -- Ensure that the customer has already checked out
    IF checkout_date IS NULL OR checkout_date > CURRENT_DATE THEN
        RETURN 'Error: Cannot leave a review before checkout.';
    END IF;

    -- Validate guest and hotel match the booking
    IF NOT EXISTS (
        SELECT 1 
        FROM bookings 
        WHERE booking_id = p_booking_id 
          AND guest_id = p_guest_id 
          AND room_id IN (SELECT room_id FROM rooms WHERE hotel_id = p_hotel_id)
    ) THEN
        RETURN 'Error: Guest or hotel does not match the booking.';
    END IF;

    -- Insert or update the review
    INSERT INTO review (booking_id, guest_id, hotel_id, rating, comment, review_date)
    VALUES (p_booking_id, p_guest_id, p_hotel_id, p_rating, p_comment, CURRENT_TIMESTAMP)
    ON CONFLICT (booking_id) -- If a review already exists, update it
    DO UPDATE SET
        rating = EXCLUDED.rating,
        comment = EXCLUDED.comment,
        review_date = CURRENT_TIMESTAMP;

    RETURN 'Review updated successfully!';
END;
$$ LANGUAGE plpgsql;
ALTER TABLE review ADD CONSTRAINT unique_booking_id UNIQUE (booking_id);

SELECT update_review(21, 1, 1, 4.2, 'Great experience!');


--------------------------get_review_summary---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_review_summary(
    p_hotel_id INTEGER
)
RETURNS TABLE(
    avg_rating NUMERIC,
    total_reviews INTEGER,
    last_review_date TIMESTAMP
)
LANGUAGE plpgsql AS
$$
BEGIN
    RETURN QUERY
    SELECT 
        AVG(rating) AS avg_rating,
        COUNT(*)::INTEGER AS total_reviews,
        MAX(review_date) AS last_review_date
    FROM Review
    WHERE hotel_id = p_hotel_id;
END;
$$;

-- Example usage:
SELECT * FROM get_review_summary(2);



----------------------top_rated_hotels-------------------------------------------------------------------------------


CREATE OR REPLACE FUNCTION top_rated_hotels()
RETURNS TABLE(hotel_id INT, hotel_name VARCHAR(255), avg_rating DECIMAL) AS $$
BEGIN
    RETURN QUERY
    WITH HotelRatings AS (
        SELECT
            h.hotel_id AS h_id,
            h.name AS h_name,
            COALESCE(AVG(r.rating), 0) AS avg_rating_value
        FROM hotel h
        LEFT JOIN review r ON h.hotel_id = r.hotel_id
        GROUP BY h.hotel_id, h.name
    )
    SELECT h_id AS hotel_id, h_name AS hotel_name, avg_rating_value AS avg_rating
    FROM HotelRatings
    ORDER BY avg_rating DESC, hotel_name ASC
    LIMIT 3;
END;
$$ LANGUAGE plpgsql;

select * from top_rated_hotels();


--------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CREATE OR REPLACE FUNCTION register_user(
--     p_username VARCHAR,
--     p_password TEXT,
--     p_first_name VARCHAR,
--     p_last_name VARCHAR,
--     p_address TEXT,
--     p_phone VARCHAR,
--     p_age INT,
--     p_email VARCHAR,
--     p_role VARCHAR
-- ) RETURNS TEXT AS $$
-- BEGIN
--     INSERT INTO users (
--         user_name, 
--         password_hashed, 
--         first_name, 
--         last_name, 
--         address, 
--         phone, 
--         age, 
--         email, 
--         role
--     ) VALUES (
--         p_username,
--         crypt(p_password, gen_salt('bf')),
--         p_first_name,
--         p_last_name,
--         p_address,
--         p_phone,
--         p_age,
--         p_email,
--         p_role
--     );
--     RETURN 'Success: User registered';
-- EXCEPTION 
--     WHEN unique_violation THEN
--         RETURN 'Error: Username/Email already exists';
--     WHEN others THEN
--         RAISE NOTICE 'Registration failed: %', SQLERRM;  -- DEBUG PRINT
--         RETURN 'Error: Registration failed';
-- END;
-- $$ LANGUAGE plpgsql;
-- SELECT * FROM register_user(
--     'user13',
--     'password13',
--     'Anusha',
--     'Dadam',
--     '112 Main St',
--     '112-222-9990',
--     17,
--     'anusha@gmail.com',
--     'user'
-- );

-- INSERT INTO users (
--     user_name, 
--     password_hashed, 
--     first_name, 
--     last_name, 
--     address, 
--     phone_number, 
--     age, 
--     email, 
--     role
-- ) VALUES (
--     'user13',
--     'password13',
--     'Anusha',
--     'Dadam',
--     '112 Main St',
--     '112-222-9990',
--     17,
--     'anusha@gmail.com',
--     'user'
-- );

-- select * from users;
-- drop function register_user;

-- Get Host Stats
SELECT 
    COUNT(DISTINCT h.hotel_id) AS total_properties,
    COALESCE(SUM(b.total_price), 0) AS monthly_revenue,
    ROUND((COUNT(b.booking_id) * 100.0 / h.total_rooms), 2) AS occupancy_rate,
    ROUND(AVG(r.rating), 1) AS avg_rating
FROM host 
JOIN hotel h USING (host_id)
LEFT JOIN rooms rm USING (hotel_id)
LEFT JOIN bookings b USING (room_id)
LEFT JOIN review r USING (hotel_id)
WHERE host.user_id = current_user_id
AND b.status = 'confirmed'
AND b.check_in_date >= CURRENT_DATE - INTERVAL '30 days';

-- Get Recent Bookings
SELECT 
    u.first_name || ' ' || u.last_name AS guest_name,
    b.check_in_date AS check_in,
    b.check_out_date AS check_out,
    b.status,
    b.total_price
FROM bookings b
JOIN guest g USING (guest_id)
JOIN users u USING (user_id)
JOIN rooms r USING (room_id)
JOIN hotel h USING (hotel_id)
WHERE h.host_id = :host_id
ORDER BY b.booking_date DESC
LIMIT 5;

-- Get Recent Reviews
SELECT 
    u.first_name || ' ' || u.last_name AS guest_name,
    r.rating,
    r.comment,
    r.review_date
FROM review r
JOIN bookings b USING (booking_id)
JOIN guest g USING (guest_id)
JOIN users u USING (user_id)
JOIN rooms rm USING (room_id)
JOIN hotel h USING (hotel_id)
WHERE h.host_id = :host_id
ORDER BY r.review_date DESC
LIMIT 3;


---------------------------------------------
-- Total Properties
CREATE OR REPLACE FUNCTION get_total_properties(p_host_id INTEGER)
RETURNS INTEGER AS $$
BEGIN
    RETURN (SELECT COUNT(*) FROM hotel WHERE host_id = p_host_id);
END;
$$ LANGUAGE plpgsql;

-- Monthly Revenue
CREATE OR REPLACE FUNCTION get_monthly_revenue(p_host_id INTEGER)
RETURNS NUMERIC AS $$
BEGIN
    RETURN (
        SELECT COALESCE(SUM(b.total_price), 0)
        FROM bookings b
        JOIN rooms r USING(room_id)
        JOIN hotel h USING(hotel_id)
        WHERE h.host_id = p_host_id
        AND b.status = 'confirmed'
        AND b.check_in_date >= CURRENT_DATE - INTERVAL '30 days'
    );
END;
$$ LANGUAGE plpgsql;

-- Occupancy Rate
CREATE OR REPLACE FUNCTION get_occupancy_rate(p_host_id INTEGER)
RETURNS NUMERIC AS $$
DECLARE
    total_rooms INTEGER;
    occupied_rooms INTEGER;
BEGIN
    SELECT SUM(total_rooms) INTO total_rooms
    FROM hotel WHERE host_id = p_host_id;

    SELECT COUNT(*) INTO occupied_rooms
    FROM bookings b
    JOIN rooms r USING(room_id)
    JOIN hotel h USING(hotel_id)
    WHERE h.host_id = p_host_id
    AND b.status = 'confirmed'
    AND CURRENT_DATE BETWEEN check_in_date AND check_out_date;

    RETURN ROUND((occupied_rooms * 100.0 / NULLIF(total_rooms, 0)), 2);
END;
$$ LANGUAGE plpgsql;

-- Average Rating
CREATE OR REPLACE FUNCTION get_average_rating(p_host_id INTEGER)
RETURNS NUMERIC AS $$
BEGIN
    RETURN (
        SELECT COALESCE(ROUND(AVG(r.rating), 1), 0)
        FROM review r
        JOIN hotel h USING(hotel_id)
        WHERE h.host_id = p_host_id
    );
END;
$$ LANGUAGE plpgsql;

select * from payment_details;,

-------------------------------------------

--ADMIN VIEWS
-- 1) System stats
CREATE OR REPLACE VIEW v_system_stats AS
SELECT
  (SELECT COUNT(*) FROM users)                                      AS total_users,
  (SELECT COUNT(*) FROM bookings)                                   AS total_bookings,
  (SELECT COALESCE(SUM(payment_amount),0)
     FROM payment_details
    WHERE payment_status = 'completed')                              AS total_revenue,
  (SELECT COUNT(*) FROM hotel)                                      AS total_hotels,
  (SELECT COUNT(*) FROM rooms)                                      AS total_rooms;

SELECT * FROM v_system_stats;
-- 2) Recent bookings (last 5)
CREATE OR REPLACE VIEW v_recent_bookings AS
SELECT b.booking_id,
       b.check_in_date,
       b.check_out_date,
       b.total_price,
       b.status,
       b.booking_date,
       u.user_name    AS guest_user,
       h.name         AS hotel_name
  FROM bookings b
  JOIN guest g    ON b.guest_id = g.guest_id
  JOIN users u    ON g.user_id   = u.user_id
  JOIN rooms r    ON b.room_id   = r.room_id
  JOIN hotel h    ON r.hotel_id  = h.hotel_id
 ORDER BY b.booking_date DESC
 LIMIT 5;
 SELECT * FROM v_recent_bookings;

 --ADMIN FUNCTIONS AND TRIGGERS

 -- 1) cancel a single booking: update status → insert cancellation → delete review
CREATE OR REPLACE FUNCTION cancel_booking(
    p_booking_id  INTEGER,
    p_reason      TEXT
) RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
    v_price  NUMERIC;
BEGIN
    -- grab the amount so we can refund
    SELECT total_price INTO v_price
      FROM bookings
     WHERE booking_id = p_booking_id;

    -- mark it cancelled
    UPDATE bookings
       SET status = 'cancelled'
     WHERE booking_id = p_booking_id;

    -- log into cancellation
    INSERT INTO cancellation(
        cancellation_date,
        cancellation_reason,
        refund_amount,
        booking_id
    ) VALUES (
        CURRENT_DATE,
        p_reason,
        v_price,
        p_booking_id
    );

    -- drop any review attached
    DELETE FROM review
     WHERE booking_id = p_booking_id;
END;
$$;

-- 2) cancel *all* bookings for a given hotel_id
CREATE OR REPLACE FUNCTION cancel_bookings_by_hotel(
    p_hotel_id  INTEGER,
    p_reason    TEXT
) RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
    rec  RECORD;
BEGIN
    FOR rec IN
      SELECT b.booking_id
        FROM bookings b
        JOIN rooms r ON b.room_id = r.room_id
       WHERE r.hotel_id = p_hotel_id
         AND b.status   <> 'cancelled'
    LOOP
      -- call the single-booking helper
      PERFORM cancel_booking(rec.booking_id, p_reason);
    END LOOP;
END;
$$;

-- 3) trigger function: before deleting a hotel, clean up everything
CREATE OR REPLACE FUNCTION before_delete_hotel_cleanup()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    -- 3a) cancel & log its bookings
    PERFORM cancel_bookings_by_hotel(OLD.hotel_id, 'Hotel deleted');
    -- 3b) drop its amenity links
    DELETE FROM hotel_amenity
     WHERE hotel_id = OLD.hotel_id;
    -- 3c) drop its rooms
    DELETE FROM rooms
     WHERE hotel_id = OLD.hotel_id;

    -- now the hotel row itself can be removed without FK errors
    RETURN OLD;
END;
$$;

-- attach the trigger:
DROP TRIGGER IF EXISTS trg_before_hotel_delete ON hotel;
CREATE TRIGGER trg_before_hotel_delete
BEFORE DELETE ON hotel
FOR EACH ROW
EXECUTE FUNCTION before_delete_hotel_cleanup();

CREATE OR REPLACE FUNCTION notify_host_on_hotel_deletion()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert a notification for the host
    INSERT INTO notifications (user_id, message)
    SELECT 
        u.user_id, 
        'Your hotel "' || OLD.name || '" has been deleted.'
    FROM host h
    JOIN users u ON h.user_id = u.user_id
    WHERE h.host_id = OLD.host_id;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER hotel_deletion_notification
AFTER DELETE ON hotel
FOR EACH ROW
EXECUTE FUNCTION notify_host_on_hotel_deletion();

-- 1. Create the trigger function
CREATE OR REPLACE FUNCTION trg_delete_user_associated_records()
RETURNS TRIGGER AS $$
BEGIN
    -- Delete from guest table if exists
    DELETE FROM guest WHERE user_id = OLD.user_id;
    
    -- Delete from host table if exists
    DELETE FROM host WHERE user_id = OLD.user_id;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- 2. Create the trigger
DROP TRIGGER IF EXISTS trg_before_delete_user ON users;
CREATE TRIGGER trg_before_delete_user
BEFORE DELETE ON users
FOR EACH ROW
EXECUTE FUNCTION trg_delete_user_associated_records();



-- ──────── GUEST DASHBOARD VIEWS ─────────
CREATE OR REPLACE FUNCTION calculate_total_price(
    room_price    NUMERIC,
    check_in      DATE,
    check_out     DATE,
    promo_code    TEXT
) RETURNS NUMERIC AS $$
DECLARE
    nights    INTEGER;
    discount  NUMERIC := 0;  -- default to zero
    total     NUMERIC;
BEGIN
    -- Number of nights
    nights := check_out - check_in;

    -- Only try to look up a discount if promo_code is non-empty
    IF promo_code IS NOT NULL AND btrim(promo_code) <> '' THEN
        -- coalesce ensures discount stays 0 if no row is found
        SELECT COALESCE(
            (SELECT discount_amount
             FROM discounts
             WHERE discounts.promo_code = promo_code
               AND CURRENT_DATE BETWEEN valid_from AND valid_until
             LIMIT 1),
            0
        )
        INTO discount;
    END IF;

    -- Now discount is guaranteed non-null
    total := GREATEST(room_price * nights - discount, 0);

    RETURN total;
END;
$$ LANGUAGE plpgsql;

-- 1) Upcoming stays (non-cancelled, check_in >= today)
CREATE OR REPLACE VIEW v_guest_upcoming_travels AS
SELECT
  b.booking_id,
  g.user_id,
  b.check_in_date,
  b.check_out_date,
  b.total_price,
  b.status,
  r.room_number,
  h.name       AS hotel_name,
  pd.payment_status
FROM bookings b
JOIN guest g    ON b.guest_id = g.guest_id
JOIN rooms r    ON b.room_id = r.room_id
JOIN hotel h    ON r.hotel_id = h.hotel_id
LEFT JOIN payment_details pd ON b.booking_id = pd.booking_id
WHERE b.status <> 'cancelled'
  AND b.check_in_date >= CURRENT_DATE
ORDER BY b.check_in_date;


-- 2) Past stays (non-cancelled, check_out < today)
CREATE OR REPLACE VIEW v_guest_travel_history AS
SELECT
  b.booking_id,
  g.user_id,
  b.check_in_date,
  b.check_out_date,
  b.total_price,
  b.status,
  r.room_number,
  h.name AS hotel_name,
  pd.payment_status
FROM bookings b
JOIN guest g    ON b.guest_id = g.guest_id
JOIN rooms r    ON b.room_id = r.room_id
JOIN hotel h    ON r.hotel_id = h.hotel_id
LEFT JOIN payment_details pd ON b.booking_id = pd.booking_id
WHERE b.status <> 'cancelled'
  AND b.check_out_date < CURRENT_DATE
ORDER BY b.check_out_date DESC;

-- 3) Cancellation history
CREATE OR REPLACE VIEW v_guest_cancellation_history AS
SELECT
  c.cancellation_id,
  g.user_id,
  b.booking_id,
  c.cancellation_date,
  c.cancellation_reason,
  c.refund_amount,
  r.room_number,
  h.name AS hotel_name
FROM cancellation c
JOIN bookings b  ON c.booking_id = b.booking_id
JOIN guest g     ON b.guest_id    = g.guest_id
JOIN rooms r     ON b.room_id     = r.room_id
JOIN hotel h     ON r.hotel_id    = h.hotel_id
ORDER BY c.cancellation_date DESC;

---Triggers

-- 1) Notify guest on new booking
CREATE OR REPLACE FUNCTION trg_notify_booking_creation()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v_user_id   INT;
  v_message   TEXT;
BEGIN
  -- look up the guest's user_id
  SELECT g.user_id INTO v_user_id
    FROM guest g
   WHERE g.guest_id = NEW.guest_id;

  -- craft a message
  v_message := FORMAT(
    'Your booking #%s at room %s has been created with status "%s".',
    NEW.booking_id,
    NEW.room_id,
    NEW.status
  );

  -- insert into notifications
  INSERT INTO notifications (user_id, message)
  VALUES (v_user_id, v_message);

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_after_booking_insert ON bookings;
CREATE TRIGGER trg_after_booking_insert
  AFTER INSERT ON bookings
  FOR EACH ROW
  EXECUTE FUNCTION trg_notify_booking_creation();


-- 2) Notify guest on booking cancellation

CREATE OR REPLACE FUNCTION trg_notify_booking_cancellation()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v_user_id INT;
  v_message TEXT;
BEGIN
  -- only fire when status flips to 'cancelled'
  IF TG_OP = 'UPDATE'
     AND OLD.status <> 'cancelled'
     AND NEW.status = 'cancelled'
  THEN
    -- guest user
    SELECT g.user_id INTO v_user_id
      FROM guest g
     WHERE g.guest_id = NEW.guest_id;

    -- Remove status_reason from message
    v_message := FORMAT(
      'Your booking #%s has been cancelled',
      NEW.booking_id
    );

    INSERT INTO notifications (user_id, message)
    VALUES (v_user_id, v_message);
  END IF;

  RETURN NEW;
END;
$$;

-- Keep the trigger creation unchanged
CREATE TRIGGER trg_after_booking_update_notify
  AFTER UPDATE OF status ON bookings
  FOR EACH ROW
  EXECUTE FUNCTION trg_notify_booking_cancellation();
-- ──────── HELPER FUNCTIONS ─────────

-- A) look up guest_id from user_id
CREATE OR REPLACE FUNCTION fn_get_guest_id(p_user_id INT)
RETURNS INT LANGUAGE sql AS $$
  SELECT guest_id FROM guest WHERE user_id = p_user_id;
$$;

-- B) upcoming stays by user_id
CREATE OR REPLACE FUNCTION fn_guest_upcoming(p_user_id INT)
RETURNS TABLE(
  booking_id       INT,
  user_id          INT,
  check_in_date    DATE,
  check_out_date   DATE,
  total_price      NUMERIC,
  status           TEXT,
  room_number      INT,
  hotel_name       TEXT,
  payment_status   TEXT
) LANGUAGE sql AS $$
  SELECT * 
    FROM v_guest_upcoming_travels
   WHERE user_id = p_user_id;
$$;

-- C) past stays by user_id
CREATE OR REPLACE FUNCTION fn_guest_past(p_user_id INT)
RETURNS TABLE(
  booking_id       INT,
  user_id          INT,
  check_in_date    DATE,
  check_out_date   DATE,
  total_price      NUMERIC,
  status           TEXT,
  room_number      INT,
  hotel_name       TEXT,
  payment_status   TEXT
) LANGUAGE sql AS $$
  SELECT *
    FROM v_guest_travel_history
   WHERE user_id = p_user_id;
$$;

-- D) cancellations by user_id
CREATE OR REPLACE FUNCTION fn_guest_cancellations(p_user_id INT)
RETURNS TABLE(
  cancellation_id   INT,
  user_id           INT,
  booking_id        INT,
  cancellation_date DATE,
  cancellation_reason TEXT,
  refund_amount     NUMERIC,
  room_number       INT,
  hotel_name        TEXT
) LANGUAGE sql AS $$
  SELECT *
    FROM v_guest_cancellation_history
   WHERE user_id = p_user_id;
$$;


CREATE OR REPLACE FUNCTION fn_get_room_details(p_room_id INT)
RETURNS TABLE (
  room_id        INT,
  room_number    INT,
  price          NUMERIC,
  capacity       INT,
  images         TEXT[],
  updated_at     TIMESTAMP,
  room_type      TEXT,
  hotel_id       INT,
  hotel_name     TEXT,
  address        TEXT,
  city           TEXT,
  state          TEXT,
  hotel_phone    TEXT,
  hotel_email    TEXT,
  avg_rating     NUMERIC,
  amenities      TEXT[]
)
LANGUAGE sql AS $$
SELECT
  r.room_id,
  r.room_number,
  r.price,
  r.capacity,
  r.images,
  r.updated_at,
  r.room_type,
  h.hotel_id,
  h.name          AS hotel_name,
  h.address,
  h.city,
  h.state,
  h.phone_number  AS hotel_phone,
  h.email         AS hotel_email,
  COALESCE((
    SELECT AVG(rv.rating)
      FROM review rv
     WHERE rv.hotel_id = h.hotel_id
  ), 0.0)           AS avg_rating,
  COALESCE((
    SELECT array_agg(a.name)
      FROM hotel_amenity ha
      JOIN amenities a ON ha.amenity_id = a.amenity_id
     WHERE ha.hotel_id = h.hotel_id
  ), ARRAY[]::TEXT[]) AS amenities
FROM rooms r
JOIN hotel h ON r.hotel_id = h.hotel_id
WHERE r.room_id = p_room_id;
$$;

--TRIGGERS

-- A) When a booking’s status flips to 'cancelled', run cancel_booking(...)
CREATE OR REPLACE FUNCTION trg_booking_cancel_cleanup()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'UPDATE'
     AND OLD.status <> 'cancelled'
     AND NEW.status = 'cancelled'
  THEN
    PERFORM cancel_booking(NEW.booking_id, 'Cancelled via app');
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_on_booking_update ON bookings;
CREATE TRIGGER trg_on_booking_update
  AFTER UPDATE OF status ON bookings
  FOR EACH ROW
  EXECUTE FUNCTION trg_booking_cancel_cleanup();


-- B) When a payment_details row is inserted, mark its booking confirmed
CREATE OR REPLACE FUNCTION trg_payment_confirm_booking()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  UPDATE bookings
     SET status = 'confirmed'
   WHERE booking_id = NEW.booking_id;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_on_payment_insert ON payment_details;
CREATE TRIGGER trg_on_payment_insert
  AFTER INSERT ON payment_details
  FOR EACH ROW
  EXECUTE FUNCTION trg_payment_confirm_booking();

---HOST


-- 1) Helper: cancel all bookings for a given room_id
CREATE OR REPLACE FUNCTION cancel_bookings_by_room(
    p_room_id  INTEGER,
    p_reason   TEXT
) RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN
      SELECT booking_id
        FROM bookings
       WHERE room_id = p_room_id
         AND status   <> 'cancelled'
    LOOP
      -- your existing cancel_booking() will update status,
      -- insert into cancellation, and delete the review
      PERFORM cancel_booking(rec.booking_id, p_reason);
    END LOOP;
END;
$$;


-- 2) Trigger function: before deleting a room, clean up its bookings
CREATE OR REPLACE FUNCTION before_delete_room_cleanup()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    -- 2a) cancel & log all bookings for this room
    PERFORM cancel_bookings_by_room(OLD.room_id, 'Room deleted');

    -- 2b) detach any remaining bookings so the FK check passes
    UPDATE bookings
       SET room_id = NULL
     WHERE room_id = OLD.room_id;

    -- now Postgres can delete the room row itself
    RETURN OLD;
END;
$$;


-- 3) Attach the trigger to rooms
DROP TRIGGER IF EXISTS trg_before_room_delete ON rooms;
CREATE TRIGGER trg_before_room_delete
  BEFORE DELETE ON rooms
  FOR EACH ROW
  EXECUTE FUNCTION before_delete_room_cleanup();


-- in pgAdmin (or psql), run once:

CREATE OR REPLACE VIEW v_rooms_with_booking_counts AS
SELECT
  r.room_id,
  r.hotel_id,
  r.room_number,
  r.price,
  r.capacity,
  r.images,
  r.updated_at,
  r.room_type,
  COALESCE(bc.total_bookings, 0) AS total_bookings
FROM rooms r
LEFT JOIN (
  SELECT room_id, COUNT(*) AS total_bookings
    FROM bookings
   GROUP BY room_id
) bc ON r.room_id = bc.room_id;

----------

----INDEXING:


--Query Example:
SELECT user_id, password_hashed, role FROM users WHERE user_name = %s;
--Creation Command:
CREATE INDEX idx_users_username ON users(user_name);



--Query Example:
SELECT user_id FROM users WHERE email = %s;
CREATE INDEX idx_users_email ON users(email);


--Query Example:
EXPLAIN ANALYZE SELECT * FROM discounts WHERE valid_until >= CURRENT_DATE ORDER BY valid_until DESC;
CREATE INDEX idx_discounts_valid_until ON discounts(valid_until DESC);


--Query Example:
SELECT * FROM v_recent_bookings ORDER BY booking_date DESC;
CREATE INDEX idx_bookings_booking_date ON bookings(booking_date DESC);


--Query Example:
SELECT discount_amount FROM discounts WHERE promo_code = %s AND valid_until >= CURRENT_DATE;
CREATE INDEX idx_discounts_promo_code ON discounts(promo_code);


--Query Example:
SELECT * FROM bookings WHERE guest_id = %s AND check_in_date > CURRENT_DATE ORDER BY check_in_date;
CREATE INDEX idx_bookings_guest_checkin ON bookings(guest_id, check_in_date);



--Query Example:
EXPLAIN ANALYZE SELECT NOT EXISTS (
  SELECT 1 FROM bookings
  WHERE room_id =4
  AND check_in_date < '30-04-2025'
  AND check_out_date > '01-05-2025'
);
CREATE INDEX idx_bookings_room_dates ON bookings(room_id, check_in_date, check_out_date);



--Query Example:
SELECT pd.* FROM payment_details pd
JOIN bookings b ON pd.booking_id = b.booking_id
WHERE b.guest_id = %s
ORDER BY pd.payment_date DESC;
CREATE INDEX idx_payment_details_date ON payment_details(payment_date DESC);

--Query Example:
explain analyze  SELECT h.* FROM hotel h
JOIN host ho ON h.host_id = ho.host_id
WHERE ho.user_id = 4;
CREATE INDEX idx_host_user_id ON host(user_id);


--Query Example:
INSERT INTO review ( rating, comment, review_date, booking_id, guest_id, hotel_id,booking_id)
VALUES
( 4.0, 'Very comfortable', '2025-04-13 10:00:00', 2, 2, 1,5);

CREATE INDEX idx_review_booking_id ON review(booking_id);


--Query Example:
SELECT AVG(rating) FROM review WHERE hotel_id = %s;
CREATE INDEX idx_review_hotel_id ON review(hotel_id);



-----
----ROLES

-- Create roles
CREATE ROLE guest;
ALTER ROLE guest WITH PASSWORD 'guest';
CREATE ROLE host;
CREATE ROLE admin;


-- Grant privileges to `hotel_app` user
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO hotel_app;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO hotel_app;


-- Tables/Views
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin;

-- Sequences
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin;

-- Functions/Procedures
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO admin;

-- Extensions (e.g., pgcrypto)
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA pgcrypto TO admin;
-- For future tables/views
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
GRANT ALL PRIVILEGES ON TABLES TO admin;

-- For future sequences
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
GRANT ALL PRIVILEGES ON SEQUENCES TO admin;

-- For future functions
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
GRANT EXECUTE ON FUNCTIONS TO admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON hotel, rooms TO admin;

-- For pgcrypto functions like gen_random_uuid(), crypt(), etc.
GRANT USAGE ON SCHEMA pgcrypto TO admin;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA pgcrypto TO admin;

-- Grant privileges to `host`
GRANT SELECT, INSERT, UPDATE, DELETE ON hotel, rooms TO host;
GRANT USAGE, SELECT ON SEQUENCE hotel_hotel_id_seq, rooms_room_id_seq TO host;

-- Grant privileges to `guest`
GRANT SELECT ON hotel, rooms TO guest;
GRANT SELECT, INSERT, UPDATE ON bookings, payment_details TO guest;
GRANT USAGE, SELECT ON SEQUENCE bookings_booking_id_seq, payment_details_payment_id_seq TO guest;
GRANT INSERT ON login_attempts To guest;
-- Verify privileges for `host`
SELECT table_name, privilege_type 
FROM information_schema.table_privileges 
WHERE grantee = 'host';


---
set role hotel_app;
set role admin;
set role guest;
set role host;
select current_user;
set role hotel_app;
INSERT INTO rooms(room_number,price,capacity,hotel_id)
VALUES
( 13, 350.00, 3, 2);

SELECT * from hotel;
