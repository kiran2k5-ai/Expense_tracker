const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const router = require('express').Router();

const User = require('../models/User');

const JWT_SECRET = process.env.JWT_SECRET || '123456789expense080701';

// ✅ Register Route
router.post('/register', async (req, res) => {
  const { email, password } = req.body;
    router.post('/register', (req, res) => {
      console.log('✅ /register route hit');
      res.send('Register route working');
    });

  try {
    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(409).json({ message: 'User already exists' });
    }

    // Create new user
    const newUser = new User({ email, password });
    await newUser.save();

    // Return JWT
    const token = jwt.sign({ userId: newUser._id }, JWT_SECRET, { expiresIn: '1d' });
    res.status(201).json({ token });
  } catch (err) {
    res.status(500).json({ message: 'Error registering user' });
  }
});

// ✅ Login Route
router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  try {
    // Find user
    const user = await User.findOne({ email });
    if (!user) return res.status(401).json({ message: 'Invalid credentials' });

    // Compare password
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(401).json({ message: 'Invalid credentials' });

    // Return JWT
    const token = jwt.sign({ userId: user._id }, JWT_SECRET, { expiresIn: '1d' });
    res.json({ token });
  } catch (err) {
    res.status(500).json({ message: 'Error logging in' });
  }
});

module.exports = router;
