const express = require('express');
const asyncHandler = require('express-async-handler');
const { protect, admin } = require('../middleware/authMiddleware');
const { body, validationResult } = require('express-validator');
const router = express.Router();
const { updateUsername, updatePhoneNumber,profile,getUserReservations } = require('../controllers/UserProfileController');

router.get('/profile', protect, asyncHandler(profile));
router.get('/user-reservations', protect , asyncHandler(getUserReservations));

router.put('/updateUsername', protect, [
  body('newUsername').trim().isLength({ min: 1 }).withMessage('Username must not be empty'),
  updateUsername
]);

// Route to update phone number
router.put('/updatePhoneNumber', protect, [
  body('newPhoneNumber').trim().isMobilePhone().withMessage('Invalid phone number'),
  updatePhoneNumber
]);
module.exports = router;
