from flask import Flask, render_template, request, redirect, url_for, session, flash
import psycopg2
from psycopg2.extras import RealDictCursor
import os
import json
from datetime import datetime, timedelta,date
from decimal import Decimal , InvalidOperation 
import re
app = Flask(__name__)
app.secret_key = os.environ.get('SECRET_KEY', 'dev_secret_key')
from flask import g
from flask_login import LoginManager, current_user, login_required
import os
from werkzeug.utils import secure_filename
# In your Flask app configuration
app.config['UPLOAD_FOLDER'] = 'static/uploads'
app.config['GMAPS_API_KEY'] = 'YOUR_GOOGLE_STATIC_MAPS_KEY'

app.config['ROOM_IMAGE_SUBFOLDER'] = 'rooms'
app.config['ALLOWED_EXTENSIONS'] = {'png', 'jpg', 'jpeg', 'gif'}
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB

# Helper function for file validation
def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in app.config['ALLOWED_EXTENSIONS']
@app.before_request
def load_current_user():
    g.user = current_user
# Database configuration
DB_CONFIG = {
    'dbname': 'Hotel',
    'user': 'hotel_app',
    'password': 'strong_password',
    'host': 'localhost',
    'port': '5432'
}

def get_db_connection():
    """Create and return a database connection and cursor"""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cur = conn.cursor(cursor_factory=RealDictCursor)
        return conn, cur
    except Exception as e:
        print(f"Database connection error: {e}")
        return None, None

def close_db_connection(conn, cur):
    """Close database connection and cursor"""
    if cur:
        cur.close()
    if conn:
        conn.close()

@app.route('/')
def index():
    return render_template('index.html')
from functools import wraps

def admin_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if session.get('role') != 'admin':
            flash('Unauthorized access!', 'danger')
            return redirect(url_for('index'))
        return f(*args, **kwargs)
    return decorated_function

def host_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if session.get('role') != 'host':
            flash('Unauthorized access!', 'danger')
            return redirect(url_for('index'))
        return f(*args, **kwargs)
    return decorated_function

def guest_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if session.get('role') != 'guest':
            flash('Unauthorized access!', 'danger')
            return redirect(url_for('index'))
        return f(*args, **kwargs)
    return decorated_function
@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username'].strip().lower()
        password = request.form['password']
        conn, cur = get_db_connection()
        login_success = False
        user_id = None
        role = None
        try:
            # Check if username exists
            cur.execute("SELECT user_id, password_hashed, role FROM users WHERE user_name = %s", (username,))
            user = cur.fetchone()
            if user:
                user_id = user['user_id']
                stored_password = user['password_hashed']
                role = user['role']
                if password == stored_password:
                    login_success = True
                    session['user_id'] = user_id
                    session['role'] = role
                    flash('Login successful!', 'success')
                else:
                    flash('Invalid password', 'danger')
            else:
                flash('Username not found', 'danger')
            
            # Log the attempt
            cur.execute(
                "INSERT INTO Login_Attempts (user_id, login_success) VALUES (%s, %s)",
                (user_id, login_success)
            )
            conn.commit()
            
            if login_success:
                return redirect(url_for('dashboard'))
            else:
                return redirect(url_for('login'))
        except Exception as e:
            if conn: conn.rollback()
            flash(f'Login error: {str(e)}', 'danger')
            return redirect(url_for('login'))
        finally:
            close_db_connection(conn, cur)
    return render_template('login.html')

@app.route('/register', methods=['GET', 'POST'])
def register():
    conn, cur = get_db_connection()
    try:
        if request.method == 'POST':
            # Input sanitization
            username         = request.form['username'].strip().lower()
            hashed_password  = request.form['password']           # renamed, no hashing
            first_name       = request.form['first_name'].strip()
            last_name        = request.form['last_name'].strip()
            address          = request.form.get('address')
            phone            = request.form.get('phone')
            age              = request.form.get('age', type=int)
            email            = request.form.get('email', '').strip().lower() or None
            role             = 'host' if request.form.get('role') == 'host' else 'guest'

            # Check for existing user/email
            cur.execute("""
                SELECT user_id
                  FROM users
                 WHERE user_name = %s
                    OR email     = %s
            """, (username, email))
            if cur.fetchone():
                flash('Username or email already exists!', 'danger')
                return redirect(url_for('register'))

            # Insert new user, returning the new user_id
            cur.execute("""
                INSERT INTO users (
                    user_name, password_hashed,
                    first_name, last_name,
                    address, age, email,
                    role, phone_number
                ) VALUES (
                    %s, %s,
                    %s, %s,
                    %s, %s, %s,
                    %s, %s
                )
                RETURNING user_id;
            """, (
                username, hashed_password,
                first_name, last_name,
                address, age, email,
                role, phone
            ))
            new_user_id = cur.fetchone()['user_id']

            # Create guest/host record
            if role == 'host':
                cur.execute("INSERT INTO host (user_id)  VALUES (%s)", (new_user_id,))
            else:
                cur.execute("INSERT INTO guest (user_id) VALUES (%s)", (new_user_id,))

            conn.commit()
            flash('Registration successful! Please login', 'success')
            return redirect(url_for('login'))

        return render_template('register.html')

    except Exception as e:
        if conn:
            conn.rollback()
        flash(f'Registration error: {e}', 'danger')
        return render_template('register.html')

    finally:
        close_db_connection(conn, cur)

@app.route('/dashboard')
def dashboard():
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    try:
        if session['role'] == 'guest':
            return guest_dashboard()
        elif session['role'] == 'host':
            return host_dashboard()
        elif session['role'] == 'admin':
            return admin_dashboard()
        return redirect(url_for('index'))
    except Exception as e:
        flash(f'Dashboard error: {str(e)}', 'danger')
        return redirect(url_for('index'))
@app.route('/admin/dashboard', methods=['GET', 'POST'])

def admin_dashboard():
    if session.get('role') != 'admin':
        return redirect(url_for('login'))

    conn, cur = get_db_connection()
    stats = {}
    recent_bookings = []
    recent_users = []
    discounts = []
    selectable_users = []  # Initialize here
    recent_login_attempts = []

    try:
        # Handle discount creation
        if request.method == 'POST':
            promo_code = request.form['promo_code'].strip().upper()
            description = request.form['description'].strip()
            discount_amount = float(request.form['discount_amount'])
            valid_from = request.form['valid_from']
            valid_until = request.form['valid_until']

            # Validate dates
            if valid_from > valid_until:
                flash('Valid Until date must be after Valid From date', 'danger')
                return redirect(url_for('admin_dashboard'))

            # Check for duplicate promo code
            cur.execute("SELECT promo_code FROM discounts WHERE promo_code = %s", (promo_code,))
            if cur.fetchone():
                flash('Promo code already exists', 'danger')
                return redirect(url_for('admin_dashboard'))

            # Insert new discount
            cur.execute("""
                INSERT INTO discounts 
                (promo_code, description, discount_amount, valid_from, valid_until)
                VALUES (%s, %s, %s, %s, %s)
            """, (promo_code, description, discount_amount, valid_from, valid_until))
            conn.commit()
            flash('Discount created successfully', 'success')

        cur.execute("""
            SELECT * FROM discounts 
            WHERE valid_until >= CURRENT_DATE
            ORDER BY valid_until DESC
        """)
        discounts = cur.fetchall()

        # Get system statistics
        cur.execute("SELECT * FROM v_system_stats;")
        stats = cur.fetchone()

        # Get recent bookings
        cur.execute("SELECT * FROM v_recent_bookings;")
        recent_bookings = cur.fetchall()

        # Get recent users
        cur.execute("""
            SELECT user_id, user_name, email, created_at, role 
            FROM users 
            ORDER BY created_at DESC LIMIT 10
        """)
        recent_users = cur.fetchall()

        # Get selectable users (MANDATORY FOR NOTIFICATION FORM)
        cur.execute("""
            SELECT user_id, user_name, email
            FROM users
            WHERE role != 'admin'
            ORDER BY user_name ASC
        """)
        selectable_users = cur.fetchall()  # This was missing

        # Get login attempts
        cur.execute("""
            SELECT la.*, u.user_name 
            FROM Login_Attempts la
            LEFT JOIN users u ON la.user_id = u.user_id
            ORDER BY la.login_time DESC
            LIMIT 10
        """)
        recent_login_attempts = cur.fetchall()

    except Exception as e:
        flash(f'Error fetching admin data: {str(e)}', 'danger')
    finally:
        close_db_connection(conn, cur)
    
    return render_template('admin_dashboard.html', 
                         stats=stats,
                         recent_bookings=recent_bookings,
                         recent_users=recent_users,
                         selectable_users=selectable_users,  # Ensure this is passed
                         recent_login_attempts=recent_login_attempts,
                         discounts=discounts)
# Add other admin routes
@app.route('/admin/users')

def manage_users():
    conn, cur = get_db_connection()
    users = []
    try:
        cur.execute("SELECT * FROM users ORDER BY created_at DESC")
        users = cur.fetchall()
    except Exception as e:
        flash(f'Error fetching users: {str(e)}', 'danger')
    finally:
        close_db_connection(conn, cur)
    
    return render_template('manage_users.html', users=users)

# Admin - Manage All Hotels
@app.route('/admin/hotels')

def manage_hotels():
    conn, cur = get_db_connection()
    hotels = []
    try:
        cur.execute("""
            SELECT 
    h.hotel_id, 
    h.name, 
    h.address, 
    h.city, 
    h.state, 
    h.phone_number, 
    h.email, 
    COUNT(r.room_id) AS total_rooms, -- Count rooms for each hotel
    u.user_name AS host_username
FROM hotel h
LEFT JOIN rooms r ON h.hotel_id = r.hotel_id -- Join with rooms table
JOIN host ho ON h.host_id = ho.host_id 
JOIN users u ON ho.user_id = u.user_id 
GROUP BY h.hotel_id, u.user_name -- Group by hotel and host information
ORDER BY h.hotel_id DESC;
        """)
        hotels = cur.fetchall()
    except Exception as e:
        flash(f'Error fetching hotels: {str(e)}', 'danger')
    finally:
        close_db_connection(conn, cur)
    return render_template('admin_hotels.html', hotels=hotels)
