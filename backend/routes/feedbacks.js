const router = require('express').Router();
const Feedback = require('../models/Feedback');

// Get all feedbacks
router.get('/', async (req, res) => {
  try {
    const feedbacks = await Feedback.find();
    res.json(feedbacks);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Create feedback
router.post('/', async (req, res) => {
  try {
    const feedback = new Feedback(req.body);
    await feedback.save();
    res.json(feedback);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
