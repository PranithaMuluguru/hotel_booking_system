from flask import Flask, render_template, request, redirect, url_for, session, flash
import psycopg2
from psycopg2 import sql
from datetime import datetime

app = Flask(__name__)
app.secret_key = 'your-secret-key-123'

# Database configuration
DB_CONFIG = {
    'dbname': 'Hotel',
    'user': 'hotel_app',        # Custom user
    'password': 'strong_password',    # strong_password
    'host': 'localhost',        # Or remote IP
    'port': '5432'
}

def get_db_connection():
    return psycopg2.connect(**DB_CONFIG)

# Routes
@app.route('/')
def index():
    return render_template('index.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        try:
            conn = get_db_connection()
            cur = conn.cursor()
            cur.execute(
                "SELECT user_id, role FROM users WHERE user_name = %s AND password_hashed = crypt(%s, password_hashed)",
                (request.form['username'], request.form['password'])
            )
            user = cur.fetchone()
            if user:
                session['user_id'] = user[0]
                session['role'] = user[1]
                return redirect(url_for('dashboard'))
            flash('Invalid credentials', 'danger')
        except Exception as e:
            flash(str(e), 'danger')
        finally:
            cur.close()
            conn.close()
    return render_template('login.html')

@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        try:
            conn = get_db_connection()
            cur = conn.cursor()
            cur.execute(
                "SELECT register_user(%s, %s, %s, %s, %s, %s, %s, %s, %s)",
                (
                    request.form['username'],
                    request.form['password'],
                    request.form['first_name'],
                    request.form['last_name'],
                    request.form.get('address'),
                    request.form.get('phone'),
                    request.form.get('age'),
                    request.form.get('email'),
                    'guest'  # Default role
                )
            )
            result = cur.fetchone()[0]
            conn.commit()
            if 'Success' in result:
                flash('Registration successful! Please login', 'success')
                return redirect(url_for('login'))
            flash(result, 'danger')
        except Exception as e:
            flash(str(e), 'danger')
        finally:
            cur.close()
            conn.close()
    return render_template('register.html')

@app.route('/dashboard')
def dashboard():
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    role = session.get('role')
    if role == 'guest':
        return guest_dashboard()
    elif role == 'host':
        return host_dashboard()
    return redirect(url_for('index'))

def guest_dashboard():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT * FROM get_user_booking_history(%s)", (session['user_id'],))
        bookings = cur.fetchall()
        return render_template('guest_dashboard.html', bookings=bookings)
    except Exception as e:
        flash(str(e), 'danger')
        return redirect(url_for('index'))
    finally:
        cur.close()
        conn.close()

def host_dashboard():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("""
            SELECT h.*, COUNT(b.booking_id) as total_bookings 
            FROM hotel h
            LEFT JOIN rooms r ON h.hotel_id = r.hotel_id
            LEFT JOIN bookings b ON r.room_id = b.room_id
            WHERE h.host_id = (SELECT host_id FROM host WHERE user_id = %s)
            GROUP BY h.hotel_id
            """, (session['user_id'],))
        hotels = cur.fetchall()
        return render_template('host_dashboard.html', hotels=hotels)
    except Exception as e:
        flash(str(e), 'danger')
        return redirect(url_for('index'))
    finally:
        cur.close()
        conn.close()

@app.route('/search', methods=['GET', 'POST'])
def search():
    if request.method == 'POST':
        try:
            conn = get_db_connection()
            cur = conn.cursor()
            cur.execute(
                "SELECT * FROM get_available_rooms_by_location(%s, %s, %s, %s, %s, %s, %s)",
                (
                    request.form['city'],
                    request.form.get('check_in'),
                    request.form.get('check_out'),
                    request.form.get('min_price', 0),
                    request.form.get('max_price', 1000),
                    request.form.get('min_capacity', 1),
                    request.form.get('min_rating', 0)
                )
            )
            results = cur.fetchall()
            return render_template('search_results.html', results=results)
        except Exception as e:
            flash(str(e), 'danger')
            return redirect(url_for('search'))
        finally:
            cur.close()
            conn.close()
    return render_template('search.html')

@app.route('/book/<int:room_id>', methods=['GET', 'POST'])
def book(room_id):
    if 'user_id' not in session or session['role'] != 'guest':
        return redirect(url_for('login'))
    
    if request.method == 'POST':
        try:
            conn = get_db_connection()
            cur = conn.cursor()
            
            # Check availability
            cur.execute("SELECT can_book_room(%s, %s, %s)", 
                        (room_id, request.form['check_in'], request.form['check_out']))
            available = cur.fetchone()[0]
            
            if available:
                # Create booking
                cur.execute("""
                    INSERT INTO bookings 
                    (guest_id, room_id, check_in_date, check_out_date, status)
                    VALUES (%s, %s, %s, %s, 'confirmed')
                    RETURNING booking_id
                    """, 
                    (session['user_id'], room_id, 
                     request.form['check_in'], request.form['check_out']))
                booking_id = cur.fetchone()[0]
                
                # Create payment
                cur.execute("""
                    INSERT INTO payment_details 
                    (payment_amount, payment_status)
                    VALUES (%s, 'completed')
                    RETURNING payment_id
                    """, (request.form['total_price'],))
                payment_id = cur.fetchone()[0]
                
                # Update booking with payment
                cur.execute("""
                    UPDATE bookings SET payment_id = %s
                    WHERE booking_id = %s
                    """, (payment_id, booking_id))
                
                conn.commit()
                flash('Booking successful!', 'success')
                return redirect(url_for('guest_dashboard'))
            else:
                flash('Room no longer available', 'danger')
        except Exception as e:
            conn.rollback()
            flash(str(e), 'danger')
        finally:
            cur.close()
            conn.close()
    
    # GET request - show booking form
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("""
            SELECT r.*, h.name, h.address, h.rating 
            FROM rooms r
            JOIN hotel h ON r.hotel_id = h.hotel_id
            WHERE r.room_id = %s
            """, (room_id,))
        room = cur.fetchone()
        return render_template('booking.html', room=room)
    except Exception as e:
        flash(str(e), 'danger')
        return redirect(url_for('search'))
    finally:
        cur.close()
        conn.close()
@app.template_filter('format_date')
def format_date(value):
    if value is None:
        return ""
    return value.strftime('%b %d, %Y')

@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('index'))

if __name__ == '__main__':
    app.run(debug=True)
