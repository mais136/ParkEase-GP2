const express = require('express');
const authController = require("../controllers/AuthController");
const router = express.Router();

router.post('/register', authController.register);
router.post('/confirm-phone', authController.confirmUserPhone);
router.post('/login', authController.login);
router.post('/forgot-password', authController.forgot_password);
router.post('/reset-password', authController.post_reset_password);
router.post('/logout', authController.logout);

module.exports = router;
