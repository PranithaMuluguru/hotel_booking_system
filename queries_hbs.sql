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
	status room_status DEFAULT 'available',
	hotel_id INTEGER REFERENCES hotel(hotel_id),
	UNIQUE(hotel_id,room_number)
	
);

SELECT * FROM rooms;

-- Amenities table stores various room amenities

CREATE TABLE Amenities(
	amenity_id SERIAL PRIMARY KEY NOT NULL,
	name TEXT,
	description TEXT
);

SELECT * FROM amenities;










-- Room_amenity table links rooms with available amenities

CREATE TABLE room_amenity(
	room_id INTEGER NOT NULL REFERENCES Rooms(room_id),
	amenity_id INTEGER NOT NULL REFERENCES Amenities(amenity_id),
	PRIMARY KEY (room_id, amenity_id)
);

SELECT * FROM room_amenity;







CREATE TYPE booking_status AS ENUM ('pending', 'confirmed', 'cancelled');

-- Bookings table stores hotel booking details

CREATE TABLE bookings(
	booking_id SERIAL PRIMARY KEY NOT NULL,
	check_in_date DATE NOT NULL,
	check_out_date DATE NOT NULL,
	total_price DECIMAL,
	status booking_status DEFAULT 'pending',
	booking_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	room_id INTEGER REFERENCES Rooms(room_id),
	hotel_id INTEGER REFERENCES hotel(hotel_id),
	guest_id INTEGER REFERENCES guest(guest_id) ON DELETE CASCADE
);
--- constraint to check in date is less than out date.
ALTER TABLE bookings
ADD CONSTRAINT check_dates 
CHECK (check_out_date >= check_in_date);

SELECT * FROM bookings;






----to ensure a person can book multiple rooms this table is created
CREATE TABLE booking_rooms (
    booking_id INTEGER REFERENCES bookings(booking_id) ON DELETE CASCADE,
    room_id INTEGER REFERENCES Rooms(room_id) ON DELETE CASCADE,
    PRIMARY KEY (booking_id, room_id)
);

INSERT INTO booking_rooms (booking_id, room_id) VALUES
(1, 1), -- Booking 101 includes Room 201
(2, 2), -- Booking 101 includes Room 202 (same hotel)
(3, 4), -- Booking 102 includes Room 203
(4, 5), -- Booking 103 includes Room 201 (another booking for same room)
(5, 7); -- Booking 103 includes Room 202

SELECT * FROM booking_rooms;








CREATE TYPE payment_status AS ENUM ('pending', 'confirmed', 'cancelled');

-- Payments table stores payment transactions for bookings

CREATE TABLE Payments(
	payment_id SERIAL PRIMARY KEY NOT NULL,
	payment_date DATE NOT NULL,
	amount DECIMAL NOT  NULL,
	payment_method TEXT ,
	transaction_id VARCHAR(100) UNIQUE,
	status payment_status DEFAULT 'pending', 
	booking_id INTEGER REFERENCES bookings(booking_id) ON DELETE CASCADE,
	guest_id INTEGER REFERENCES guest(guest_id) ON DELETE CASCADE
);
SELECT * FROM payments;


-- Review table stores user reviews for hotels

