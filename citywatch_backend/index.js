const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');

const { register, login } = require('./auth');
const { upload, submitComplaint, getUserComplaints, getStats } = require('./complaints');
const { getAllComplaints, getComplaintById, updateComplaintStatus, getComplaintContact } = require('./admin');
const path = require('path');

const app = express();
const PORT = 3000;

// Middleware
app.use(cors()); // Enable CORS for all routes (allows Flutter app to connect)
app.use(bodyParser.json()); // Parse JSON bodies
app.use('/uploads', express.static(path.join(__dirname, 'uploads'))); // Serve uploaded images

// Test Route
app.get('/', (req, res) => {
    res.send('CityWatch Server is Running');
});

// Auth Routes
app.post('/api/register', register);
app.post('/api/login', login);

// Complaint Routes
app.post('/api/complaints', upload.single('image'), submitComplaint);
app.get('/api/complaints/user/:userId', getUserComplaints);

// Admin Routes
app.get('/api/admin/complaints', getAllComplaints);
app.get('/api/admin/complaints/:id', getComplaintById); // For admin issue details screen
app.get('/api/admin/complaints/:id/contact', getComplaintContact); // For admin Call Reporter feature
app.patch('/api/admin/complaints/status', updateComplaintStatus);

// Citizen Stats Route
app.get('/api/citizen/stats', getStats);

// Start Server
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
