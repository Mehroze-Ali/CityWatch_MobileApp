const db = require('./database');
const multer = require('multer');
const path = require('path');

// Configure Multer for file storage
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'uploads/');
    },
    filename: async (req, file, cb) => {
        try {
            const { v4: uuidv4 } = await import('uuid');
            const uniqueSuffix = Date.now() + '-' + uuidv4() + path.extname(file.originalname);
            cb(null, uniqueSuffix);
        } catch (err) {
            cb(err);
        }
    }
});

const upload = multer({ storage: storage });

const submitComplaint = (req, res) => {
    const { user_id, type, title, description, phone, latitude, longitude, confidence_score } = req.body;

    // Check if file was uploaded
    let image_url = null;
    if (req.file) {
        // Construct URL for the frontend to access the image
        image_url = `/uploads/${req.file.filename}`;
    }

    const sql = `INSERT INTO complaints 
        (user_id, type, title, description, phone, latitude, longitude, confidence_score, image_url, reported_date) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))`;

    const params = [user_id, type, title, description, phone || null, latitude, longitude, confidence_score, image_url];

    db.run(sql, params, function (err) {
        if (err) {
            return res.status(500).json({ error: 'Error submitting complaint: ' + err.message });
        }
        res.json({
            message: 'Complaint submitted successfully',
            complaintId: this.lastID,
            imageUrl: image_url
        });
    });
};

const getUserComplaints = (req, res) => {
    const userId = req.params.userId;
    const sql = 'SELECT * FROM complaints WHERE user_id = ? ORDER BY reported_date DESC';

    db.all(sql, [userId], (err, rows) => {
        if (err) {
            return res.status(500).json({ error: 'Error fetching complaints' });
        }
        res.json({
            count: rows.length,
            complaints: rows
        });
    });
};
const getStats = (req, res) => {
    // Helper to wrap db.all in a Promise
    const query = (sql, params = []) => {
        return new Promise((resolve, reject) => {
            db.all(sql, params, (err, rows) => {
                if (err) reject(err);
                else resolve(rows);
            });
        });
    };

    const typeSql = 'SELECT type, COUNT(*) as count FROM complaints GROUP BY type';
    const statusSql = 'SELECT status, COUNT(*) as count FROM complaints GROUP BY status';

    Promise.all([query(typeSql), query(statusSql)])
        .then(([typeStats, statusStats]) => {
            // Format stats into a cleaner object
            const stats = {
                byType: typeStats.reduce((acc, row) => {
                    acc[row.type] = row.count;
                    return acc;
                }, {}),
                byStatus: statusStats.reduce((acc, row) => {
                    acc[row.status] = row.count;
                    return acc;
                }, {})
            };
            res.json(stats);
        })
        .catch(err => {
            res.status(500).json({ error: 'Error compiling stats: ' + err.message });
        });
};

module.exports = { upload, submitComplaint, getUserComplaints, getStats };
