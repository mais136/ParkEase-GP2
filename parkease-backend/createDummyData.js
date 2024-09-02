const mongoose = require('mongoose');
const { DateTime } = require('luxon');
const ParkingSpot = require('./models/ParkingSpots');
const Reservation = require('./models/Reservation');
const User = require('./models/User');
require('dotenv').config();

const uri = process.env.MONGO_URI; // Replace with your MongoDB connection string
mongoose.connect(uri, { useNewUrlParser: true, useUnifiedTopology: true });

const createDummyData = async () => {
  try {
    await mongoose.connection.dropDatabase();

    // Create users
    const users = await User.insertMany([
      {
        Username: 'user1',
        Password: 'password1',
        isAdmin: true,
        PhoneNumber: '1234567890',
        IsPhoneVerified: true,
        ConfirmationCode: '123456',
        ConfirmationCodeExpires: DateTime.local().plus({ days: 1 }).toJSDate(),
        LastDeviceToken: 'token1',
        LastLogout: DateTime.local().minus({ days: 1 }).toJSDate()
      },
      {
        Username: 'user2',
        Password: 'password2',
        PhoneNumber: '0987654321',
        IsPhoneVerified: false,
        ConfirmationCode: '654321',
        ConfirmationCodeExpires: DateTime.local().plus({ days: 1 }).toJSDate(),
        LastDeviceToken: 'token2',
        LastLogout: DateTime.local().minus({ days: 2 }).toJSDate()
      }
    ]);

    // Create parking spots
    const spots = await ParkingSpot.insertMany([
      {
        name: 'Parking A',
        address: '123 Main St',
        latitude: 37.7749,
        longitude: -122.4194,
        evSpots: 5,
        standardSpot: 20,
        standardSpotAvailable: 20,
        evSpotsAvailable: 5,
        isEVChargingAvailable: true,
        createdBy: users[0]._id
      },
      {
        name: 'Parking B',
        address: '456 Elm St',
        latitude: 34.0522,
        longitude: -118.2437,
        evSpots: 10,
        standardSpot: 30,
        standardSpotAvailable: 25,
        evSpotsAvailable: 10,
        isEVChargingAvailable: true,
        createdBy: users[1]._id
      }
    ]);

    // Create reservations
    const reservations = await Reservation.insertMany([
      {
        spotId: spots[0]._id,
        userId: users[0]._id,
        spotType: 'standardSpot',
        status: 'reserved',
        qrCode: 'qr123',
        checkInTime: DateTime.local().minus({ hours: 1 }).toJSDate(),
        checkoutTime: DateTime.local().plus({ hours: 1 }).toJSDate()
      },
      {
        spotId: spots[1]._id,
        userId: users[1]._id,
        spotType: 'ev',
        status: 'checked-in',
        qrCode: 'qr456',
        checkInTime: DateTime.local().minus({ hours: 2 }).toJSDate(),
        checkoutTime: DateTime.local().plus({ hours: 2 }).toJSDate()
      }
    ]);

    console.log('Dummy data created successfully!');
    process.exit();
  } catch (error) {
    console.error('Error creating dummy data:', error);
    process.exit(1);
  }
};

createDummyData();
