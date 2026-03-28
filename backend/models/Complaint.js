const mongoose = require('mongoose');

const statusUpdateSchema = new mongoose.Schema({
  status: Number,
  timestamp: String,
  note: String,
});

const complaintSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  userId: String,
  title: String,
  description: String,
  department: Number,
  address: String,
  latitude: Number,
  longitude: Number,
  imagePaths: [String],
  status: { type: Number, default: 0 },
  createdAt: String,
  updatedAt: String,
  assignedTo: String,
  authorityNote: String,
  completionImagePath: String,
  statusHistory: [statusUpdateSchema],
});

module.exports = mongoose.model('Complaint', complaintSchema);
