const express = require('express');
const Subscription = require('../models/Subscription');
const router = express.Router();

// Add a subscription
router.post('/', async (req, res) => {
    try {
        const subscription = new Subscription(req.body);
        await subscription.save();
        res.status(201).send(subscription);
    } catch (error) {
        res.status(400).send(error);
    }
});

// Get all subscriptions
router.get('/', async (req, res) => {
    try {
        const subscriptions = await Subscription.find({}).populate('userId');
        res.status(200).send(subscriptions);
    } catch (error) {
        res.status(500).send(error);
    }
});

// Update a subscription by ID
router.patch('/:id', async (req, res) => {
    try {
        const subscription = await Subscription.findByIdAndUpdate(req.params.id, req.body, { new: true });
        if (!subscription) {
            return res.status(404).send();
        }
        res.send(subscription);
    } catch (error) {
        res.status(400).send(error);
    }
});

// Delete a subscription by ID
router.delete('/:id', async (req, res) => {
    try {
        const subscription = await Subscription.findByIdAndDelete(req.params.id);
        if (!subscription) {
            return res.status(404).send();
        }
        res.send(subscription);
    } catch (error) {
        res.status(500).send(error);
    }
});

module.exports = router;