@app.route('/admin/bookings')

def manage_bookings():
    conn, cur = get_db_connection()
    bookings = []
    try:
        cur.execute("""
            SELECT
                b.booking_id,
                u.user_name,                      -- Fetched from users table via guest table
                h.name AS hotel_name,             -- Fetched from hotel table via rooms table
                r.room_number,                    -- Fetched from rooms table
                b.check_in_date AS check_in,      -- Renamed for template convenience
                b.check_out_date AS check_out,    -- Renamed for template convenience
                b.status,                         -- From bookings table
                COALESCE(pd.payment_status, 'pending') AS payment_status, -- Fetched from payment_details, handle missing payments
                b.total_price                     -- From bookings table
            FROM
                bookings b
            JOIN                                -- Join bookings with rooms
                rooms r ON b.room_id = r.room_id
            JOIN                                -- Join rooms with hotel
                hotel h ON r.hotel_id = h.hotel_id
            JOIN                                -- Join bookings with guest
                guest g ON b.guest_id = g.guest_id
            JOIN                                -- Join guest with users
                users u ON g.user_id = u.user_id
            LEFT JOIN                           -- Use LEFT JOIN for payments in case a booking doesn't have a payment yet
                payment_details pd ON b.booking_id = pd.booking_id
            ORDER BY                            -- Optional: Order the results
                b.booking_id DESC;
        """)
        bookings = cur.fetchall()
        print(bookings)  # Debugging: Check console output
    except Exception as e:
        flash(f'Error fetching bookings: {str(e)}', 'danger')
    finally:
        close_db_connection(conn, cur)
    
    return render_template('manage_bookings.html', bookings=bookings)
@app.route('/admin/hotel/delete/<int:hotel_id>', methods=['POST'])

def admin_delete_hotel(hotel_id):
    # 0) Only admins may hit this route
    if session.get('role') != 'admin':
        flash('Access denied', 'danger')
        return redirect(url_for('login'))

    conn, cur = get_db_connection()
    try:
        # 1) Ensure the hotel exists
        cur.execute(
            "SELECT 1 FROM hotel WHERE hotel_id = %s",
            (hotel_id,)
        )
        if not cur.fetchone():
            flash('Hotel not found', 'warning')
            return redirect(url_for('manage_hotels'))

        # 2) Delete the hotel row.
        #    The BEFORE DELETE trigger in Postgres will automatically:
        #      • cancel & log all related bookings
        #      • delete associated reviews
        #      • remove hotel_amenity links
        #      • delete the hotel’s rooms
        cur.execute(
            "DELETE FROM hotel WHERE hotel_id = %s",
            (hotel_id,)
        )
        conn.commit()

        flash(
            'Hotel deleted; bookings cancelled & logged, '
            'amenities and rooms removed.',
            'success'
        )

    except Exception as e:
        conn.rollback()
        flash(f'Error deleting hotel: {e}', 'danger')

    finally:
        close_db_connection(conn, cur)

    return redirect(url_for('manage_hotels'))
@app.route('/admin/send_notification', methods=['POST'])
def send_notification():
    if session.get('role') != 'admin':
        flash('Unauthorized!', 'danger')
        return redirect(url_for('login'))
    
    message = request.form.get('message')
    selected_user_ids_str = request.form.getlist('user_ids')  # Ensure correct name attribute
    
    # Convert to integers
    try:
        user_ids = [int(uid) for uid in selected_user_ids_str]
    except ValueError:
        flash('Invalid user IDs', 'danger')
        return redirect(url_for('admin_dashboard'))
    
    conn, cur = None, None
    try:
        conn, cur = get_db_connection()
        # Validate users exist and are not admins
        cur.execute("""
            SELECT user_id FROM users 
            WHERE user_id = ANY(%s) AND role != 'admin'
        """, (user_ids,))
        valid_users = [row['user_id'] for row in cur.fetchall()]
        
        if not valid_users:
            flash('No valid users selected', 'warning')
            return redirect(url_for('admin_dashboard'))
        
        # Insert notifications
        insert_data = [(uid, message) for uid in valid_users]
        cur.executemany("""
            INSERT INTO notifications (user_id, message)
            VALUES (%s, %s)
        """, insert_data)
        conn.commit()
        flash(f'Notifications sent to {len(valid_users)} users!', 'success')
    except Exception as e:
        if conn: conn.rollback()
        flash(f'Error: {str(e)}', 'danger')
        app.logger.error(f"Notification error: {str(e)}")
    finally:
        close_db_connection(conn, cur)
    
    return redirect(url_for('admin_dashboard'))
@app.route('/admin/user/delete/<int:user_id>', methods=['POST'])

def admin_delete_user(user_id):
    # Prevent admin from deleting themselves
    if user_id == session.get('user_id'):
        flash('You cannot delete your own account.', 'danger')
        return redirect(url_for('manage_users'))

    conn, cur = None, None
    try:
        conn, cur = get_db_connection()
        if not conn: return redirect(url_for('manage_users'))

        # Check if the user exists and is not an admin (optional: prevent deleting other admins)
        cur.execute("SELECT role FROM users WHERE user_id = %s", (user_id,))
        user_to_delete = cur.fetchone()

        if not user_to_delete:
            flash('User not found.', 'danger')
            return redirect(url_for('manage_users'))

        # Optional: Add check to prevent deleting other admins if desired
        # if user_to_delete['role'] == 'admin':
        #     flash('Cannot delete another admin account.', 'danger')
        #     return redirect(url_for('manage_users'))

        # Delete the user.
        # IMPORTANT: Assumes your database schema uses ON DELETE CASCADE for foreign keys
        # referencing users.user_id (in guest, host, bookings, notifications etc.)
        # If not, you need to manually delete related records first.
        cur.execute("DELETE FROM users WHERE user_id = %s", (user_id,))
        conn.commit()
        flash(f'User ID {user_id} deleted successfully.', 'success')
        app.logger.info(f"Admin {session.get('username')} deleted user ID {user_id}")

    except psycopg2.Error as db_err:
        conn.rollback()
        flash(f'Database error deleting user: {db_err}', 'danger')
        app.logger.error(f"Admin Delete User DB Error (user_id={user_id}): {db_err}")
    except Exception as e:
        if conn: conn.rollback() # Rollback on any exception
        flash(f'Error deleting user: {str(e)}', 'danger')
        app.logger.error(f"Admin Delete User Error (user_id={user_id}): {e}")
    finally:
        close_db_connection(conn, cur)

    return redirect(url_for('manage_users'))
@app.route('/admin/user/add', methods=['GET', 'POST'])

def admin_add_user():
    conn, cur = None, None
    try:
        conn, cur = get_db_connection()
        if not conn:
             # If GET, show form with error, if POST, redirect back to avoid losing POST context
             if request.method == 'GET':
                 return render_template('admin_add_user.html')
             else:
                 return redirect(url_for('manage_users')) # Or back to add form

        if request.method == 'POST':
            # Extract form data
            username = request.form.get('username', '').strip().lower()
            password = request.form.get('password', '') # Add validation! HASH THIS!
            first_name = request.form.get('first_name', '').strip()
            last_name = request.form.get('last_name', '').strip()
            role = request.form.get('role') # Make sure this matches ('guest', 'host', 'admin')
            email = request.form.get('email', '').strip().lower() or None
            phone = request.form.get('phone', '').strip() or None
            address = request.form.get('address', '').strip() or None
            age_str = request.form.get('age', '').strip()

            # --- Validation ---
            errors = []
            if not username: errors.append("Username is required.")
            if not password: errors.append("Password is required.") # Add length/complexity checks
            if not first_name: errors.append("First name is required.")
            if not last_name: errors.append("Last name is required.")
            if role not in ['guest', 'host', 'admin']: errors.append("Invalid role selected.")
            if email and '@' not in email: errors.append("Invalid email format.")
            age = None
            if age_str:
                try:
                    age = int(age_str)
                    if age <= 0: errors.append("Age must be a positive number.")
                except ValueError:
                    errors.append("Age must be a valid number.")

            if errors:
                for error in errors: flash(error, 'danger')
                # Return form with entered data
                return render_template('admin_add_user.html', form_data=request.form)

            # Validate existing user (Username OR Email if provided)
            check_query = "SELECT user_id FROM users WHERE user_name = %s"
            params = [username]
            if email:
                check_query += " OR email = %s"
                params.append(email)
            cur.execute(check_query, tuple(params))

            if cur.fetchone():
                flash('Username or email already exists!', 'danger')
                return render_template('admin_add_user.html', form_data=request.form)

            # --- Insert User (HASH THE PASSWORD!) ---
            cur.execute("""
                INSERT INTO users (
                    user_name, password_hashed,
                    first_name, last_name,
                    address, age, email,
                    role, phone_number
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING user_id
            """, (username, password, first_name, last_name, address, age, email, role, phone))
            new_user_id = cur.fetchone()['user_id']

            # --- Create guest/host profile IF needed ---
            if role == 'host':
                cur.execute("INSERT INTO host (user_id) VALUES (%s)", (new_user_id,))
                app.logger.info(f"Admin created host record for new user_id {new_user_id}")
            elif role == 'guest':
                cur.execute("INSERT INTO guest (user_id) VALUES (%s)", (new_user_id,))
                app.logger.info(f"Admin created guest record for new user_id {new_user_id}")
            # No separate table needed for 'admin' role assumed

            conn.commit()
            flash(f'User "{username}" added successfully with role "{role}".', 'success')
            app.logger.info(f"Admin {session.get('username')} added user '{username}' (ID: {new_user_id}) with role '{role}'.")
            return redirect(url_for('manage_users'))

        # --- GET Request ---
        # Show the form template
        return render_template('admin_add_user.html')

    except psycopg2.Error as db_err:
        if conn: conn.rollback()
        flash(f'Database error adding user: {db_err}', 'danger')
        app.logger.error(f"Admin Add User DB Error: {db_err}")
        return render_template('admin_add_user.html', form_data=request.form if request.method == 'POST' else {})
    except Exception as e:
        if conn: conn.rollback()
        flash(f'Error adding user: {str(e)}', 'danger')
        app.logger.error(f"Admin Add User Error: {e}")
        return render_template('admin_add_user.html', form_data=request.form if request.method == 'POST' else {})
    finally:
        close_db_connection(conn, cur)
