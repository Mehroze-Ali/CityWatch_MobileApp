const sqlite3 = require('sqlite3').verbose();
const bcrypt = require('bcryptjs');

// Connect to SQLite database
const db = new sqlite3.Database('./citywatch.db', (err) => {
    if (err) {
        console.error('Error opening database:', err.message);
    } else {
        console.log('Connected to the SQLite database.');

        // Initialize Tables
        createTables();
    }
});

function createTables() {
    // Create Users Table (without role column)
    db.run(`CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT UNIQUE,
        password_hash TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`, (err) => {
        if (err) {
            console.error('Error creating users table:', err.message);
        } else {
            console.log('Users table ready.');
            seedUsers();
            ensureUsersTableHasNoRole();
        }
    });

    // Create Complaints Table
    db.run(`CREATE TABLE IF NOT EXISTS complaints (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        type TEXT,
        title TEXT,
        description TEXT,
        phone TEXT,
        latitude REAL,
        longitude REAL,
        status TEXT DEFAULT 'pending',
        confidence_score REAL,
        image_url TEXT,
        reported_date DATETIME,
        FOREIGN KEY (user_id) REFERENCES users (id)
    )`, (err) => {
        if (err) {
            console.error('Error creating complaints table:', err.message);
        } else {
            console.log('Complaints table ready.');
            ensureComplaintsTableHasPhone();
        }
    });
}

// Migration helper: ensure old users table with a `role` column is rebuilt without it
function ensureUsersTableHasNoRole() {
    db.all("PRAGMA table_info(users)", [], (err, rows) => {
        if (err) {
            console.error('Error checking users table schema:', err.message);
            return;
        }

        const hasRole = rows.some((col) => col.name === 'role');
        if (!hasRole) {
            return; // nothing to do
        }

        console.log("Migrating users table to remove 'role' column...");

        db.serialize(() => {
            db.run('BEGIN TRANSACTION');
            db.run(`CREATE TABLE IF NOT EXISTS users_new (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT,
                email TEXT UNIQUE,
                password_hash TEXT,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )`);
            db.run(`INSERT INTO users_new (id, name, email, password_hash, created_at)
                SELECT id, name, email, password_hash, created_at FROM users`);
            db.run('DROP TABLE users');
            db.run('ALTER TABLE users_new RENAME TO users');
            db.run('COMMIT', (commitErr) => {
                if (commitErr) {
                    console.error('Error finalizing users table migration:', commitErr.message);
                } else {
                    console.log("Users table migrated; 'role' column removed.");
                }
            });
        });
    });
}

// Migration helper: ensure complaints table has `phone` column
function ensureComplaintsTableHasPhone() {
    db.all("PRAGMA table_info(complaints)", [], (err, rows) => {
        if (err) {
            console.error('Error checking complaints table schema:', err.message);
            return;
        }

        const hasPhone = rows.some((col) => col.name === 'phone');
        if (hasPhone) {
            return; // already present
        }

        console.log("Adding 'phone' column to complaints table...");
        db.run('ALTER TABLE complaints ADD COLUMN phone TEXT', (alterErr) => {
            if (alterErr) {
                console.error("Error adding 'phone' column to complaints table:", alterErr.message);
            } else {
                console.log("'phone' column added to complaints table.");
            }
        });
    });
}

function seedUsers() {
    db.get("SELECT count(*) as count FROM users", (err, row) => {
        if (err) {
            console.error(err.message);
            return;
        }

        if (row.count === 0) {
            const insert = 'INSERT INTO users (name, email, password_hash) VALUES (?,?,?)';
            const salt = bcrypt.genSaltSync(10);
            const adminPass = bcrypt.hashSync("admin123", salt);
            const citizenPass = bcrypt.hashSync("citizen123", salt);

            db.run(insert, ["Admin User", "admin@citywatch.com", adminPass]);
            db.run(insert, ["Citizen User", "citizen@citywatch.com", citizenPass]);
            console.log('Sample users inserted with hashed passwords.');
        } else {
            console.log('Users table already seeded.');
        }
    });
}

module.exports = db;
