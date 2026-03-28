const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  phone: { type: String, default: '' },
  role: { type: String, enum: ['citizen', 'authority', 'government'], default: 'citizen' },
  avatarPath: { type: String, default: '' },
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);