@app.route('/admin/hotel/add', methods=['GET', 'POST'])

def admin_add_hotel():
    conn, cur = None, None
    hosts = [] # Initialize hosts list
    try:
        conn, cur = get_db_connection()
        if not conn:
            flash("Database connection failed, cannot load hosts.", "danger")
            # Decide how to handle this - show form without hosts or redirect?
            return render_template('admin_add_hotel.html', hosts=[], form_data=request.form if request.method == 'POST' else {})


        # --- Fetch existing hosts for the dropdown ---
        # This needs to happen for both GET and POST (in case of POST errors)
        try:
             cur.execute("""
                SELECT h.host_id, u.user_name, u.first_name, u.last_name
                FROM host h
                JOIN users u ON h.user_id = u.user_id
                WHERE u.role = 'host' -- Ensure we only get actual hosts
                ORDER BY u.user_name ASC
            """)
             hosts = cur.fetchall()
        except psycopg2.Error as db_err:
             flash(f"Error fetching hosts list: {db_err}", "warning")
             app.logger.error(f"Admin Add Hotel - Fetch Hosts DB Error: {db_err}")
             # Proceed with empty hosts list, form might be unusable

        # --- Handle POST request (form submission) ---
        if request.method == 'POST':
            # Get form data
            name = request.form.get('name', '').strip()
            address = request.form.get('address', '').strip()
            city = request.form.get('city', '').strip()
            state = request.form.get('state', '').strip()
            zip_code = request.form.get('zip_code', '').strip() or None
            phone = request.form.get('phone', '').strip() or None
            email = request.form.get('email', '').strip().lower() or None
            total_rooms_str = request.form.get('total_rooms', '').strip()
            host_id_str = request.form.get('host_id', '').strip() # Get host_id from form dropdown

            # --- Validation ---
            errors = []
            if not name: errors.append("Hotel name is required.")
            if not address: errors.append("Address is required.")
            if not city: errors.append("City is required.")
            if not state: errors.append("State is required.")
            if not host_id_str: errors.append("A host must be selected.")

            host_id = None
            if host_id_str:
                try:
                    host_id = int(host_id_str)
                except ValueError:
                    errors.append("Invalid Host ID format.")

            total_rooms = None
            if total_rooms_str:
                try:
                    total_rooms = int(total_rooms_str)
                    if total_rooms < 0: errors.append("Total rooms cannot be negative.")
                except ValueError:
                    errors.append("Total rooms must be a valid number.")
            else:
                errors.append("Total rooms is required.") # Or default to 0?

            if email and '@' not in email: errors.append("Invalid email format.")
            # Add more validation (zip code format, phone format, state format etc.)

            # --- Validate Selected Host ID ---
            if host_id:
                # Check if the selected host_id actually exists in the fetched list
                # This is safer than querying the DB again here, but querying is also an option
                valid_host_selected = any(h['host_id'] == host_id for h in hosts)
                if not valid_host_selected:
                    errors.append('Invalid host selected. Please choose from the list.')

            if errors:
                for error in errors: flash(error, 'danger')
                # Return form with entered data and the hosts list
                return render_template('admin_add_hotel.html', hosts=hosts, form_data=request.form)

            # --- Insert hotel ---
            try:
                cur.execute("""
                    INSERT INTO hotel (
                        host_id, name, address, city, state, zip_code,
                        phone_number, email, total_rooms
                    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                    RETURNING hotel_id
                """, (host_id, name, address, city, state, zip_code, phone, email, total_rooms))
                new_hotel_id = cur.fetchone()['hotel_id']
                conn.commit()
                flash(f'Hotel "{name}" added successfully!', 'success')
                app.logger.info(f"Admin {session.get('username')} added hotel '{name}' (ID: {new_hotel_id}) linked to host_id {host_id}.")
                return redirect(url_for('manage_hotels'))

            except psycopg2.Error as db_err:
                 conn.rollback() # Rollback on insertion error
                 flash(f"Database error adding hotel: {db_err}", "danger")
                 app.logger.error(f"Admin Add Hotel - Insert DB Error: {db_err}")
                 # Show form again with data
                 return render_template('admin_add_hotel.html', hosts=hosts, form_data=request.form)

        # --- GET Request ---
        # Render the form, passing the list of hosts
        return render_template('admin_add_hotel.html', hosts=hosts)

    except Exception as e:
        # Catch any other unexpected errors
        if conn and not conn.closed and conn.status != psycopg2.extensions.STATUS_IN_TRANSACTION:
             # Only rollback if connection is valid and not already in error state
             try:
                 conn.rollback()
             except psycopg2.Error as rb_err:
                 app.logger.error(f"Rollback failed in admin_add_hotel: {rb_err}")
        flash(f'An unexpected error occurred: {str(e)}', 'danger')
        app.logger.error(f"Admin Add Hotel Error: {e}", exc_info=True) # Log stack trace
        # Decide where to redirect on generic error
        return redirect(url_for('admin_dashboard')) # Redirect to dashboard on major error
    finally:
        close_db_connection(conn, cur)

@app.route('/guest/dashboard')
def guest_dashboard():
    if 'user_id' not in session or session.get('role') != 'guest':
        flash('Please log in as a guest.', 'warning')
        return redirect(url_for('login'))

    conn, cur = get_db_connection()
    try:
        uid = session['user_id']

        # 1) Upcoming stays
        cur.execute("SELECT * FROM fn_guest_upcoming(%s)", (uid,))
        upcoming = cur.fetchall()

        # 2) Past stays
        cur.execute("SELECT * FROM fn_guest_past(%s)", (uid,))
        past = cur.fetchall()

        # 3) Cancellations
        cur.execute("SELECT * FROM fn_guest_cancellations(%s)", (uid,))
        cancellations = cur.fetchall()

        # (Optionally pull user name)
        cur.execute("SELECT first_name, last_name FROM users WHERE user_id = %s", (uid,))
        user = cur.fetchone()

    except Exception as e:
        flash(f"Error loading dashboard: {e}", 'danger')
        upcoming = past = cancellations = []
        user = None
    finally:
        close_db_connection(conn, cur)

    return render_template(
        'guest_dashboard.html',
        upcoming=upcoming,
        past=past,
        cancellations=cancellations,
        user=user,
        today_date=date.today()
    )

from flask import flash, redirect, render_template, url_for
from datetime import date

@app.route('/room_details/<int:room_id>')
def room_details(room_id):
    conn, cur = get_db_connection()
    try:
        # call the SQL function
        cur.execute("SELECT * FROM fn_get_room_details(%s)", (room_id,))
        rec = cur.fetchone()

        if not rec:
            flash('Room not found.', 'danger')
            return redirect(url_for('search'))

        # rec is a dict-like with keys matching the RETURNS TABLE cols
        amenities = rec['amenities'] or []
        today_date = date.today().strftime('%Y-%m-%d')

        return render_template(
            'room_details.html',
            room=rec,
            amenities=amenities,
            today_date=today_date,
            format_date=format_date
        )

    except Exception as e:
        flash(f'Error loading room details: {e}', 'danger')
        return redirect(url_for('search'))

    finally:
        close_db_connection(conn, cur)

# Constant for cancellation status (ensure this matches your DB value exactly)
BOOKING_STATUS_CANCELLED = 'cancelled' # Case-sensitive if stored that way in DB

@app.template_global()
def calculate_refund(total_price, check_in_date):
    """
    Always refund the entire booking amount.
    """
    try:
        # Ensure it's a Decimal
        return Decimal(total_price).quantize(Decimal("0.01"))
    except:
        return Decimal("0.00")

@app.route('/booking/<int:booking_id>/cancel', methods=['POST'])
def cancel_booking_route(booking_id):
    if 'user_id' not in session:
        flash('Please log in to manage bookings.', 'warning')
        return redirect(url_for('login'))

    conn, cur = get_db_connection()
    try:
        # Optional: verify this booking belongs to this guest
        cur.execute("""
            SELECT b.booking_id
              FROM bookings b
              JOIN guest g ON b.guest_id = g.guest_id
             WHERE b.booking_id = %s
               AND g.user_id = %s
        """, (booking_id, session['user_id']))
        if not cur.fetchone():
            flash('Booking not found or unauthorized.', 'danger')
            return redirect(url_for('guest_dashboard'))

        # flip status; trigger will call cancel_booking(...)
        cur.execute(
            "UPDATE bookings SET status = 'cancelled' WHERE booking_id = %s",
            (booking_id,)
        )
        conn.commit()

        flash(f'Booking #{booking_id} cancelled.', 'success')
    except Exception as e:
        conn.rollback()
        flash(f'Cancellation failed: {e}', 'danger')
    finally:
        close_db_connection(conn, cur)

    return redirect(url_for('guest_dashboard'))


