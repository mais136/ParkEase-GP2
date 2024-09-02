const jwt = require('jsonwebtoken');
const asyncHandler = require('express-async-handler');
const User = require('../models/User');

const protect = asyncHandler(async (req, res, next) => {
  let token;

  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      token = req.headers.authorization.split(' ')[1];
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      req.user = await User.findById(decoded.id).select('-password');
      next();
    } catch (error) {
      if (error.name === 'TokenExpiredError') {
        res.status(401).json({ message: 'Token expired, please login again' });
      } else {
        res.status(401).json({ message: 'Not authorized, token failed' });
      }
    }
  }

  if (!token) {
    res.status(401).json({ message: 'Not authorized, no token provided' });
  }
});

const admin = (req, res, next) => {
  if (req.user && req.user.isAdmin) {
    next();
  } else {
    res.status(401);
    throw new Error('Not authorized as an admin');
  }
};

const renewTokenIfNeeded = (req, res, next) => {
  const tokenExpiresSoon = (req.user.exp * 1000) - Date.now() < 5 * 60 * 1000;
  if (tokenExpiresSoon) {
    const newToken = jwt.sign({
      id: req.user.id,
      username: req.user.username,
    }, process.env.JWT_SECRET, { expiresIn: '1h' });
    res.setHeader('x-new-token', newToken);
  }
  next();
}

module.exports = { protect, admin, renewTokenIfNeeded };
