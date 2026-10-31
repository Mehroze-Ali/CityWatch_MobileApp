const db = require('./database');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const SECRET_KEY = '9e9b438c42281fc469b659c9dd72a0d55b8487e00b87986135d3966b64bb25d1d656267339602f0c809f50218b13a255120453cff222c984b6c3753246848373'; // In a real app, use ENV variables

const register = (req, res) => {
    const { name, email, password } = req.body;

    const salt = bcrypt.genSaltSync(10);
    const password_hash = bcrypt.hashSync(password, salt);

    const sql = 'INSERT INTO users (name, email, password_hash) VALUES (?, ?, ?)';

    db.run(sql, [name, email, password_hash], function (err) {
        if (err) {
            return res.status(500).json({ error: 'Error registering user: ' + err.message });
        }
        res.json({
            message: 'User registered successfully',
            userId: this.lastID
        });
    });
};

const login = (req, res) => {
    const { email, password } = req.body;

    const sql = 'SELECT * FROM users WHERE email = ?';

    db.get(sql, [email], (err, user) => {
        if (err) {
            return res.status(500).json({ error: 'Server error' });
        }
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        const isValidPassword = bcrypt.compareSync(password, user.password_hash);

        if (!isValidPassword) {
            return res.status(401).json({ error: 'Invalid password' });
        }

        const token = jwt.sign({ id: user.id }, SECRET_KEY, { expiresIn: '1h' });

        res.json({
            message: 'Login successful',
            token: token,
            user: {
                id: user.id,
                name: user.name,
                email: user.email
            }
        });
    });
};

module.exports = { register, login };