@app.route('/payment', methods=['GET', 'POST'])
def payment():
    if 'user_id' not in session or session.get('role') != 'guest':
        flash('Please log in as a guest.', 'warning')
        return redirect(url_for('login'))

    booking = session.get('booking_details')
    if not booking:
        flash('Booking info missing. Please start again.', 'danger')
        return redirect(url_for('search'))

    if request.method == 'POST':
        # validate form fields…
        for f in ('payment_method','card_number','card_name','expiry','cvv'):
            if not request.form.get(f):
                flash(f'Missing: {f.replace("_"," ").title()}', 'danger')
                return redirect(url_for('payment'))

        card = request.form['card_number'].replace(' ','')
        if not (card.isdigit() and len(card)==16):
            flash('Card must be 16 digits.', 'danger')
            return redirect(url_for('payment'))
        if not re.match(r'^\d{2}/\d{2}$', request.form['expiry']):
            flash('Expiry MM/YY.', 'danger')
            return redirect(url_for('payment'))
        if not (request.form['cvv'].isdigit() and len(request.form['cvv'])==3):
            flash('CVV must be 3 digits.', 'danger')
            return redirect(url_for('payment'))

        try:
            ci = datetime.fromisoformat(booking['check_in']).date()
            co = datetime.fromisoformat(booking['check_out']).date()
            total = Decimal(str(booking['total'])).quantize(Decimal('0.00'))
            room_id = int(booking['room_id'])
        except Exception as e:
            flash(f'Invalid booking data: {e}', 'danger')
            return redirect(url_for('payment'))

        conn, cur = get_db_connection()
        try:
            # fetch guest_id
            cur.execute("SELECT guest_id FROM guest WHERE user_id = %s",
                        (session['user_id'],))
            row = cur.fetchone()
            if not row:
                flash('Guest profile missing.', 'danger')
                return redirect(url_for('guest_dashboard'))
            guest_id = row['guest_id']

            # insert booking (if you haven’t yet)
            cur.execute("""
                INSERT INTO bookings
                  (check_in_date, check_out_date, total_price,
                   status, booking_date, room_id, guest_id)
                VALUES (%s,%s,%s,%s,%s,%s,%s)
                RETURNING booking_id
            """, (
                ci, co, total,
                'pending',
                datetime.now().replace(microsecond=0),
                room_id, guest_id
            ))
            booking_id = cur.fetchone()['booking_id']

            # insert payment; trigger will set booking → 'confirmed'
            method = request.form['payment_method'].replace(' ','_').lower()
            cur.execute("""
                INSERT INTO payment_details
                  (payment_date, mode_of_payment,
                   payment_amount, payment_status, booking_id)
                VALUES (%s,%s,%s,%s,%s)
                RETURNING payment_id
            """, (
                date.today(), method, total, 'completed', booking_id
            ))
            payment_id = cur.fetchone()['payment_id']

            conn.commit()

            session.pop('booking_details', None)
            session['payment_summary'] = {
                'booking_id': booking_id,
                'payment_id': payment_id,
                'check_in': booking['check_in'],
                'check_out': booking['check_out'],
                'total': f"{total:.2f}",
                'method': method.replace('_',' ').title(),
                'date': date.today().isoformat()
            }

            flash('Payment successful!', 'success')
            return redirect(url_for('payment_confirmation'))

        except Exception as e:
            conn.rollback()
            flash(f'Payment error: {e}', 'danger')
            return redirect(url_for('payment'))
        finally:
            close_db_connection(conn, cur)

    # GET – render form
    try:
        ci = datetime.fromisoformat(booking['check_in']).date()
        co = datetime.fromisoformat(booking['check_out']).date()
        nights = (co - ci).days
    except:
        nights = 0

    return render_template('payment.html',
        booking=booking,
        nights=nights,
        price_per_night=booking.get('price_per_night', 0),
        payment_methods=['Credit Card', 'Debit Card'],
        selected_method='Credit Card'
    )

@app.route('/payment_confirmation')
def payment_confirmation():
    if 'user_id' not in session or session.get('role')!='guest':
        flash('Please log in.', 'warning')
        return redirect(url_for('login'))

    summary = session.pop('payment_summary', None)
    if not summary:
        flash('No payment to confirm.', 'danger')
        return redirect(url_for('search'))

    return render_template('payment_confirmation.html', summary=summary)

@app.template_filter('format_date')
def format_date(v, fmt='%b %d, %Y'):
    try:
        dt = datetime.fromisoformat(v) if isinstance(v,str) else v
        return dt.strftime(fmt)
    except:
        return v
@app.route('/payment_history')
def payment_history():
    # 1. Ensure login
    if 'user_id' not in session:
        flash('Please log in to view your payment history.', 'warning')
        return redirect(url_for('login'))

    user_id = session['user_id']
    conn, cur = None, None
    payments_list = []

    try:
        # get_db_connection should return (conn, cursor) with DictCursor
        conn, cur = get_db_connection()
        if not conn or not cur:
            flash("Database connection error.", "danger")
            return redirect(url_for('dashboard'))

        # 2. Find guest_id
        cur.execute("SELECT guest_id FROM guest WHERE user_id = %s", (user_id,))
        row = cur.fetchone()
        if not row:
            flash("Guest profile not found.", "warning")
            return redirect(url_for('dashboard'))
        guest_id = row['guest_id']

        # 3. Fetch *all* payments for this guest
        sql = """
            SELECT
              pd.payment_id,
              pd.payment_date,
              pd.mode_of_payment,
              pd.payment_amount,
              pd.payment_status,
              pd.booking_id,
              h.name AS hotel_name
            FROM payment_details pd
            JOIN bookings b       ON pd.booking_id = b.booking_id
            LEFT JOIN rooms    r  ON b.room_id      = r.room_id
            LEFT JOIN hotel    h  ON r.hotel_id     = h.hotel_id
            WHERE b.guest_id = %s
            ORDER BY pd.payment_date DESC, pd.payment_id DESC;
        """
        cur.execute(sql, (guest_id,))
        payments_list = cur.fetchall()

    except psycopg2.Error as e:
        app.logger.exception(f"Error loading payment history for user {user_id}")
        flash("An error occurred retrieving your payment history.", "danger")
    finally:
        if conn and cur:
            close_db_connection(conn, cur)

    return render_template('payment_history.html', payments=payments_list)

@app.route('/profile', methods=['GET', 'POST'])
def profile():
    conn, cur = None, None # Initialize to None
    try:
        conn, cur = get_db_connection()
        # Ensure user is logged in (you might have a login_required decorator)
        if 'user_id' not in session:
            flash('Please log in to view this page.', 'warning')
            return redirect(url_for('login')) # Assuming you have a 'login' route

        user_id = session['user_id']

        if request.method == 'POST':
            # Use .get() to safely retrieve form data, providing defaults if necessary
            # Using 'or None' ensures an empty string submitted becomes NULL if the DB allows it
            email = request.form.get('email') or None
            # Adjust default if empty string is not desired (e.g., None)
            phone = request.form.get('phone', '')
            addr = request.form.get('address', '')

            # --- Direct UPDATE Query ---
            cur.execute(
                """
                UPDATE users
                SET email = %s,
                    phone_number = %s,
                    address = %s
                WHERE user_id = %s
                """,
                (email, phone, addr, user_id)
            )
            # --- End Direct UPDATE Query ---

            conn.commit()
            flash("Profile updated successfully.", 'info') # Static success message
            # Assuming you have a 'dashboard' route
            return redirect(url_for('dashboard'))

        # GET Request: Fetch current user data
        cur.execute(
            "SELECT email, phone_number, address FROM users WHERE user_id=%s",
            (user_id,)
        )
        user = cur.fetchone()
        if not user:
            flash("User profile not found.", 'danger')
            return redirect(url_for('dashboard')) # Or handle appropriately

        return render_template('profile.html', user=user)

    except Exception as e:
        # Log the error for debugging
        app.logger.error(f"Error in /profile route: {e}")
        # Rollback transaction in case of error during POST
        if conn:
            conn.rollback()
        flash(f"An error occurred: {e}", 'danger')
        # Redirect to a safe page, like dashboard
        return redirect(url_for('dashboard'))
    finally:
        # Ensure connection is closed even if errors occur
        if conn and cur:
            close_db_connection(conn, cur)

@app.route('/notifications')
# @login_required # Use session check instead if not using Flask-Login fully
def notifications():
    if 'user_id' not in session:
         flash("Please log in to view notifications.", "warning")
         return redirect(url_for('login'))

    conn, cur = None, None
    user_id = session['user_id']

    try:
        conn, cur = get_db_connection()
        if not conn or not cur:
            flash("Database connection error.", "danger")
            return redirect(url_for('dashboard'))

        # Fetch notifications
        cur.execute(
            "SELECT notification_id, message, notification_date FROM notifications "
            "WHERE user_id = %s ORDER BY notification_date DESC",
            (user_id,)
        )
        notes = cur.fetchall()


        return render_template('notifications.html', notes=notes)
    except Exception as e:
         flash(f"Error fetching notifications: {e}", 'danger')
         return redirect(url_for('dashboard'))
    finally:
        close_db_connection(conn, cur)
@app.route('/cancellations')
# @login_required # Or use session check
def all_cancellations():
    if 'user_id' not in session:
        flash("Please log in to view your cancellations.", "warning")
        return redirect(url_for('login'))

    # Ensure the user is a guest
    if session.get('role') != 'guest':
         flash("Access denied.", "warning")
         return redirect(url_for('dashboard')) # Or index

    conn, cur = None, None
    user_id = session['user_id']

    try:
        conn, cur = get_db_connection()
        if not conn or not cur:
            flash("Database connection error.", "danger")
            # Redirect to dashboard as it's likely logged in
            return redirect(url_for('dashboard'))

        # First, get the guest_id for the current user
        cur.execute("SELECT guest_id FROM guest WHERE user_id = %s", (user_id,))
        guest_record = cur.fetchone()

        if not guest_record:
            flash("Guest profile not found.", "warning")
            return redirect(url_for('dashboard'))
        guest_id = guest_record['guest_id']

        # Now, fetch ALL cancellations for this guest_id
        cur.execute(
            """
            SELECT
                c.cancellation_id, -- Good practice to select primary key if needed
                b.booking_id,
                c.cancellation_date,
                c.cancellation_reason,
                c.refund_amount,
                h.name AS hotel_name,
                r.room_number, -- Added room number
                b.check_in_date AS original_check_in, -- Added original dates for context
                b.check_out_date AS original_check_out
            FROM cancellation c
            JOIN bookings b USING (booking_id)
            JOIN rooms r USING (room_id)
            JOIN hotel h USING (hotel_id)
            WHERE b.guest_id = %s
            ORDER BY c.cancellation_date DESC -- Show most recent first
            """,
            (guest_id,)
        )
        cancellations_list = cur.fetchall()

        # Pass the full list to a new template
        return render_template('cancellations.html', cancellations=cancellations_list)

    except Exception as e:
         flash(f"Error fetching cancellation history: {e}", 'danger')
         # Redirect to dashboard as something went wrong after login
         return redirect(url_for('dashboard'))
    finally:
        close_db_connection(conn, cur)
