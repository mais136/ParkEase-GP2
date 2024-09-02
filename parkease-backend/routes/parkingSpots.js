const express = require('express');
const router = express.Router();
const spotController = require('../controllers/SpotController');
const { protect, admin } = require('../middleware/authMiddleware');

// Define routes
router.post('/reserve-spot', protect, spotController.reserveSpot);
router.put('/check-in', protect, spotController.checkIn);
router.post('/create-spot', protect, admin, spotController.createSpot);
router.get('/list-spots', protect, spotController.listSpots); // Protect this route
router.put('/update-spot/:id', protect, admin, spotController.updateSpot);
router.delete('/delete-spot/:id', protect, admin, spotController.deleteSpot);
router.delete('/delete-reservation/:reservationId', protect, spotController.deleteReservation);
router.put('/check-out', protect, spotController.checkOut);
router.get('/current', protect, spotController.getCurrentUserReservation);

module.exports = router;
