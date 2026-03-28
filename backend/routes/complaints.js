const router = require('express').Router();
const Complaint = require('../models/Complaint');

// Get all complaints
router.get('/', async (req, res) => {
  try {
    const complaints = await Complaint.find().sort({ createdAt: -1 });
    res.json(complaints);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Get complaints by userId
router.get('/user/:userId', async (req, res) => {
  try {
    const complaints = await Complaint.find({ userId: req.params.userId }).sort({ createdAt: -1 });
    res.json(complaints);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Create complaint
router.post('/', async (req, res) => {
  try {
    const complaint = await Complaint.findOneAndUpdate(
      { id: req.body.id },
      req.body,
      { upsert: true, new: true }
    );
    res.json(complaint);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Update complaint status
router.put('/:id', async (req, res) => {
  try {
    const complaint = await Complaint.findOneAndUpdate(
      { id: req.params.id },
      req.body,
      { new: true }
    );
    if (!complaint) return res.status(404).json({ message: 'Complaint not found' });
    res.json(complaint);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