@app.route('/stats')
def stats():
    # 1. Auth check
    if 'user_id' not in session:
        flash('Please log in to view statistics.', 'warning')
        return redirect(url_for('login'))

    conn = cur = None
    try:
        conn, cur = get_db_connection()
        user_id = session['user_id']

        # 2. Verify guest role
        cur.execute("SELECT role FROM users WHERE user_id = %s", (user_id,))
        role_row = cur.fetchone()
        if not role_row or role_row['role'] != 'guest':
            flash('Access denied. Guests only.', 'warning')
            return redirect(url_for('dashboard'))

        # 3. Fetch guest_id
        cur.execute("SELECT guest_id FROM guest WHERE user_id = %s", (user_id,))
        guest_row = cur.fetchone()
        if not guest_row:
            flash('Guest profile missing.', 'warning')
            return redirect(url_for('dashboard'))
        guest_id = guest_row['guest_id']

        # 4. Aggregate stats
        stats_sql = """
            SELECT
              COALESCE(SUM(
                CASE WHEN pd.payment_status IN ('confirmed','completed')
                     THEN pd.payment_amount
                     ELSE 0
                END
              ), 0)                      AS total_spent,
              COUNT(
                CASE WHEN pd.payment_status IN ('confirmed','completed')
                     THEN 1
                END
              )                           AS successful_payments,
              COALESCE(SUM(c.refund_amount), 0) AS refunds
            FROM bookings b
            LEFT JOIN payment_details pd ON b.booking_id = pd.booking_id
            LEFT JOIN cancellation   c  ON b.booking_id = c.booking_id
            WHERE b.guest_id = %s;
        """
        cur.execute(stats_sql, (guest_id,))
        s = cur.fetchone() or {'total_spent': 0, 'successful_payments': 0, 'refunds': 0}

        return render_template('stats.html', stats=s)

    except psycopg2.Error as err:
        app.logger.exception("Error loading stats")
        flash("An error occurred loading your stats.", 'danger')
        return redirect(url_for('dashboard'))

    finally:
        if conn and cur:
            close_db_connection(conn, cur)


@app.route('/review/submit/<int:booking_id>', methods=['GET', 'POST'])
def submit_review_simple(booking_id):
    # Ensure user is logged in
    if 'user_id' not in session:
        flash('You must be logged in to submit a review.', 'warning')
        return redirect(url_for('login'))
    user_id = session['user_id']
    
    
    # Fetch booking and any existing review
    booking = None
    existing_review = None
    try:
        conn = get_db_connection()[0] if isinstance(get_db_connection(), tuple) else get_db_connection()
   

        with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
            cur.execute("SELECT guest_id FROM guest WHERE user_id = %s", (user_id,))
            guest_row = cur.fetchone()
            # …
            guest_id = guest_row["guest_id"]

            # Ensure table names match your schema (e.g., hotels vs. hotel)
            cur.execute(
                """
                SELECT 
                    b.booking_id AS id,
                    b.guest_id,
                    b.check_in_date,
                    b.check_out_date,
                    r.hotel_id,
                    b.status,
                    h.name AS hotel_name
                FROM bookings b
                JOIN rooms r ON b.room_id = r.room_id
                JOIN hotel h ON r.hotel_id = h.hotel_id
                WHERE b.booking_id = %s AND b.guest_id = %s
                """,
                (booking_id, guest_id)
            )
            
            row = cur.fetchone()
            if not row:
                app.logger.debug(f"No booking found for booking_id={booking_id}, guest_id={guest_id}")
                flash('Booking not found or unauthorized.', 'warning')
                return redirect(url_for('dashboard'))
            booking = dict(row)

            # Fetch existing review
            cur.execute(
                "SELECT review_id, rating, comment, review_date FROM review WHERE booking_id = %s LIMIT 1",
                (booking_id,)
            )
            rv = cur.fetchone()
            if rv:
                existing_review = dict(rv)
    except Exception as e:
        app.logger.exception("Error fetching booking/review:")
        flash(f"Database error: {str(e)}", 'danger')
        return redirect(url_for('dashboard'))
    finally:
        if conn:
            conn.close()

    # Prevent reviewing cancelled or future bookings
    today = date.today()
    if booking['status'].lower() == 'cancelled':
        flash('Cannot review a cancelled booking.', 'warning')
        return redirect(url_for('dashboard'))
    co_date = booking['check_out_date']
    if isinstance(co_date, datetime):
        co_date = co_date.date()
    if co_date > today:
        flash('You can only review on or after the check-out date.', 'warning')
        return redirect(url_for('dashboard'))

    # Populate form on GET
    if request.method == 'GET':
        return render_template(
            'submit_review_simple.html',
            booking=booking,
            errors={},
            submitted_rating=str(existing_review['rating']) if existing_review else '',
            submitted_comment=existing_review['comment'] if existing_review else '',
            submitted_date=(existing_review['review_date'].strftime('%Y-%m-%d %H:%M:%S') if existing_review else ''),
            is_edit=bool(existing_review)
        )

    # Handle form submission
    errors = {}
    rating_str = request.form.get('rating')
    comment = request.form.get('comment', '').strip()

    # Validate rating
    try:
        rating = float(rating_str)
        if not (1 <= rating <= 5):
            errors['rating'] = 'Rating must be between 1 and 5.'
    except (TypeError, ValueError):
        errors['rating'] = 'Rating is required and must be a number between 1 and 5.'

    # Validate comment
    if not comment:
        errors['comment'] = 'Comment is required.'
    elif len(comment) < 10:
        errors['comment'] = 'Comment must be at least 10 characters.'
    elif len(comment) > 1000:
        errors['comment'] = 'Comment cannot exceed 1000 characters.'

    if errors:
        flash('Please correct the errors below.', 'danger')
        return render_template(
            'submit_review_simple.html',
            booking=booking,
            errors=errors,
            submitted_rating=rating_str,
            submitted_comment=comment,
            submitted_date=request.form.get('submitted_date', ''),
            is_edit=bool(existing_review)
        )

    # Insert or Update review
    try:
        conn2 = get_db_connection()[0] if isinstance(get_db_connection(), tuple) else get_db_connection()
        with conn2.cursor() as cur:
            ts = datetime.now().replace(microsecond=0)
            if existing_review:
                cur.execute(
                    "UPDATE review SET rating=%s, comment=%s, review_date=%s WHERE review_id=%s",
                    (rating, comment, ts, existing_review['review_id'])
                )
            else:
                cur.execute(
                    "INSERT INTO review (rating, comment, booking_id, guest_id, hotel_id, review_date)"
                    " VALUES (%s, %s, %s, %s, %s, %s)",
                    (rating, comment, booking_id, guest_id, booking['hotel_id'], ts)
                )
        conn2.commit()
        flash('Your review has been saved.', 'success')
        return redirect(url_for('dashboard'))
    except Exception as e:
        if conn2:
            conn2.rollback()
        app.logger.exception("Error saving review:")
        flash(f"Error saving your review: {str(e)}", 'danger')
        return render_template(
            'submit_review_simple.html',
            booking=booking,
            errors=errors,
            submitted_rating=rating_str,
            submitted_comment=comment,
            submitted_date=request.form.get('submitted_date', ''),
            is_edit=bool(existing_review)
        )
    finally:
        if conn2:
            conn2.close()

@app.route('/host/dashboard')

def host_dashboard():
    if 'user_id' not in session or session.get('role') != 'host':
        return redirect(url_for('login'))
    
    conn, cur = get_db_connection()
    try:
        # Get host properties
        cur.execute("""
            SELECT h.*, 
                (SELECT COUNT(*) FROM rooms WHERE hotel_id = h.hotel_id) AS total_rooms,
                (SELECT COUNT(*) FROM bookings b 
                 JOIN rooms r ON b.room_id = r.room_id 
                 WHERE r.hotel_id = h.hotel_id) AS total_bookings
            FROM hotel h
            WHERE h.host_id = (SELECT host_id FROM host WHERE user_id = %s)
        """, (session['user_id'],))
        
        hotels = cur.fetchall()
        cur.execute("""
            SELECT first_name, last_name 
            FROM users 
            WHERE user_id = %s
        """, (session['user_id'],))
        user = cur.fetchone()

        # Get notification count
        cur.execute("""
            SELECT COUNT(*) AS notification_count 
            FROM notifications 
            WHERE user_id = %s
        """, (session['user_id'],))
        notification_count = cur.fetchone()['notification_count']
        # Get recent bookings across all hotels
        cur.execute("""
            SELECT b.*, r.room_number, h.name AS hotel_name,
                   u.first_name || ' ' || u.last_name AS guest_name
            FROM bookings b
            JOIN rooms r USING (room_id)
            JOIN hotel h USING (hotel_id)
            JOIN guest g USING (guest_id)
            JOIN users u ON g.user_id = u.user_id
            WHERE h.host_id = (SELECT host_id FROM host WHERE user_id = %s)
            ORDER BY b.booking_date DESC
            LIMIT 10
        """, (session['user_id'],))
        
        recent_bookings = cur.fetchall()
        
        return render_template('host_dashboard.html',
                             hotels=hotels,
                             recent_bookings=recent_bookings,
                             user=user,
                             notification_count=notification_count)

    except Exception as e:
        flash(f'Error loading dashboard: {str(e)}', 'danger')
        return redirect(url_for('index'))
    finally:
        close_db_connection(conn, cur)