CREATE TABLE Review(
	review_id SERIAL PRIMARY KEY NOT NULL,
	rating DECIMAL  NOT NULL,
	comment text,
	review_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	booking_id INTEGER REFERENCES Bookings(booking_id),
	guest_id INTEGER REFERENCES guest(guest_id),
	hotel_id INTEGER REFERENCES hotel(hotel_id)

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

-- INSERT INTO hotel (hotel_id, host_id, name, address, city, state, phone_number, email, total_rooms, zip_code, rating)
-- VALUES
-- (4, 4, 'Hotel Sunbeam', 'Sector 22B', 'Chandigarh', 'Punjab', '+91-172-2704011', 'sunbeamchd@example.com', 75, 160022, 4.0),
-- (5, 5, 'The Park', '14/7, MG Road', 'Bangalore', 'Karnataka', '+91-80-25594666', 'theparkblr@example.com', 200, 560001, 4.2),
-- (6, 6, 'Hotel City Star', '8718 D.B. Gupta Road', 'New Delhi', 'Delhi', '+91-11-43532828', 'citystardelhi@example.com', 100, 110055, 4.1),
-- (7, 7, 'Hotel Shalimar', 'Near Railway Station', 'Jaipur', 'Rajasthan', '+91-141-2378855', 'shalimarjaipur@example.com', 150, 302006, 4.0),
-- (8, 8, 'The Presidency', '1471/A, Nayapalli', 'Bhubaneswar', 'Odisha', '+91-674-2560801', 'presidencybbsr@example.com', 120, 751015, 4.1),
-- (9, 9, 'Hotel Abad Plaza', 'MG Road', 'Kochi', 'Kerala', '+91-484-2381122', 'abadplaza@example.com', 180, 682035, 4.0),
-- (10, 10, 'Hotel Hindustan International', 'A.J.C Bose Road', 'Kolkata', 'West Bengal', '+91-33-22802123', 'hhi_kolkata@example.com', 250, 700017, 4.2);
-- INSERT INTO hotel (hotel_id, host_id, name, address, city, state, phone_number, email, total_rooms, zip_code, rating)
-- VALUES
-- (11, 11, 'Hotel Marine Plaza', '29, Marine Drive', 'Mumbai', 'Maharashtra', '+91-22-22851212', 'marineplaza@example.com', 80, 400020, 4.3),
-- (12, 12, 'Hotel Suba Palace', 'Apollo Bunder, Colaba', 'Mumbai', 'Maharashtra', '+91-22-22846256', 'subapalace@example.com', 75, 400001, 4.0),
-- (13, 13, 'Hotel Royal Orchid', '1, Golf Avenue', 'Bangalore', 'Karnataka', '+91-80-41783000', 'royalorchid@example.com', 195, 560008, 4.2),
-- (14, 14, 'Hotel Iris', '70 Brigade Road', 'Bangalore', 'Karnataka', '+91-80-25585858', 'irisblr@example.com', 50, 560001, 4.1),
-- (15, 15, 'Hotel Ajanta', '36, Arakashan Road', 'New Delhi', 'Delhi', '+91-11-23585511', 'ajantadelhi@example.com', 90, 110055, 3.0),
-- (16, 16, 'The Hans Hotel', '15, Barakhamba Road', 'New Delhi', 'Delhi', '+91-11-23316899', 'hansdelhi@example.com', 75, 110001, 4.1),
-- (17, 17, 'Hotel Golden Tulip', 'Opp. GPO, M.I. Road', 'Jaipur', 'Rajasthan', '+91-141-4268777', 'goldentulipjaipur@example.com', 110, 302001, 3.0),
-- (18, 18, 'Hotel Arya Niwas', 'Sansar Chandra Road', 'Jaipur', 'Rajasthan', '+91-141-2372456', 'aryaniwas@example.com', 100, 302001, 4.1),
-- (19, 19, 'The Peerless Inn', '12, Jawaharlal Nehru Road', 'Kolkata', 'West Bengal', '+91-33-44002222', 'peerlesskolkata@example.com', 168, 700013, 2.2),
-- (20, 20, 'Lytton Hotel', '14, Sudder Street', 'Kolkata', 'West Bengal', '+91-33-22493371', 'lyttonkolkata@example.com', 80, 700016, 4.0);

INSERT INTO rooms(room_id,room_number,price,capacity,status,hotel_id)
VALUES
(1, 101, 150.00, 2, 'available', 1),
(2, 102, 170.00, 2, 'available', 1),
(3, 103, 200.00, 3, 'unavailable', 1),
(4, 201, 120.00, 2, 'available', 2),
(5, 101, 130.00, 2, 'available', 2),
(6, 203, 140.00, 2, 'available', 2),
(7, 301, 180.00, 3, 'available', 3),
(8, 302, 190.00, 3, 'available', 3),
(9, 303, 210.00, 4, 'unavailable', 3),
(10, 304, 220.00, 4, 'available', 3);
INSERT INTO rooms(room_id,room_number,price,capacity,status,hotel_id)
VALUES
(11, 101, 520.00, 3, 'available', 4),
(12, 102, 320.00, 4, 'available', 4);


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

INSERT INTO room_amenity (room_id, amenity_id)
VALUES 
(1,1),
(1,2),
(2,1),
(2,4),
(3,3),
(4,1),
(4,6),
(5,2),
(6,7),
(7,1);

--Inserting values into bookings

INSERT INTO bookings (booking_id, check_in_date, check_out_date, total_price, status, booking_date, room_id, hotel_id, guest_id)
VALUES
(1, '2025-04-01', '2025-04-05', 600.00, 'confirmed', '2025-03-01 12:00:00', 1, 1, 1),
(2, '2025-04-10', '2025-04-12', 340.00, 'confirmed', '2025-03-01 13:00:00', 2, 1, 2),
(3, '2025-05-05', '2025-05-10', 700.00, 'pending', '2025-03-02 09:00:00', 4, 2, 3),
(4, '2025-05-15', '2025-05-18', 450.00, 'confirmed', '2025-03-02 10:00:00', 5, 2, 4),
(5, '2025-06-01', '2025-06-05', 800.00, 'confirmed', '2025-03-03 11:00:00', 7, 3, 5),
(6, '2025-06-10', '2025-06-12', 380.00, 'pending', '2025-03-03 12:00:00', 8, 3, 6),
(7, '2025-07-01', '2025-07-04', 500.00, 'confirmed', '2025-03-04 08:00:00', 3, 1, 7),
(8, '2025-07-10', '2025-07-15', 750.00, 'confirmed', '2025-03-04 09:00:00', 6, 2, 1),
(9, '2025-08-05', '2025-08-10', 900.00, 'pending', '2025-03-05 14:00:00', 9, 3, 3),
(10, '2025-08-15', '2025-08-20', 950.00, 'confirmed', '2025-03-05 15:00:00', 10, 3, 5);

--Inserting values into payments

INSERT INTO payments (payment_id, payment_date, amount, payment_method, transaction_id, status, booking_id, guest_id)
VALUES
(1, '2025-03-01', 600.00, 'Credit Card', 'TXN001', 'confirmed', 1, 1),
(2, '2025-03-01', 340.00, 'Debit Card', 'TXN002', 'confirmed', 2, 2),
(3, '2025-03-02', 700.00, 'PayPal', 'TXN003', 'pending', 3, 3),
(4, '2025-03-02', 450.00, 'Credit Card', 'TXN004', 'confirmed', 4, 4),
(5, '2025-03-03', 800.00, 'Debit Card', 'TXN005', 'confirmed', 5, 5),
(6, '2025-03-03', 380.00, 'PayPal', 'TXN006', 'pending', 6, 6),
(7, '2025-03-04', 500.00, 'Credit Card', 'TXN007', 'confirmed', 7, 7),
(8, '2025-03-04', 750.00, 'Debit Card', 'TXN008', 'confirmed', 8, 1),
(9, '2025-03-05', 900.00, 'Credit Card', 'TXN009', 'pending', 9, 3),
(10, '2025-03-05', 950.00, 'PayPal', 'TXN010', 'confirmed', 10, 5);


--Inserting values into cancellation

INSERT INTO cancellation (cancellation_id, booking_id, Cancellation_date, cancellation_reason, Refund_amount)
VALUES
(1, 2, '2025-03-10', 'Plans changed', 340.00),
(2, 3, '2025-03-11', 'Double booked', 700.00),
(3, 4, '2025-03-12', 'Emergency cancellation', 450.00),
(4, 6, '2025-03-13', 'Customer request', 380.00),
(5, 8, '2025-03-14', 'Travel restrictions', 750.00),
(6, 9, '2025-03-15', 'Weather issues', 900.00),
(7, 10, '2025-03-16', 'Found better option', 950.00),
(8, 1, '2025-03-17', 'Change of plans', 600.00),
(9, 5, '2025-03-18', 'Service issues', 800.00),
(10, 7, '2025-03-19', 'Schedule conflict', 500.00);


--Inserting values into review

INSERT INTO review (review_id, rating, comment, review_date, booking_id, guest_id, hotel_id)
VALUES
(1, 4.5, 'Great stay at Grand Plaza', '2025-04-06 08:00:00', 1, 1, 1),
(2, 4.0, 'Very comfortable', '2025-04-13 10:00:00', 2, 2, 1),
(3, 3.5, 'Good service but room was small', '2025-05-11 09:00:00', 3, 3, 2),
(4, 5.0, 'Excellent experience!', '2025-05-19 12:00:00', 4, 4, 2),
(5, 4.8, 'Loved the mountain view', '2025-06-06 07:30:00', 5, 5, 3),
(6, 3.8, 'Decent stay', '2025-06-13 11:15:00', 6, 6, 3),
(7, 4.2, 'Room was clean and spacious', '2025-07-05 10:20:00', 7, 7, 1),
(8, 4.0, 'Pleasant experience overall', '2025-07-16 14:10:00', 8, 1, 2),
(9, 3.0, 'Average service', '2025-08-11 09:45:00', 9, 3, 3),
(10, 4.7, 'Will visit again!', '2025-08-21 08:50:00', 10, 5, 3);

--Inserting values into discounts


INSERT INTO discounts (discount_id, Promo_code, discount_amount, valid_from, valid_until, description, booking_id)
VALUES
(1, 'DISCOUNT10', 10.00, '2025-04-01', '2025-04-30', 'Spring discount', 1),
(2, 'SUMMER15', 15.00, '2025-06-01', '2025-06-30', 'Summer special', 2),
(3, 'WINTER20', 20.00, '2025-12-01', '2025-12-31', 'Winter sale', 3),
(4, 'FLASH5', 5.00, '2025-03-15', '2025-03-20', 'Flash deal', 4),
(5, 'NEWYEAR25', 25.00, '2026-01-01', '2026-01-31', 'New Year offer', 5),
(6, 'VIP30', 30.00, '2025-05-01', '2025-05-31', 'VIP discount', 6),
(7, 'EARLYBIRD10', 10.00, '2025-07-01', '2025-07-15', 'Early bird offer', 7),
(8, 'LASTMIN20', 20.00, '2025-08-01', '2025-08-10', 'Last minute deal', 8),
(9, 'EXCLUSIVE15', 15.00, '2025-09-01', '2025-09-30', 'Exclusive offer', 9),
(10, 'SEASONAL5', 5.00, '2025-10-01', '2025-10-31', 'Seasonal discount', 10);

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


-- FUNCTIONS 


CREATE OR REPLACE FUNCTION get_average_rating(hotel_id INTEGER)
RETURNS DECIMAL AS $$
DECLARE
    avg_rating DECIMAL;
BEGIN
    SELECT AVG(hotel.rating) INTO avg_rating
    FROM Review
    JOIN bookings ON review.booking_id = bookings.booking_id 
    JOIN rooms ON rooms.room_id = bookings.room_id
    JOIN hotel ON hotel.hotel_id = rooms.hotel_id
    WHERE hotel.hotel_id = get_average_rating.hotel_id;

    RETURN COALESCE(avg_rating, 0);
END;
$$ LANGUAGE plpgsql;

select get_average_rating(3);





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

















-- SELECT * FROM get_average_rating;











