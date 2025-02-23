DROP TABLE Users;
DROP TABLE Hotels;
DROP TABLE Rooms;
DROP TABLE Users;
CREATE TABLE Users(
	user_id SERIAL PRIMARY KEY NOT NULL,
	name VARCHAR(255) UNIQUE NOT NULL,
	password VARCHAR(255) NOT NULL,
	first_name VARCHAR(225) NOT NULL,
	last_name VARCHAR(225) NOT NULL,
	address TEXT,
	phone_number VARCHAR(20),
	age INTEGER,
	Email VARCHAR(255) UNIQUE,
	Role text
);
select * from USERS;

DROP TABLE Hotels;
CREATE TABLE Hotels(
	hotel_id SERIAL PRIMARY KEY NOT NULL,
	name VARCHAR(255) UNIQUE NOT NULL,
	address TEXT,
	city TEXT,
	state TEXT,
	zip_code INTEGER,
	rating DECIMAL
);

SELECT * FROM Hotels;
CREATE TYPE room_status AS ENUM ('unavailable', 'available');

CREATE TABLE Rooms(
	room_id SERIAL PRIMARY KEY NOT NULL,
	room_number INTEGER UNIQUE NOT NULL,
	price_per_night DECIMAL,
	status room_status DEFAULT 'available',
	hotel_id INTEGER REFERENCES Users(user_id)
);

SELECT * FROM Rooms;
CREATE TABLE Amenities(
	amenity_id SERIAL PRIMARY KEY NOT NULL,
	name TEXT,
	descriptiion TEXT
);
SELECT * FROM Amenities;

CREATE TABLE room_amenity(
	-- room_id INTEGER NOT NULL,
 --    amenity_id INTEGER NOT NULL,
	-- PRIMARY KEY (room_id, amenity_id),
	room_id INTEGER REFERENCES Rooms(room_id),
	amenity_id INTEGER REFERENCES Amenities(amenity_id)
);
SELECT * FROM room_amenity;


CREATE TABLE Review(
	review_id SERIAL PRIMARY KEY NOT NULL,
	rating DECIMAL  NOT NULL,
	comment text,
	review_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	booking_id INTEGER REFERENCES Bookings(booking_id)
);
SELECT * FROM Review;


CREATE TYPE booking_status AS ENUM ('pending', 'confirmed', 'cancelled', 'completed');

CREATE TABLE Bookings(
	booking_id SERIAL PRIMARY KEY NOT NULL,
	check_in_date DATE,
	check_out_date DATE,
	total_price DECIMAL,
	status booking_status DEFAULT 'pending',
	booking_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	room_id INTEGER REFERENCES Rooms(room_id),
	user_id INTEGER REFERENCES Users(user_id)
);
SELECT * FROM Bookings;

CREATE TYPE payment_status AS ENUM ('pending', 'confirmed', 'cancelled', 'completed');

CREATE TABLE Payments(
	payment_id SERIAL PRIMARY KEY NOT NULL,
	payment_date DATE,
	amount DECIMAL,
	payment_method TEXT,
	status payment_status DEFAULT 'pending', 
	booking_id INTEGER REFERENCES Bookings(booking_id)
);

SELECT * FROM Payments;