# Helper functions for host dashboard
def get_total_properties(cur, host_id):
    cur.execute("SELECT COUNT(*) FROM hotel WHERE host_id = %s", (host_id,))
    return cur.fetchone()['count']

def get_monthly_revenue(cur, host_id):
    cur.execute("""
        SELECT COALESCE(SUM(total_price), 0) AS revenue
        FROM bookings
        WHERE status = 'confirmed'
        AND check_in_date >= CURRENT_DATE - INTERVAL '30 days'
        AND room_id IN (SELECT room_id FROM rooms WHERE hotel_id IN 
            (SELECT hotel_id FROM hotel WHERE host_id = %s))
    """, (host_id,))
    return float(cur.fetchone()['revenue'])

def get_occupancy_rate(cur, host_id):
    cur.execute("""
        SELECT COALESCE(
            (COUNT(*) * 100.0 / NULLIF(SUM(total_rooms), 0)), 
            0
        ) AS rate
        FROM bookings
        JOIN rooms USING (room_id)
        JOIN hotel USING (hotel_id)
        WHERE host_id = %s
        AND CURRENT_DATE BETWEEN check_in_date AND check_out_date
    """, (host_id,))
    return round(cur.fetchone()['rate'], 2)

def get_average_rating(cur, host_id):
    cur.execute("""
        SELECT COALESCE(ROUND(AVG(rating), 1), 0.0) AS avg_rating
        FROM review
        WHERE hotel_id IN (SELECT hotel_id FROM hotel WHERE host_id = %s)
    """, (host_id,))
    return cur.fetchone()['avg_rating']

def get_hotels(cur, host_id):
    cur.execute("""
        SELECT h.*, 
            (SELECT image_url FROM hotel_images 
             WHERE hotel_id = h.hotel_id LIMIT 1) AS main_image
        FROM hotel h
        WHERE h.host_id = %s
    """, (host_id,))
    return cur.fetchall()

def get_recent_bookings(cur, host_id):
    cur.execute("""
        SELECT u.first_name, u.last_name,
               b.check_in_date, b.check_out_date,
               b.status, b.total_price
        FROM bookings b
        JOIN rooms r USING (room_id)
        JOIN hotel h USING (hotel_id)
        JOIN guest g USING (guest_id)
        JOIN users u ON g.user_id = u.user_id
        WHERE h.host_id = %s
        ORDER BY b.booking_date DESC
        LIMIT 5
    """, (host_id,))
    return cur.fetchall()

def get_recent_reviews(cur, host_id):
    cur.execute("""
        SELECT u.first_name, u.last_name,
               r.rating, r.comment, r.review_date
        FROM review r
        JOIN hotel h USING (hotel_id)
        JOIN guest g USING (guest_id)
        JOIN users u ON g.user_id = u.user_id
        WHERE h.host_id = %s
        ORDER BY r.review_date DESC
        LIMIT 3
    """, (host_id,))
    return cur.fetchall()

def get_revenue_data(cur, host_id):
    months = [(datetime.now() - timedelta(days=i*30)).strftime('%Y-%m-01') 
             for i in range(5, -1, -1)]
    
    revenue_data = []
    for month in months:
        end_date = (datetime.strptime(month, '%Y-%m-%d') + 
                    timedelta(days=32)).replace(day=1)
        cur.execute("""
            SELECT COALESCE(SUM(total_price), 0) AS revenue
            FROM bookings
            WHERE room_id IN (
                SELECT room_id FROM rooms 
                WHERE hotel_id IN (
                    SELECT hotel_id FROM hotel 
                    WHERE host_id = %s
                )
            )
            AND booking_date >= %s 
            AND booking_date < %s
        """, (host_id, month, end_date.strftime('%Y-%m-%d')))
        revenue_data.append(float(cur.fetchone()['revenue']))
    
    labels = [datetime.strptime(m, '%Y-%m-%d').strftime('%b %Y') for m in months]
    return labels, revenue_data
# Add this with other template filters
@app.template_filter('format_date')
def format_date(value):
    """Format datetime object or ISO date string"""
    if isinstance(value, str):
        try:
            value = datetime.fromisoformat(value)
        except ValueError:
            return value
    if not value:
        return ""
    return value.strftime('%b %d, %Y')
@app.route('/search', methods=['GET', 'POST'])
def search():
    today_date = date.today().strftime('%Y-%m-%d')
    form_vals = {
        'city': '',
        'check_in': '',
        'check_out': '',
        'min_price': 0,
        'max_price': 500,
        'min_capacity': 1,
        'min_rating': 0
    }

    # On POST: run the search and render results page
    if request.method == 'POST':
        # 1) Pull & cast form values
        form_vals['city']         = request.form.get('city', '').strip()
        form_vals['check_in']     = request.form.get('check_in', '')
        form_vals['check_out']    = request.form.get('check_out', '')
        form_vals['min_price']    = request.form.get('min_price', 0, type=float)
        form_vals['max_price']    = request.form.get('max_price', 500, type=float)
        form_vals['min_capacity'] = request.form.get('min_capacity', 1, type=int)
        form_vals['min_rating']   = request.form.get('min_rating', 0, type=float)

        # 2) Query the DB
        conn, cur = get_db_connection()
        cur.execute(
            "SELECT * FROM get_available_rooms_by_location(%s,%s,%s,%s,%s,%s,%s)",
            (
              form_vals['city'],
              form_vals['check_in'],
              form_vals['check_out'],
              form_vals['min_price'],
              form_vals['max_price'],
              form_vals['min_capacity'],
              form_vals['min_rating']
            )
        )
        results = [dict(r) for r in cur.fetchall()]
        close_db_connection(conn, cur)

        # 3) Render the separate results template
        return render_template(
            'search_results.html',
            results=results,
            form_vals=form_vals,
            today_date=today_date
        )

    # GET: just show the search form
    return render_template(
        'search.html',
        form_vals=form_vals,
        today_date=today_date
    )
@app.route('/book/<int:room_id>', methods=['GET', 'POST'])
def book(room_id):
    if 'user_id' not in session or session.get('role') != 'guest':
        flash('Please login to book a room', 'danger')
        return redirect(url_for('login'))
    
    conn, cur = None, None
    try:
        conn, cur = get_db_connection()
        if not conn or not cur:
            flash('Database connection error', 'danger')
            return redirect(url_for('search'))

        # Get room details
        cur.execute("""
            SELECT r.*, h.name AS hotel_name 
            FROM rooms r
            JOIN hotel h ON r.hotel_id = h.hotel_id
            WHERE r.room_id = %s
        """, (room_id,))
        room = cur.fetchone()
        
        if not room:
            flash('Room not found', 'danger')
            return redirect(url_for('search'))

        # Fetch available discounts for both GET and POST
        cur.execute("""
            SELECT promo_code, discount_amount, description 
            FROM discounts 
            WHERE CURRENT_DATE BETWEEN valid_from AND valid_until
            ORDER BY discount_amount DESC
        """)
        available_discounts = cur.fetchall()

        if request.method == 'POST':
            check_in = request.form.get('check_in')
            check_out = request.form.get('check_out')
            promo_code = request.form.get('promo_code', '').strip()

            # Validate dates
            try:
                check_in_date = datetime.strptime(check_in, '%Y-%m-%d').date()
                check_out_date = datetime.strptime(check_out, '%Y-%m-%d').date()
                today = date.today()
                
                if check_in_date >= check_out_date:
                    flash('Check-out must be after check-in', 'danger')
                    return redirect(url_for('book', room_id=room_id))
                
                if check_in_date < today:
                    flash('Cannot book dates in the past', 'danger')
                    return redirect(url_for('book', room_id=room_id))

            except ValueError as e:
                app.logger.error(f"Date parsing error: {str(e)}")
                flash('Invalid date format (use YYYY-MM-DD)', 'danger')
                return redirect(url_for('book', room_id=room_id))

            # Check availability using direct SQL
            try:
                cur.execute("""
                    SELECT NOT EXISTS (
                        SELECT 1 
                        FROM bookings 
                        WHERE room_id = %s 
                        AND check_in_date < %s 
                        AND check_out_date > %s
                    ) AS available
                """, (room_id, check_out_date, check_in_date))
                
                result = cur.fetchone()
                available = result['available'] if result else False
                
                if not available:
                    flash('Room not available for selected dates', 'danger')
                    return redirect(url_for('book', room_id=room_id))

            except psycopg2.Error as e:
                app.logger.error(f"Database error: {e.pgerror}")
                flash('Error checking availability', 'danger')
                return redirect(url_for('book', room_id=room_id))
            except Exception as e:
                app.logger.error(f"Availability check error: {str(e)}")
                flash('Error checking availability', 'danger')
                return redirect(url_for('book', room_id=room_id))

            # Calculate pricing
            try:
                nights = (check_out_date - check_in_date).days
                base_price = float(room['price']) * nights
                discount = 0.0

                if promo_code:
                    cur.execute("""
                        SELECT discount_amount::FLOAT 
                        FROM discounts 
                        WHERE promo_code = %s 
                        AND CURRENT_DATE BETWEEN valid_from AND valid_until
                    """, (promo_code,))
                    promo = cur.fetchone()
                    if promo:
                        discount = promo['discount_amount']
                    else:
                        flash('Invalid/expired promo code', 'warning')

                total = max(base_price - discount, 0.0)

                # Store booking details
                session['booking_details'] = {
                    'room_id': room_id,
                    'check_in': check_in_date.isoformat(),
                    'check_out': check_out_date.isoformat(),
                    'price_per_night': float(room['price']),
                    'base_price': base_price,
                    'discount': discount,
                    'total': total,
                    'promo_code': promo_code or None,
                    'hotel_name': room['hotel_name'],
                    'room_type': room['room_type']
                }

                return redirect(url_for('payment'))

            except Exception as e:
                app.logger.error(f"Pricing calculation error: {str(e)}")
                flash('Error calculating booking total', 'danger')
                return redirect(url_for('book', room_id=room_id))
            

        return render_template('booking.html',
                             room=room,
                             min_date=date.today().isoformat(),
                             discounts=available_discounts)
        
    except Exception as e:
        app.logger.error(f"General booking error: {str(e)}")
        flash('Error processing booking request', 'danger')
        return redirect(url_for('search'))
    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()
