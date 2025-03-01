-- Users table stores details of all users, including guests and hosts

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

SELECT * FROM bookings;



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



