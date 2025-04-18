-- Users table stores details of all users, including guests and hosts
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
	Role text
);

SELECT * FROM users;
-- Enable pgcrypto extension (only required once)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Insert user data with hashed passwords
INSERT INTO users (user_id, user_name, password_hashed, first_name, last_name, address, phone_number, age, email, created_at, Role)
VALUES 
(1, 'user1', crypt('password1', gen_salt('bf')), 'John', 'Doe', '123 Main St, Cityville', '111-222-3333', 28, 'user1@example.com', '2025-03-01 08:00:00', 'guest'),
(2, 'user2', crypt('password2', gen_salt('bf')), 'Alice', 'Smith', '456 Oak Ave, Townsville', '222-333-4444', 32, 'user2@example.com', '2025-03-01 08:05:00', 'host'),
(3, 'user3', crypt('password3', gen_salt('bf')), 'Mike', 'Brown', '789 Pine Rd, Villageton', '333-444-5555', 45, 'user3@example.com', '2025-03-01 08:10:00', 'guest'),
(4, 'user4', crypt('password4', gen_salt('bf')), 'Sarah', 'Lee', '101 Maple Blvd, Hamlet', '444-555-6666', 27, 'user4@example.com', '2025-03-01 08:15:00', 'host'),
(5, 'user5', crypt('password5', gen_salt('bf')), 'David', 'Wilson', '202 Birch St, Metro City', '555-666-7777', 36, 'user5@example.com', '2025-03-01 08:20:00', 'guest'),
(6, 'user6', crypt('password6', gen_salt('bf')), 'Emma', 'Johnson', '303 Cedar Dr, Uptown', '666-777-8888', 29, 'user6@example.com', '2025-03-01 08:25:00', 'guest'),
(7, 'user7', crypt('password7', gen_salt('bf')), 'Liam', 'Williams', '404 Spruce Ln, Downtown', '777-888-9999', 40, 'user7@example.com', '2025-03-01 08:30:00', 'guest'),
(8, 'user8', crypt('password8', gen_salt('bf')), 'Olivia', 'Jones', '505 Elm St, Suburbia', '888-999-0000', 33, 'user8@example.com', '2025-03-01 08:35:00', 'host'),
(9, 'user9', crypt('password9', gen_salt('bf')), 'Noah', 'Davis', '606 Walnut Ave, Oldtown', '999-000-1111', 22, 'user9@example.com', '2025-03-01 08:40:00', 'guest'),
(10, 'user10', crypt('password10', gen_salt('bf')), 'Ava', 'Martin', '707 Chestnut Rd, Riverside', '000-111-2222', 31, 'user10@example.com', '2025-03-01 08:45:00', 'guest');

-- Guests table stores users who book hotels

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
DROP TABLE Bookings;
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

INSERT INTO bookings (check_in_date, check_out_date, total_price, status, booking_date, payment_id, room_id, guest_id)
VALUES
  ('2025-04-01', '2025-04-05', 600.00, 'confirmed', '2025-03-01 12:00:00', 1, 1, 1),
  ('2025-04-06', '2025-04-09', 450.00, 'confirmed', '2025-03-02 10:30:00', 2, 2, 2),
  ('2025-04-10', '2025-04-15', 750.00, 'pending',   '2025-03-03 11:15:00', 3, 4, 3),
  ('2025-04-16', '2025-04-20', 500.00, 'confirmed', '2025-03-04 09:45:00', 4, 5, 4),
  ('2025-04-21', '2025-04-25', 800.00, 'confirmed', '2025-03-05 14:30:00', 5, 7, 5),
  ('2025-04-26', '2025-04-30', 650.00, 'pending',   '2025-03-06 15:00:00', 6, 8, 6),
  ('2025-05-01', '2025-05-05', 550.00, 'confirmed', '2025-03-07 08:30:00', 7, 3, 7),
  ('2025-05-06', '2025-05-10', 720.00, 'confirmed', '2025-03-08 11:00:00', 8, 6, 1),
  ('2025-05-11', '2025-05-15', 830.00, 'pending',   '2025-03-09 09:15:00', 9, 9, 2),
  ('2025-05-16', '2025-05-20', 910.00, 'confirmed', '2025-03-10 10:00:00', 10, 10, 3);


