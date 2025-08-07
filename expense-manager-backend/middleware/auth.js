const jwt = require('jsonwebtoken');
const JWT_SECRET = process.env.JWT_SECRET || '123456789expense080701';

const verifyToken = (req, res, next) => {
  const authHeader = req.headers.authorization;
  console.log('🔐 Auth Header:', authHeader); // LOG

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'No token provided' });
  }

  const token = authHeader.split(' ')[1];
  console.log('🪪 Extracted Token:', token); // LOG

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    console.log('✅ Decoded:', decoded); // LOG
    req.userId = decoded.userId;
    next();
  } catch (err) {
    console.error('❌ JWT ERROR:', err.message); // LOG
    return res.status(401).json({ message: 'Invalid token' });
  }
};

module.exports = verifyToken;