@app.route('/manage-rooms/<int:hotel_id>')
def manage_rooms(hotel_id):
    if 'user_id' not in session or session.get('role') != 'host':
        return redirect(url_for('login'))

    conn, cur = get_db_connection()
    try:
        # 1) Verify hotel ownership
        cur.execute("""
            SELECT h.* 
              FROM hotel h
              JOIN host ho ON h.host_id = ho.host_id
             WHERE h.hotel_id = %s
               AND ho.user_id = %s
        """, (hotel_id, session['user_id']))
        hotel = cur.fetchone()
        if not hotel:
            flash('Hotel not found or access denied', 'danger')
            return redirect(url_for('host_dashboard'))

        # 2) Pull rooms + booking counts from the view
        cur.execute("""
            SELECT *
              FROM v_rooms_with_booking_counts
             WHERE hotel_id = %s
             ORDER BY room_number
        """, (hotel_id,))
        rooms = cur.fetchall()

        return render_template(
            'manage_rooms.html',
            hotel=hotel,
            rooms=rooms
        )

    except Exception as e:
        flash(f'Error loading rooms: {e}', 'danger')
        return redirect(url_for('host_dashboard'))
    finally:
        close_db_connection(conn, cur)
@app.route('/hotel-bookings/<int:hotel_id>')
def hotel_bookings(hotel_id):
    if 'user_id' not in session or session.get('role') != 'host':
        return redirect(url_for('login'))
    
    conn, cur = get_db_connection()
    try:
        # Verify hotel ownership
        cur.execute("""
            SELECT h.* FROM hotel h
            JOIN host ho ON h.host_id = ho.host_id
            WHERE h.hotel_id = %s AND ho.user_id = %s
        """, (hotel_id, session['user_id']))
        
        hotel = cur.fetchone()
        if not hotel:
            flash('Hotel not found or access denied', 'danger')
            return redirect(url_for('host_dashboard'))
        
        # Get bookings
        cur.execute("""
            SELECT b.*, r.room_number,
                   u.first_name || ' ' || u.last_name AS guest_name
            FROM bookings b
            JOIN rooms r USING (room_id)
            JOIN guest g USING (guest_id)
            JOIN users u ON g.user_id = u.user_id
            WHERE r.hotel_id = %s
            ORDER BY b.booking_date DESC
        """, (hotel_id,))
        
        bookings = cur.fetchall()
        return render_template('hotel_bookings.html', hotel=hotel, bookings=bookings)
    
    except Exception as e:
        flash(f'Error loading bookings: {str(e)}', 'danger')
        return redirect(url_for('host_dashboard'))
    finally:
        close_db_connection(conn, cur)
@app.route('/add-room/<int:hotel_id>', methods=['GET', 'POST'])

def add_room(hotel_id):
    if 'user_id' not in session or session.get('role') != 'host':
        return redirect(url_for('login'))
    
    conn, cur = get_db_connection()
    try:
        # Verify hotel ownership
        cur.execute("""
            SELECT h.* FROM hotel h
            JOIN host ho ON h.host_id = ho.host_id
            WHERE h.hotel_id = %s AND ho.user_id = %s
        """, (hotel_id, session['user_id']))
        
        hotel = cur.fetchone()
        if not hotel:
            flash('Hotel not found or access denied', 'danger')
            return redirect(url_for('host_dashboard'))

        if request.method == 'POST':
            # Handle file uploads
            image_paths = []
            if 'images' in request.files:
                files = request.files.getlist('images')
                for file in files:
                    if file and allowed_file(file.filename):
                        filename = secure_filename(file.filename)
                        save_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
                        file.save(save_path)
                        image_paths.append(f'uploads/rooms/{filename}')

            # Get form data
            room_number = request.form['room_number']
            price = request.form['price']
            capacity = request.form['capacity']
            room_type = request.form['room_type']

            cur.execute("""
                INSERT INTO rooms 
                (room_number, price, capacity, room_type, hotel_id, images)
                VALUES (%s, %s, %s, %s, %s, %s)
            """, (room_number, price, capacity, room_type, hotel_id, image_paths))
            conn.commit()
            flash('Room added successfully with images!', 'success')
            return redirect(url_for('manage_rooms', hotel_id=hotel_id))

        return render_template('add_room.html', hotel=hotel)
    
    except Exception as e:
        if conn: conn.rollback()
        flash(f'Error adding room: {str(e)}', 'danger')
        return redirect(url_for('manage_rooms', hotel_id=hotel_id))
    finally:
        close_db_connection(conn, cur)
@app.route('/update-room-images/<int:room_id>', methods=['POST'])
def update_room_images(room_id):
    if 'user_id' not in session or session.get('role') != 'host':
        return redirect(url_for('login'))
    
    conn, cur = get_db_connection()
    try:
        # Verify room ownership
        cur.execute("""
            SELECT r.* FROM rooms r
            JOIN hotel h ON r.hotel_id = h.hotel_id
            JOIN host ho ON h.host_id = ho.host_id
            WHERE r.room_id = %s AND ho.user_id = %s
        """, (room_id, session['user_id']))
        
        if not cur.fetchone():
            flash('Room not found or access denied', 'danger')
            return redirect(url_for('host_dashboard'))

        # Handle file uploads
        image_paths = []
        if 'images' in request.files:
            files = request.files.getlist('images')
            for file in files:
                if file and allowed_file(file.filename):
                    filename = secure_filename(file.filename)
                    save_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
                    file.save(save_path)
                    image_paths.append(f'uploads/rooms/{filename}')

        # Update database
        cur.execute("""
            UPDATE rooms 
            SET images = images || %s 
            WHERE room_id = %s
        """, (image_paths, room_id))
        conn.commit()
        flash('Room images updated successfully!', 'success')
        return redirect(url_for('manage_rooms', hotel_id=request.args.get('hotel_id')))
    
    except Exception as e:
        if conn: conn.rollback()
        flash(f'Error updating images: {str(e)}', 'danger')
        return redirect(url_for('host_dashboard'))
    finally:
        close_db_connection(conn, cur)
from datetime import date
@app.route('/delete-room/<int:room_id>', methods=['POST'])
def delete_room(room_id):
    # 1) Auth guard
    if 'user_id' not in session or session.get('role') != 'host':
        flash('Please log in as a host.', 'warning')
        return redirect(url_for('login'))

    conn, cur = get_db_connection()
    try:
        # 2) Verify ownership
        cur.execute("""
            SELECT 1
              FROM rooms r
              JOIN hotel h USING(hotel_id)
              JOIN host ho ON h.host_id = ho.host_id
             WHERE r.room_id = %s
               AND ho.user_id = %s
        """, (room_id, session['user_id']))
        if not cur.fetchone():
            flash('Room not found or access denied.', 'danger')
            return redirect(url_for('host_dashboard'))

        # 3) Single delete — your BEFORE DELETE trigger does:
        #    • cancel_bookings_by_room()
        #    • insert into cancellation, delete reviews
        #    • null out room_id on orphaned bookings
        cur.execute("DELETE FROM rooms WHERE room_id = %s", (room_id,))
        conn.commit()

        flash('Room deleted. Related bookings cancelled & logged.', 'success')

    except Exception as e:
        conn.rollback()
        flash(f'Error deleting room: {e}', 'danger')

    finally:
        close_db_connection(conn, cur)

    return redirect(request.referrer or url_for('host_dashboard'))
@app.route('/add-hotel', methods=['GET', 'POST'])

def add_hotel():
    if 'user_id' not in session or session.get('role') != 'host':
        return redirect(url_for('login'))
    
    conn, cur = get_db_connection()
    try:
        if request.method == 'POST':
            # Get form data
            name = request.form['name']
            address = request.form['address']
            city = request.form['city']
            state = request.form['state']
            phone = request.form['phone']
            email = request.form['email']
            
            zip_code = request.form['zip_code']
            
            # Get host_id
            cur.execute("SELECT host_id FROM host WHERE user_id = %s", (session['user_id'],))
            host_id = cur.fetchone()['host_id']
            
            # Insert new hotel
            cur.execute("""
    INSERT INTO hotel 
    (host_id, name, address, city, state, phone_number, email, zip_code)
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
""", (host_id, name, address, city, state, phone, email, zip_code))

            
            conn.commit()
            flash('Hotel added successfully!', 'success')
            return redirect(url_for('host_dashboard'))
        
        return render_template('add_hotel.html')
    
    except Exception as e:
        if conn: conn.rollback()
        flash(f'Error adding hotel: {str(e)}', 'danger')
        return redirect(url_for('host_dashboard'))
    finally:
        close_db_connection(conn, cur)
