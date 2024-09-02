const mongoose = require('mongoose');

const reservationSchema = new mongoose.Schema({
  spotId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Spot',
    required: true
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  spotType: {
    type: String,
    required: true
  },
  status: {
    type: String,
    enum: ['reserved', 'checked-in', 'cancelled'],
    default: 'reserved'
  },
  qrCode: {
    type: String
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  checkInTime: {
    type: Date
  },
  checkoutTime: {
    type: Date
  }
});

module.exports = mongoose.model('Reservation', reservationSchema);
