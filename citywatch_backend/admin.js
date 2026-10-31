const db = require('./database');

const getAllComplaints = (req, res) => {
    const sql = `
        SELECT complaints.*, users.name as reported_by, users.email 
        FROM complaints 
        JOIN users ON complaints.user_id = users.id 
        ORDER BY reported_date DESC
    `;

    db.all(sql, [], (err, rows) => {
        if (err) {
            return res.status(500).json({ error: 'Error fetching complaints: ' + err.message });
        }
        res.json(rows);
    });
};

const getComplaintById = (req, res) => {
    const { id } = req.params;

    if (!id) {
        return res.status(400).json({ error: 'Complaint ID is required' });
    }

    const sql = `
        SELECT complaints.*, users.name as reported_by, users.email 
        FROM complaints 
        JOIN users ON complaints.user_id = users.id 
        WHERE complaints.id = ?
    `;

    db.get(sql, [id], (err, row) => {
        if (err) {
            return res.status(500).json({ error: 'Error fetching complaint: ' + err.message });
        }
        if (!row) {
            return res.status(404).json({ error: 'Complaint not found' });
        }
        res.json(row);
    });
};

const updateComplaintStatus = (req, res) => {
    const { id, status } = req.body;

    // Ensure id and status are provided
    if (!id || !status) {
        return res.status(400).json({ error: 'Complaint ID and new status are required' });
    }

    // Allow only two statuses: pending and resolved
    const allowedStatuses = ['pending', 'resolved'];
    if (!allowedStatuses.includes(status)) {
        return res.status(400).json({ error: 'Invalid status. Allowed values are pending or resolved' });
    }

    const sql = 'UPDATE complaints SET status = ? WHERE id = ?';

    db.run(sql, [status, id], function (err) {
        if (err) {
            return res.status(500).json({ error: 'Error updating status: ' + err.message });
        }
        if (this.changes === 0) {
            return res.status(404).json({ error: 'Complaint not found' });
        }
        res.json({ message: 'Status updated successfully', id: id, newStatus: status });
    });
};

// Return reporter contact details (including phone) for a specific complaint
const getComplaintContact = (req, res) => {
    const { id } = req.params;

    if (!id) {
        return res.status(400).json({ error: 'Complaint ID is required' });
    }

    const sql = `
        SELECT complaints.phone,
               users.name AS reported_by,
               users.email
        FROM complaints
        JOIN users ON complaints.user_id = users.id
        WHERE complaints.id = ?
    `;

    db.get(sql, [id], (err, row) => {
        if (err) {
            return res.status(500).json({ error: 'Error fetching contact: ' + err.message });
        }
        if (!row) {
            return res.status(404).json({ error: 'Complaint not found' });
        }
        res.json(row);
    });
};

module.exports = { getAllComplaints, getComplaintById, updateComplaintStatus, getComplaintContact };
