const mongoose = require('mongoose');

const savingsSchema = new mongoose.Schema({
  userId: { type: String, required: true },
  category: { type: String, required: true },
  name: { type: String, required: true },
  targetAmount: { type: Number, required: true },
  currentAmount: { type: Number, default: 0 },
  startDate: { type: Date, required: true },
  endDate: { type: Date, required: true },
});

module.exports = mongoose.model('Savings', savingsSchema);
