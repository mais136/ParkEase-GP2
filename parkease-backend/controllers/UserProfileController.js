const Users = require("../models/User")
const asyncHandler = require("express-async-handler")
const Reservation = require("../models/User")

// Profile retrieval remains unchanged
exports.profile = asyncHandler(async (req, res) => {
    try {
        const user = await Users.findById(req.user._id);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }
        res.status(200).json({ profile: user });
    } catch (error) {
        // Log the error for debugging purposes
        console.error('Error fetching user profile:', error);
        // Respond with a generic server error message
        res.status(500).json({ message: 'Internal Server Error' });
    }
});

exports.updateUsername = asyncHandler(async (req, res) => {
  const { newUsername } = req.body;
  const user = await Users.findById(req.user._id);

  if (!user) {
      return res.status(404).json({ message: 'User not found' });
  }

  if (newUsername && newUsername !== user.Username) {
      const usernameExists = await Users.findOne({ Username: newUsername });
      if (usernameExists) {
          return res.status(409).json({ message: 'Username already exists' });
      }
      user.Username = newUsername;
  }

  await user.save();
  res.status(200).json({ message: 'Username updated successfully' });
});

// Update Phone Number
exports.updatePhoneNumber = asyncHandler(async (req, res) => {
  const { newPhoneNumber } = req.body;
  const user = await Users.findById(req.user._id);

  if (!user) {
      return res.status(404).json({ message: 'User not found' });
  }

  if (newPhoneNumber && newPhoneNumber !== user.PhoneNumber) {
      // Additional checks or actions can be performed here
      user.PhoneNumber = newPhoneNumber;
  }

  await user.save();
  res.status(200).json({ message: 'Phone number updated successfully' });
});