CREATE TABLE Payment_Details (
    payment_id SERIAL PRIMARY KEY NOT NULL,
    payment_date DATE ,
    mode_of_payment VARCHAR(50),
    payment_amount NUMERIC(10, 2) NOT NULL,
    payment_status VARCHAR(20)
);
INSERT INTO Payment_Details (payment_date, mode_of_payment, payment_amount, payment_status)
VALUES
  ('2025-03-01', 'Credit Card', 600.00, 'confirmed'),
  ('2025-03-02', 'Debit Card', 340.00, 'confirmed'),
  ('2025-03-03', 'PayPal', 700.00, 'pending'),
  ('2025-03-04', 'Credit Card', 450.00, 'confirmed'),
  ('2025-03-05', 'Debit Card', 800.00, 'confirmed'),
  ('2025-03-06', 'PayPal', 380.00, 'pending'),
  ('2025-03-07', 'Credit Card', 500.00, 'confirmed'),
  ('2025-03-08', 'Debit Card', 750.00, 'confirmed'),
  ('2025-03-09', 'Credit Card', 900.00, 'pending'),
  ('2025-03-10', 'PayPal', 950.00, 'confirmed');



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

-- Discounts table stores discount details and promo codes

CREATE TABLE Discounts(
    discount_id SERIAL PRIMARY KEY NOT NULL,
    Promo_code VARCHAR(50) NOT NULL,
    discount_amount NUMERIC(10, 2) NOT NULL,
    valid_from DATE NOT NULL,
    valid_until DATE NOT NULL,
    description TEXT,
    booking_id INTEGER REFERENCES bookings(booking_id)
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

-- Hotel images table stores URLs of images for each hotel

CREATE TABLE hotel_images (
    image_id SERIAL PRIMARY KEY NOT NULL,
    hotel_id INTEGER REFERENCES hotel(hotel_id) ON DELETE CASCADE,
    image_url TEXT NOT NULL
);
SELECT * FROM hotel_images;

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

--Inserting values into hotel

INSERT INTO hotel(hotel_id, host_id, name, address, city, state, phone_number, email, total_rooms, zip_code, rating)
VALUES 
(1, 1, 'Grand Plaza', '100 Luxury Ave', 'Metropolis', 'State1', '111-222-3333', 'grandplaza@example.com', 120, 12345, 4.5),
(2, 2, 'Sunrise Inn', '200 Ocean Dr', 'Beachside', 'State2', '222-333-4444', 'sunriseinn@example.com', 80, 23456, 4.2),
(3, 3, 'Mountain Retreat', '300 Alpine Rd', 'Highland', 'State3', '333-444-5555', 'mountainretreat@example.com', 50, 34567, 4.8);
INSERT INTO hotel(hotel_id, host_id, name, address, city, state, phone_number, email, total_rooms, zip_code, rating)
VALUES
(4, 3, 'Taj', '300 Alpine Rd', 'Highland', 'State3', '333-444-5555', 'taj@example.com', 50, 34567, 3.8);


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

INSERT INTO cancellation (cancellation_id, booking_id, Cancellation_date, cancellation_reason, Refund_amount)
VALUES
(1, 21, '2025-03-10', 'Plans changed', 340.00),
(2, 23, '2025-03-11', 'Double booked', 700.00),
(3, 24, '2025-03-12', 'Emergency cancellation', 450.00),
(4, 30, '2025-03-13', 'Customer request', 380.00);

--Inserting values into review

INSERT INTO review (review_id, rating, comment, review_date, booking_id, guest_id, hotel_id)
VALUES
(1, 4.5, 'Great stay at Grand Plaza', '2025-04-06 08:00:00', 21, 1, 1),
(2, 4.0, 'Very comfortable', '2025-04-13 10:00:00', 22, 2, 1),
(3, 3.5, 'Good service but room was small', '2025-05-11 09:00:00', 23, 3, 2),
(4, 5.0, 'Excellent experience!', '2025-05-19 12:00:00', 24, 4, 2),
(5, 4.8, 'Loved the mountain view', '2025-06-06 07:30:00', 25, 5, 3),
(6, 3.8, 'Decent stay', '2025-06-13 11:15:00', 26, 6, 3),
(7, 4.2, 'Room was clean and spacious', '2025-07-05 10:20:00', 27, 7, 1),
(8, 4.0, 'Pleasant experience overall', '2025-07-16 14:10:00', 28, 1, 2),
(9, 3.0, 'Average service', '2025-08-11 09:45:00', 29, 3, 3),
(10, 4.7, 'Will visit again!', '2025-08-21 08:50:00', 30, 5, 3);

--Inserting values into discounts


INSERT INTO discounts (discount_id, Promo_code, discount_amount, valid_from, valid_until, description, booking_id)
VALUES
(1, 'DISCOUNT10', 10.00, '2025-04-01', '2025-04-30', 'Spring discount', 21),
(2, 'SUMMER15', 15.00, '2025-06-01', '2025-06-30', 'Summer special', 22),
(3, 'WINTER20', 20.00, '2025-12-01', '2025-12-31', 'Winter sale', 23),
(4, 'FLASH5', 5.00, '2025-03-15', '2025-03-20', 'Flash deal', 24),
(5, 'NEWYEAR25', 25.00, '2026-01-01', '2026-01-31', 'New Year offer', 25),
(6, 'VIP30', 30.00, '2025-05-01', '2025-05-31', 'VIP discount', 26),
(7, 'EARLYBIRD10', 10.00, '2025-07-01', '2025-07-15', 'Early bird offer', 27),
(8, 'LASTMIN20', 20.00, '2025-08-01', '2025-08-10', 'Last minute deal', 28),
(9, 'EXCLUSIVE15', 15.00, '2025-09-01', '2025-09-30', 'Exclusive offer', 29),
(10, 'SEASONAL5', 5.00, '2025-10-01', '2025-10-31', 'Seasonal discount', 30);

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

--Inserting values into hotel_images

INSERT INTO hotel_images (image_id, hotel_id, image_url)
VALUES
(1, 1, 'http://example.com/images/hotel1_img1.jpg'),
(2, 1, 'http://example.com/images/hotel1_img2.jpg'),
(3, 2, 'http://example.com/images/hotel2_img1.jpg'),
(4, 2, 'http://example.com/images/hotel2_img2.jpg'),
(5, 3, 'http://example.com/images/hotel3_img1.jpg'),
(6, 3, 'http://example.com/images/hotel3_img2.jpg'),
(7, 1, 'http://example.com/images/hotel1_img3.jpg'),
(8, 2, 'http://example.com/images/hotel2_img3.jpg'),
(9, 3, 'http://example.com/images/hotel3_img3.jpg'),
(10, 2, 'http://example.com/images/hotel2_img4.jpg');



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
    price DECIMAL,
    capacity INTEGER,
    hotel_rating DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT r.room_id,CAST(h.name AS TEXT) AS hotel_name, r.room_number, r.price, r.capacity, h.rating
    FROM rooms r
    JOIN hotel h ON r.hotel_id = h.hotel_id
    WHERE h.city = p_city
    AND r.price BETWEEN p_min_price AND p_max_price
    AND r.capacity >= p_min_capacity
    AND h.rating >= p_min_rating
    AND( p_check_in_date IS NULL OR p_check_out_date IS NULL 
			OR  r.room_id NOT IN (
        SELECT b.room_id FROM bookings b
        WHERE b.status NOT IN ('cancelled')
        AND (p_check_in_date < check_out_date AND p_check_out_date > check_in_date)
		)
    )
    ORDER BY r.price ASC; -- Default sorting (modify if needed)
END;
$$ LANGUAGE plpgsql;


select * from get_available_rooms_by_location('Highland',NULL,NULL,0,1000,3);




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
CREATE OR REPLACE FUNCTION register_user(
    p_username VARCHAR,
    p_password VARCHAR,
    p_first_name VARCHAR,
    p_last_name VARCHAR,
    p_address TEXT DEFAULT NULL,
    p_phone_number VARCHAR(20) DEFAULT NULL,
    p_age INTEGER DEFAULT NULL,
    p_email VARCHAR(255) DEFAULT NULL,
    p_role TEXT DEFAULT 'guest'
) RETURNS TEXT AS $$
DECLARE
    v_exists BOOLEAN;
    v_email_exists BOOLEAN;
BEGIN
    -- Check if username already exists
    SELECT EXISTS (SELECT 1 FROM users WHERE user_name = p_username) INTO v_exists;
    IF v_exists THEN
        RETURN 'Error: Username already exists';
    END IF;

    -- Check if email already exists (if email is provided)
    IF p_email IS NOT NULL THEN
        SELECT EXISTS (SELECT 1 FROM users WHERE email = p_email) INTO v_email_exists;
        IF v_email_exists THEN
            RETURN 'Error: Email already exists';
        END IF;
    END IF;

    -- Insert user with all fields
    BEGIN
        INSERT INTO users (
            user_name, password_hashed, first_name, last_name, address,
            phone_number, age, email, role
        ) VALUES (
            p_username, crypt(p_password, gen_salt('bf')), p_first_name,
            p_last_name, p_address, p_phone_number, p_age, p_email, p_role
        );

        RETURN 'Success: User registered';
    EXCEPTION
        WHEN unique_violation THEN
            RETURN 'Error: Duplicate entry detected';
        WHEN others THEN
            RETURN 'Error: Registration failed due to an unexpected issue';
    END;
END;
$$ LANGUAGE plpgsql;