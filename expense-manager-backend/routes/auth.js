const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const router = express.Router();  // cleaned this
const verifyToken = require('../middleware/auth');
const User = require('../models/User');

const JWT_SECRET = process.env.JWT_SECRET || '123456789expense080701';


// ✅ REGISTER
router.post('/register', async (req, res) => {
  const { email, password, userName , monthlyBudget } = req.body;

  try {
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(409).json({ message: 'User already exists' });
    }
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    const newUser = new User({
      email,
      password: hashedPassword,
      userName: userName || '',
      monthlyBudget: Number(monthlyBudget) || 0,
    });

    await newUser.save();

    const token = jwt.sign(
      { userId: newUser._id },
      JWT_SECRET,
      { expiresIn: '1d' }
    );

    res.status(201).json({
      token,
      user: {
        userId: newUser._id,
        email: newUser.email,
        userName: newUser.userName,
        monthlyBudget: newUser.monthlyBudget
      }
    });
  } catch (err) {
    console.error("Register Error:", err);
    res.status(500).json({ message: 'Error registering user' });
  }
});


// ✅ LOGIN
router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  try {
    const user = await User.findOne({ email });
    if (!user) return res.status(401).json({ message: 'Invalid credentials' });

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(401).json({ message: 'Invalid credentials' });

    const token = jwt.sign({ userId: user._id }, JWT_SECRET, { expiresIn: '1d' });

    // Include user data in login response
    res.json({
      token,
      user: {
        _id: user._id,
        email: user.email,
        userName: user.userName || '',
        monthlyBudget: user.monthlyBudget || 0
      }
    });
  } catch (err) {
    res.status(500).json({ message: 'Error logging in' });
  }
});


// ✅ UPDATE Profile Route
router.put('/:id/update', verifyToken, async (req, res) => {
  // Check to ensure the user is only updating their own profile
  if (req.params.id !== req.userId) {
    return res.status(403).json({ message: 'Unauthorized: You can only update your own profile.' });
  }

  const { userName, monthlyBudget } = req.body;
  try {
    const user = await User.findByIdAndUpdate(
      req.params.id,
      { userName, monthlyBudget: Number(monthlyBudget) },
      { new: true }
    );

    if (!user) return res.status(404).json({ message: 'User not found' });

    res.json({
      message: 'Profile updated',
      user: {
        _id: user._id,
        email: user.email,
        userName: user.userName,
        monthlyBudget: user.monthlyBudget
      }
    });
  } catch (error) {
    console.error('Update error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// ✅ GET /api/auth/profile/:id
// ✅ GET /api/auth/profile
router.get('/profile', verifyToken , async (req, res) => {
  try {
    // 🐛 FIX: Use req.userId, which is set by the middleware
    const user = await User.findById(req.userId).select('-password');
    if (!user) return res.status(404).json({ message: 'User not found' });
    res.json(user);
  } catch (err) {
    console.error(err); // Added to help debug in the future
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;




module.exports = router;