@app.route('/edit-room/<int:room_id>', methods=['GET', 'POST'])
def edit_room(room_id):
    # Authentication/Authorization Check
    if 'user_id' not in session or session.get('role') != 'host':
        flash('Please log in as a host to access this page.', 'warning')
        return redirect(url_for('login'))

    conn, cur = None, None
    try:
        conn, cur = get_db_connection()

        # Verify Room Ownership & Fetch Room Data
        cur.execute("""
            SELECT r.*, h.hotel_id
            FROM rooms r
            JOIN hotel h USING (hotel_id)
            JOIN host ho ON h.host_id = ho.host_id
            WHERE r.room_id = %s AND ho.user_id = %s
        """, (room_id, session['user_id']))

        room_data = cur.fetchone()
        if not room_data:
            flash('Room not found or access denied.', 'danger')
            return redirect(url_for('host_dashboard'))

        # Prepare Existing Images
        existing_images = room_data.get('images', []) or []
        hotel_id = room_data['hotel_id']

        if request.method == 'POST':
            try:
                # Validate form data
                room_number = int(request.form['room_number'])
                price = float(request.form['price'])
                capacity = int(request.form['capacity'])
                room_type = request.form['room_type']

                # Check for duplicate room number
                cur.execute("""
                    SELECT room_id FROM rooms
                    WHERE hotel_id = %s AND room_number = %s AND room_id != %s
                """, (hotel_id, room_number, room_id))
                if cur.fetchone():
                    flash(f'Room number {room_number} already exists in this hotel.', 'danger')
                    return render_template('edit_room.html', room=room_data, existing_images=existing_images)

                # Handle file uploads
                new_image_paths = []
                if 'images' in request.files:
                    upload_path = os.path.join(
                        app.config['UPLOAD_FOLDER'],
                        app.config['ROOM_IMAGE_SUBFOLDER']
                    )
                    os.makedirs(upload_path, exist_ok=True)

                    for file in request.files.getlist('images'):
                        if file and file.filename and allowed_file(file.filename):
                            filename = secure_filename(f"room_{room_id}_{file.filename}")
                            file.save(os.path.join(upload_path, filename))
                            relative_path = f"{app.config['ROOM_IMAGE_SUBFOLDER']}/{filename}"
                            new_image_paths.append(relative_path)

                # Combine images and update database
                updated_images = existing_images + new_image_paths
                
                cur.execute("""
                    UPDATE rooms SET
                        room_number = %s,
                        price = %s,
                        capacity = %s,
                        room_type = %s,
                        images = %s,
                        updated_at = CURRENT_TIMESTAMP
                    WHERE room_id = %s
                """, (room_number, price, capacity, room_type, updated_images, room_id))

                conn.commit()
                flash('Room updated successfully!', 'success')
                return redirect(url_for('manage_rooms', hotel_id=hotel_id))

            except (ValueError, KeyError) as e:
                flash('Invalid form data. Please check your inputs.', 'danger')
                return render_template('edit_room.html', room=room_data, existing_images=existing_images)
            except Exception as e:
                conn.rollback()
                flash(f'Error updating room: {str(e)}', 'danger')
                return render_template('edit_room.html', room=room_data, existing_images=existing_images)

        return render_template('edit_room.html', room=room_data, existing_images=existing_images)

    except Exception as e:
        if conn: conn.rollback()
        flash(f'An error occurred: {str(e)}', 'danger')
        return redirect(url_for('host_dashboard'))
    finally:
        close_db_connection(conn, cur)
@app.route('/booking-details/<int:booking_id>')
def booking_details(booking_id):
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    conn, cur = get_db_connection()
    try:
        # For Hosts
        if session['role'] == 'host':
            cur.execute("""
                SELECT 
                    b.*, 
                    r.room_number, 
                    h.name AS hotel_name,
                    u.first_name || ' ' || u.last_name AS guest_name,
                    p.payment_status, 
                    p.payment_date,
                    p.mode_of_payment,
                    p.payment_amount
                FROM bookings b
                JOIN rooms r ON b.room_id = r.room_id
                JOIN hotel h ON r.hotel_id = h.hotel_id
                JOIN guest g ON b.guest_id = g.guest_id
                JOIN users u ON g.user_id = u.user_id
                LEFT JOIN payment_details p ON b.booking_id = p.booking_id
                WHERE b.booking_id = %s
                AND h.host_id = (SELECT host_id FROM host WHERE user_id = %s)
            """, (booking_id, session['user_id']))
        
        # For Guests
        elif session['role'] == 'guest':
            cur.execute("""
                SELECT 
                    b.*,
                    r.room_number, 
                    h.name AS hotel_name,
                    u.first_name || ' ' || u.last_name AS guest_name,
                    p.payment_status, 
                    p.payment_date,
                    p.mode_of_payment,
                    p.payment_amount
                FROM bookings b
                JOIN rooms r ON b.room_id = r.room_id
                JOIN hotel h ON r.hotel_id = h.hotel_id
                JOIN guest g ON b.guest_id = g.guest_id

                JOIN users u ON g.user_id = u.user_id  
                LEFT JOIN payment_details p ON b.booking_id = p.booking_id
                WHERE b.booking_id = %s
                AND b.guest_id = (SELECT guest_id FROM guest WHERE user_id = %s)
            """, (booking_id, session['user_id']))
        
        booking = cur.fetchone()
        
        if not booking:
            flash('Booking not found or access denied', 'danger')
            return redirect(url_for('dashboard'))
            
        # Convert Decimal to float for JSON serialization if needed
        if booking.get('total_price'):
            booking['total_price'] = float(booking['total_price'])
        if booking.get('payment_amount'):
            booking['payment_amount'] = float(booking['payment_amount'])
            
        return render_template('booking_details.html', booking=booking)
    
    except Exception as e:
        flash(f'Error loading booking details: {str(e)}', 'danger')
        return redirect(url_for('dashboard'))
    finally:
        close_db_connection(conn, cur)
@app.route('/edit-hotel/<int:hotel_id>', methods=['GET', 'POST'])
def edit_hotel(hotel_id):
    if 'user_id' not in session or session.get('role') != 'host':
        return redirect(url_for('login'))
    
    conn, cur = get_db_connection()
    try:
        # Verify ownership
        cur.execute("""
            SELECT * FROM hotel 
            WHERE hotel_id = %s 
            AND host_id = (SELECT host_id FROM host WHERE user_id = %s)
        """, (hotel_id, session['user_id']))
        hotel = cur.fetchone()
        
        if not hotel:
            flash('Hotel not found or access denied', 'danger')
            return redirect(url_for('host_dashboard'))

        if request.method == 'POST':
            # Get and validate form data
            name = request.form['name']
            address = request.form['address']
            city = request.form['city']
            state = request.form['state']
            email = request.form['email']
            phone_number = request.form['phone_number']

            try:
                zip_code = int(request.form['zip_code'])
            except ValueError:
                flash('ZIP code must be an integer.', 'danger')
                return redirect(url_for('edit_hotel', hotel_id=hotel_id))

            # Execute update
            cur.execute("""
                UPDATE hotel
                SET name = %s,
                    address = %s,
                    city = %s,
                    state = %s,
                    zip_code = %s,
                    phone_number = %s,
                    email = %s
                WHERE hotel_id = %s
            """, (
                name, address, city, state,
                zip_code, phone_number, email,
                hotel_id
            ))
            conn.commit()
            flash('Hotel updated successfully!', 'success')
            return redirect(url_for('manage_rooms', hotel_id=hotel_id))

        return render_template('edit_hotel.html', hotel=hotel)
    finally:
        cur.close()
        conn.close()

from datetime import date

@app.route('/delete-hotel/<int:hotel_id>', methods=['POST'])
def delete_hotel(hotel_id):
    if 'user_id' not in session or session.get('role') != 'host':
        return redirect(url_for('login'))

    conn, cur = get_db_connection()
    try:
        # 1) Ownership check
        cur.execute("""
            SELECT 1
              FROM hotel h
              JOIN host ho ON h.host_id = ho.host_id
             WHERE h.hotel_id = %s
               AND ho.user_id = %s
        """, (hotel_id, session['user_id']))
        if not cur.fetchone():
            flash('Hotel not found or access denied', 'danger')
            return redirect(url_for('host_dashboard'))

        # 2) Cancel + log + delete all bookings for this hotel's rooms
        cur.execute("""
            SELECT b.booking_id, b.total_price
              FROM bookings b
              JOIN rooms   r ON b.room_id = r.room_id
             WHERE r.hotel_id = %s
               AND b.status != 'cancelled'
        """, (hotel_id,))
        bookings = cur.fetchall()

        for b in bookings:
            bid        = b['booking_id']
            refund_amt = b['total_price']

            # 2a) Log cancellation
            cur.execute("""
                INSERT INTO cancellation(
                    cancellation_date,
                    cancellation_reason,
                    refund_amount,
                    booking_id
                ) VALUES (%s, %s, %s, %s)
            """, (
                date.today(),
                'Hotel deleted',
                refund_amt,
                bid
            ))

            # 2b) Drop any review on that booking
            cur.execute("DELETE FROM review WHERE booking_id = %s", (bid,))

            # 2c) Delete the booking itself
            cur.execute("DELETE FROM bookings WHERE booking_id = %s", (bid,))

        # 3) Remove any hotel_amenity rows referencing this hotel
        cur.execute("DELETE FROM hotel_amenity WHERE hotel_id = %s", (hotel_id,))

        # 4) Delete all rooms belonging to the hotel
        cur.execute("DELETE FROM rooms WHERE hotel_id = %s", (hotel_id,))

        # 5) Finally delete the hotel
        cur.execute("""
            DELETE FROM hotel
             WHERE hotel_id = %s
               AND host_id = (
                   SELECT host_id FROM host WHERE user_id = %s
               )
        """, (hotel_id, session['user_id']))

        conn.commit()
        flash('Hotel, its rooms and amenities removed; bookings cancelled & logged.', 'success')

    except Exception as e:
        conn.rollback()
        flash(f'Error deleting hotel: {e}', 'danger')

    finally:
        close_db_connection(conn, cur)

    return redirect(url_for('host_dashboard'))

@app.route('/logout')
def logout():
    session.clear()  # Clear all session variables
    flash('You have been logged out.', 'success')
    return redirect(url_for('index'))
app.jinja_env.globals['calculate_refund'] = calculate_refund

if __name__ == '__main__':
    app.run(debug=True)