const { body, validationResult } = require('express-validator');
const bcrypt = require('bcryptjs');
const asyncHandler = require('express-async-handler');
const Users = require('../models/User'); // Make sure this path is correct
const axios = require('axios');
const generateOTP = () => Math.floor(100000 + Math.random() * 900000).toString();
const jwt = require('jsonwebtoken');

exports.register = [
  // Validate and sanitize username
  body('username', "Username must be provided")
    .trim()
    .isLength({ min: 1 })
    .escape()
    .custom(async (username) => {
      const usernameExists = await Users.findOne({ Username: username });
      if (usernameExists) {
        return Promise.reject('Username already exists');
      }
    }),

  // Validate password length
  body('password', "Password must be 8 characters long")
    .trim()
    .isLength({ min: 8 }),

  // Validate phone number (Add your own validation logic as necessary)
  body('phoneNumber', "Phone number must be provided")
    .trim()
    .isLength({ min: 1 }),

  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { username, password, phoneNumber } = req.body;

    // Check again for username existence to be extra cautious
    const userExists = await Users.findOne({ Username: username });
    if (userExists) {
      return res.status(400).json({ message: "Username already exists" });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    // Temporarily comment out OTP generation and sending
    
    const otp = generateOTP();
    

    // Create a user instance
    const user = new Users({
      Username: username,
      Password: hashedPassword,
      PhoneNumber: phoneNumber,
      IsPhoneVerified: false,
      // Temporarily comment out OTP related field
      ConfirmationCode: otp,
      // Other fields as necessary...
    });

    try {
      // Temporarily disable sending OTP
      /*
      await axios({
        method: 'POST',
        url: process.env.TELESIGN_VOICE_URL,
        params: {
          phone_number: phoneNumber,
          verify_code: otp
        },
        headers: {
          'X-RapidAPI-Key': process.env.TELESIGN_API_KEY,
          'X-RapidAPI-Host': 'telesign-telesign-voice-verify-v1.p.rapidapi.com'
        }
      });
      */

      // Save the user
      await user.save();

      res.status(201).json({
        message: "User registered successfully. OTP verification is temporarily disabled."
        // When OTP is enabled again, change the message accordingly
      });
    } catch (error) {
      console.error('Error registering user:', error);
      res.status(500).json({ message: "Failed to register user. Internal server error." });
    }
  })
];





exports.confirmUserPhone = asyncHandler(async (req, res) => {
  const { phoneNumber, otp } = req.body;
  const user = await User.findOne({ PhoneNumber: phoneNumber });

  if (!user) {
      return res.status(404).json({ message: "User not found." });
  }

  // Check if OTP has expired
  if (user.otp.expiresAt < new Date()) {
      return res.status(400).json({ message: "OTP has expired." });
  }

  if (user.otp.code === otp) {
      user.IsPhoneVerified = true;
      user.otp.code = ''; // Optionally clear the OTP after verification
      user.otp.expiresAt = null; // Clear expiration time
      await user.save();

      res.status(200).json({ message: "Phone number verified successfully." });
  } else {
      res.status(400).json({ message: "Incorrect OTP." });
  }
});


exports.login = asyncHandler(async (req, res) => {
  const { phoneNumber, password, deviceToken } = req.body;

  const user = await Users.findOne({ PhoneNumber: phoneNumber });
  if (!user) {
    return res.status(404).json({ message: "User not found" });
  }

  const isMatch = await bcrypt.compare(password, user.Password);
  if (!isMatch) {
    return res.status(400).json({ message: "Invalid credentials" });
  }

  if (!user.IsPhoneVerified) {
    return res.json({
      phoneVerificationRequired: true,
      message: "User is not verified. OTP verification is currently disabled."
    });
  }

  // Device check and cooldown logic
  if (user.LastDeviceToken && user.LastLogout) {
    const hoursSinceLastLogout = Math.abs(new Date() - user.LastLogout) / 36e5;
    const isSameDevice = deviceToken === user.LastDeviceToken;

    // Check if user is trying to log in from a new device before cooldown is over
    if (!isSameDevice && hoursSinceLastLogout < 24) {
      const timeLeft = 24 - hoursSinceLastLogout;
      return res.status(409).json({
        message: "Login from a new device is temporarily restricted.",
        canLoginAfter: `${timeLeft.toFixed(2)} hours`
      });
    }
  }

  // Generate JWT access token
  const accessToken = jwt.sign(
    { id: user._id, username: user.Username }, 
    process.env.JWT_SECRET, 
    { expiresIn: '1d' }
  );

  user.CurrentSessionToken = accessToken;
  user.SessionExpires = new Date(new Date().getTime() + (24 * 60 * 60 * 1000)); // 1 day in the future
  user.LastDeviceToken = deviceToken;
  // Do not reset LastLogout here; it will be reset on logout

  await user.save();

  return res.json({
    message: "Logged in successfully",
    accessToken,
    user: {
      _id: user._id,
      username: user.Username,
      phoneNumber: user.PhoneNumber
    },
    deviceRestriction: {
      isRestricted: false,
      canLoginAfter: "Now"
    }
  });
});

exports.forgot_password = asyncHandler(async (req, res) => {
  const { phoneNumber } = req.body;
  const user = await Users.findOne({ PhoneNumber: phoneNumber });
  if (!user) return res.status(404).json({ message: "User not found." });

  const otp = generateOTP();
  user.ConfirmationCode = otp;
  await user.save();
  
  await axios({
    method: 'POST',
    url: process.env.TELESIGN_VOICE_URL,
    params: { phone_number: phoneNumber, verify_code: otp },
    headers: {
      'X-RapidAPI-Key': process.env.TELESIGN_API_KEY,
      'X-RapidAPI-Host': 'telesign-telesign-voice-verify-v1.p.rapidapi.com'
    }
  }).catch(error => console.error('Error sending OTP with Telesign:', error));

  res.status(200).json({ message: "OTP sent to your phone number for password reset." });
});


exports.post_reset_password = asyncHandler(async (req, res) => {
  const { phoneNumber, newPassword } = req.body;

  const user = await Users.findOne({ PhoneNumber: phoneNumber });
  if (!user) {
    return res.status(404).json({ message: "User not found." });
  }

  const hashedPassword = await bcrypt.hash(newPassword, 10);
  user.Password = hashedPassword;
  await user.save();

  res.status(200).json({ message: "Your password has been reset successfully." });
});


// In your Node.js backend, adjust the logout controller to find the user by phoneNumber
exports.logout = asyncHandler(async (req, res) => {
  const { phoneNumber, deviceToken } = req.body; // Now expecting phoneNumber instead of userId
  
  // Validate phoneNumber is provided and is a string
  if (!phoneNumber || typeof phoneNumber !== 'string' || !phoneNumber.trim()) {
    return res.status(400).json({ message: 'Phone number must be provided.' });
  }

  try {
    // Use findOne to find the user by their phoneNumber
    const user = await Users.findOne({ PhoneNumber: phoneNumber.trim() });
    if (!user) {
      return res.status(404).json({ message: 'User not found.' });
    }

    user.LastLogout = new Date();
    user.LastDeviceToken = deviceToken;

    await user.save();

    console.log('User logged out:', user);
    res.status(200).json({ message: 'Logout successful.' });
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({ message: 'Error during logout.' });
  }
});





