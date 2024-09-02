const mongoose = require('mongoose');

const spotSchema = new mongoose.Schema({
  name: { type: String, required: true },
  address: { type: String, required: true },
  latitude: { type: Number, required: true },
  longitude: { type: Number, required: true },
  evSpots: { type: Number, required: true },
  standardSpot: { type: Number, required: true },
  standardSpotAvailable: { type: Number, required: true },
  evSpotsAvailable: { type: Number, required: true },
  isEVChargingAvailable: { type: Boolean, default: false },
  reserved: { type: Boolean, default: false },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true }
}, {
  timestamps: true
});

spotSchema.virtual('totalSpots').get(function() {
  return this.standardSpot + this.evSpots;
});

spotSchema.virtual('totalAvailable').get(function() {
  return this.standardSpotAvailable + this.evSpotsAvailable;
});

spotSchema.set('toJSON', { virtuals: true });
spotSchema.index({ latitude: 1, longitude: 1 }, { "2dsphere": true });

module.exports = mongoose.model('ParkingSpots', spotSchema);
