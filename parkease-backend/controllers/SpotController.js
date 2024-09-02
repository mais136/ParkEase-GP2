const asyncHandler = require('express-async-handler');
const Spot = require('../models/ParkingSpots');
const axios = require('axios');
const Reservation = require('../models/Reservation');
const mongoose = require('mongoose');
const QRCode = require('qrcode');

const updateSpotAvailability = async (spotId, session) => {
  try {
    const spot = await Spot.findById(spotId).session(session);
    if (!spot) throw new Error('Spot not found');
    const reservations = await Reservation.find({ spotId, status: { $in: ['reserved', 'checked-in'] } }).session(session);
    const evReservations = reservations.filter(r => r.spotType === 'ev').length;
    const standardReservations = reservations.filter(r => r.spotType === 'standard').length;

    spot.evSpotsAvailable = spot.evSpots - evReservations;
    spot.standardSpotsAvailable = spot.standardSpots - standardReservations;

    await spot.save({ session });
    console.log(`Availability updated for spot: ${spotId}`);
  } catch (error) {
    console.error(`Error updating availability for spot ${spotId}: ${error}`);
    throw error;
  }
};

exports.deleteReservation = asyncHandler(async (req, res) => {
  const { reservationId } = req.params;

  console.log(`Attempting to delete reservation with ID: ${reservationId}`);

  if (!mongoose.Types.ObjectId.isValid(reservationId)) {
    console.log('Invalid reservation ID.');
    return res.status(400).send('Invalid reservation ID.');
  }

  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const reservation = await Reservation.findById(reservationId).session(session);
    if (!reservation) {
      console.log(`Reservation with ID: ${reservationId} not found.`);
      await session.abortTransaction();
      session.endSession();
      return res.status(404).send('Reservation not found.');
    }

    await Reservation.findByIdAndDelete(reservationId).session(session);
    await updateSpotAvailability(reservation.spotId, session);

    await session.commitTransaction();
    session.endSession();

    console.log(`Reservation with ID: ${reservationId} deleted successfully.`);
    res.status(200).send('Reservation deleted successfully.');
  } catch (error) {
    console.error('Failed to delete reservation:', error);
    if (session.inTransaction()) {
      await session.abortTransaction();
    }
    session.endSession();
    res.status(500).send('Internal Server Error');
  }
});

exports.listSpots = asyncHandler(async (req, res) => {
  try {
    const userId = req.user._id; // Get the userId from the protected route
    let spots = await Spot.find({});

    const spotsWithReservationInfo = await Promise.all(
      spots.map(async (spot) => {
        const spotObject = spot.toObject();

        const reservation = await Reservation.findOne({
          spotId: spot._id,
          userId: userId,
          status: { $in: ['reserved', 'checked-in'] },
        });

        if (reservation) {
          spotObject.reservationStatus = reservation.status;
          spotObject.reservedByCurrentUser = true;
          spotObject.reservationId = reservation._id; // Include reservationId
        } else {
          spotObject.reservationStatus = null;
          spotObject.reservedByCurrentUser = false;
          spotObject.reservationId = null;
        }

        if (!spotObject.isEVChargingAvailable) {
          delete spotObject.evSpots;
          delete spotObject.evSpotsAvailable;
        }

        return spotObject;
      })
    );

    res.json(spotsWithReservationInfo);
  } catch (error) {
    console.error('Error listing spots:', error);
    res.status(500).json({ message: 'Error fetching spots.' });
  }
});

async function generateQRCode(text) {
  try {
    return await QRCode.toDataURL(text);
  } catch (err) {
    console.error(err);
    throw new Error('Failed to generate QR Code');
  }
}

const deleteIfNotCheckedIn = async (reservationId) => {
  const reservation = await Reservation.findById(reservationId);
  if (reservation && reservation.status === 'reserved') {
    const currentTime = new Date();
    const timeDifference = currentTime - reservation.createdAt;
    const twentyMinutes = 20 * 60 * 1000;
    if (timeDifference > twentyMinutes) {
      console.log(`Deleting reservation ${reservationId} due to no check-in.`);
      await Reservation.findByIdAndDelete(reservationId);
      await updateSpotAvailability(reservation.spotId);
    }
  }
};

exports.getCurrentUserReservation = asyncHandler(async (req, res) => {
  const userId = req.user._id;

  try {
    const reservation = await Reservation.findOne({ userId, status: { $in: ['reserved', 'checked-in'] } });
    
    if (!reservation) {
      return res.status(404).json({ message: 'No active reservation found for the user.' });
    }

    res.json(reservation);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching current reservation.', error });
  }
});

exports.reserveSpot = asyncHandler(async (req, res) => {
  const { spotId, spotType } = req.body;

  if (!spotId || !spotType) {
    return res.status(400).json({ message: 'Spot ID and type must be provided' });
  }

  const userId = req.user._id;
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const spot = await Spot.findById(spotId).session(session);
    if (!spot) {
      await session.abortTransaction();
      session.endSession();
      return res.status(404).json({ message: 'Spot not found' });
    }

    let availableSpots = spotType === 'ev' ? spot.evSpotsAvailable : spot.standardSpotsAvailable;
    if (availableSpots <= 0) {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({ message: `No ${spotType} spots available` });
    }

    const existingReservation = await Reservation.findOne({ userId, status: 'reserved' }).session(session);
    if (existingReservation) {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({ message: 'You already have an active reservation' });
    }

    const reservation = new Reservation({
      spotId,
      userId,
      spotType,
      status: 'reserved',
      createdAt: new Date()
    });
    await reservation.save({ session });

    spotType === 'ev' ? spot.evSpotsAvailable-- : spot.standardSpotsAvailable--;
    await spot.save({ session });

    const qrCodeData = reservation._id.toString();
    const qrCode = await generateQRCode(qrCodeData);

    reservation.qrCode = qrCode;
    await reservation.save({ session });
    await session.commitTransaction();
    session.endSession();

    setTimeout(() => deleteIfNotCheckedIn(reservation._id), 20 * 60 * 1000);

    return res.status(201).json({ message: 'Reservation successful', reservation });
  } catch (error) {
    console.error('Reservation error:', error);
    await session.abortTransaction();
    session.endSession();
    return res.status(500).json({ message: 'Error processing reservation' });
  }
});

