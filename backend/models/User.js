const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  name: String,
  email: { type: String, required: true },
  phone: String,
  role: { type: String, enum: ['citizen', 'authority', 'government'], default: 'citizen' },
  avatarPath: String,
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);
