const express = require('express');
const router = express.Router();
const Savings = require('../models/Savings');

// 1. Get all savings for a user
router.get('/:userId', async (req, res) => {
  const savings = await Savings.find({ userId: req.params.userId });
  res.json(savings);
});

// 2. Add new saving
router.post('/', async (req, res) => {
  const newSaving = new Savings(req.body);
  await newSaving.save();
  res.status(201).json(newSaving);
});

// 3. Update saving
router.put('/:id', async (req, res) => {
  const updated = await Savings.findByIdAndUpdate(req.params.id, req.body, { new: true });
  res.json(updated);
});

// 4. Delete saving
router.delete('/:id', async (req, res) => {
  await Savings.findByIdAndDelete(req.params.id);
  res.sendStatus(204);
});

module.exports = router;
