const mongoose = require('mongoose');
const { DateTime } = require("luxon");
const Schema = mongoose.Schema;

const userSchema = new Schema({
  Username: { type: String, required: true, unique: true },
  Password: { type: String, required: true },
  isAdmin: { type: Boolean, default: false },
  PhoneNumber: { type: String, required: true, unique: true },
  IsPhoneVerified: { type: Boolean, default: false }, // To track if the phone number has been verified
  ConfirmationCode: { type: String }, // For storing the verification code
  ConfirmationCodeExpires: { type: Date }, // For storing the expiration time of the verification code
  LastDeviceToken: { type: String, default: "" }, 
  LastLogout: { type: Date },
  created_at: { type: Date, default: Date.now }
});

// Virtual for formatting the created_at date
userSchema.virtual("Date_formatted").get(function() {
  const date = DateTime.fromJSDate(this.created_at).setZone("local");

  const day = date.day;
  const month = date.toFormat('LLL'); // Format the month as a short name, e.g., "Oct"
  const year = date.year;
  
  let daySuffix = 'th';
  const j = day % 10,
        k = day % 100;
        
  if (j == 1 && k != 11) {
      daySuffix = "st";
  }
  if (j == 2 && k != 12) {
      daySuffix = "nd";
  }
  if (j == 3 && k != 13) {
      daySuffix = "rd";
  }

  return `${month} ${day}${daySuffix}, ${year}`;
});

const User = mongoose.model('User', userSchema);

module.exports = User;
