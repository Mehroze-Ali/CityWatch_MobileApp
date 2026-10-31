const sqlite3 = require('sqlite3').verbose();
const bcrypt = require('bcryptjs');

const db = new sqlite3.Database('./citywatch.db', (err) => {
    if (err) {
        console.error(err.message);
        return;
    }
    console.log('Connected to database.');

    db.all("SELECT * FROM users", [], (err, rows) => {
        if (err) {
            throw err;
        }
        console.log("Users in DB:", rows);

        rows.forEach(user => {
            console.log(`Checking password for ${user.email} (stored: ${user.password_hash})`);
            const isMatch = bcrypt.compareSync("admin123", user.password_hash);
            console.log(`Password 'admin123' match? ${isMatch}`);
        });
    });
});