exports.checkIn = asyncHandler(async (req, res) => {
  const { reservationId } = req.body;

  console.log(`Attempting to check-in with Reservation ID: ${reservationId}`);

  if (!reservationId) {
    return res.status(400).json({ message: 'Reservation ID is required.' });
  }

  const reservation = await Reservation.findById(reservationId);
  if (!reservation || reservation.status !== 'reserved') {
    console.log(`Reservation with ID: ${reservationId} not found or already checked in.`);
    return res.status(404).json({ message: 'Invalid or inactive reservation.' });
  }

  reservation.status = 'checked-in';
  reservation.checkInTime = new Date();
  await reservation.save();

  await updateSpotAvailability(reservation.spotId);

  res.json({ message: 'Check-in successful.', reservation });
});

exports.checkOut = asyncHandler(async (req, res) => {
  const { reservationId } = req.body;

  console.log(`Attempting to check-out with Reservation ID: ${reservationId}`);

  if (!reservationId) {
    return res.status(400).json({ message: 'Reservation ID is required.' });
  }

  const reservation = await Reservation.findById(reservationId);
  if (!reservation || reservation.status !== 'checked-in') {
    console.log(`Reservation with ID: ${reservationId} not found or not checked in.`);
    return res.status(404).json({ message: 'Invalid or inactive reservation.' });
  }

  reservation.status = 'cancelled';
  reservation.checkoutTime = new Date();
  await reservation.save();

  await updateSpotAvailability(reservation.spotId);

  res.json({ message: 'Check-out successful.' });
});

async function getCoordinatesForAddress(address) {
  const apiKey = process.env.GOOGLE_MAPS_API_KEY;
  if (!apiKey) {
    throw new Error('Google Maps API key not configured.');
  }

  try {
    const encodedAddress = encodeURIComponent(address);
    const response = await axios.get(`https://maps.googleapis.com/maps/api/geocode/json?address=${address}&key=${apiKey}`);
    const data = response.data;

    if (!data || data.status === 'ZERO_RESULTS') {
      throw new Error('Could not find location for the specified address.');
    }

    const coordinates = data.results[0].geometry.location;
    return coordinates;
  } catch (error) {
    console.error('Error fetching coordinates:', error);
    throw new Error('Error fetching coordinates for address.');
  }
}

exports.createSpot = asyncHandler(async (req, res) => {
  const { name, address, standardSpot, evSpots, isEVChargingAvailable } = req.body;

  if (!req.user || !req.user.isAdmin) {
    return res.status(403).json({ message: 'Access denied. Admins only.' });
  }

  try {
    const coordinates = await getCoordinatesForAddress(address);

    const spot = new Spot({
      name,
      address,
      latitude: coordinates.lat,
      longitude: coordinates.lng,
      standardSpot,
      standardSpotAvailable: standardSpot,
      evSpots,
      evSpotsAvailable: evSpots,
      isEVChargingAvailable,
      createdBy: req.user._id,
    });

    await spot.save();
    res.status(201).json(spot);
  } catch (error) {
    console.error('Error creating spot:', error);
    res.status(500).json({ message: 'Error creating spot.' });
  }
});

exports.updateSpot = asyncHandler(async (req, res) => {
  if (!req.user || !req.user.isAdmin) {
    return res.status(403).json({ message: 'Access denied. Admins only.' });
  }

  try {
    const spot = await Spot.findById(req.params.id);
    if (!spot) {
      return res.status(404).json({ message: 'Spot not found.' });
    }

    const { name, standardSpot, evSpots, isEVChargingAvailable } = req.body;
    const standardSpotAvailable = spot.standardSpotAvailable - (spot.standardSpot - standardSpot);
    let evSpotsAvailable = spot.evSpotsAvailable - (spot.evSpots - evSpots);

    let updatedIsEVChargingAvailable = isEVChargingAvailable;
    if (evSpots === 0) {
      evSpotsAvailable = 0;
      updatedIsEVChargingAvailable = false;
    }

    spot.set({
      name,
      standardSpot,
      evSpots,
      isEVChargingAvailable: updatedIsEVChargingAvailable,
      standardSpotAvailable: Math.max(0, standardSpotAvailable),
      evSpotsAvailable: Math.max(0, evSpotsAvailable)
    });

    const updatedSpot = await spot.save();
    res.json(updatedSpot);
  } catch (error) {
    console.error('Error updating spot:', error);
    res.status(500).json({ message: 'Error updating spot.' });
  }
});

exports.deleteSpot = asyncHandler(async (req, res) => {
  if (!req.user || !req.user.isAdmin) {
    return res.status(403).json({ message: 'Access denied. Admins only.' });
  }

  try {
    const result = await Spot.findByIdAndDelete(req.params.id);
    if (!result) {
      return res.status(404).json({ message: 'Spot not found.' });
    }
    res.json({ message: 'Spot removed.' });
  } catch (error) {
    console.error('Error deleting spot:', error);
    res.status(500).json({ message: 'Error removing spot.' });
  }
});
