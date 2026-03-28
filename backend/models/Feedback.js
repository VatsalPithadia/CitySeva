const mongoose = require('mongoose');

const feedbackSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  complaintId: String,
  userId: String,
  rating: Number,
  completedOnTime: Boolean,
  comment: String,
  createdAt: String,
});

module.exports = mongoose.model('Feedback', feedbackSchema);
