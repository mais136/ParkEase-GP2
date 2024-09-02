require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const passport = require('passport');
const cors = require('cors');
const path = require('path');
const cookieParser = require('cookie-parser');
const logger = require('morgan');
const createError = require('http-errors');
require('dotenv').config();
const http = require('http');
const { Server } = require('socket.io');

// Passport Config
require("./passport-config")(passport);

const app = express();
const server = http.createServer(app);
const io = new Server(server);

app.set('socketio', io);

// MongoDB Connection
mongoose.set("strictQuery", false);
const mongoDB = process.env.MONGO_URI;
mongoose.connect(mongoDB)
  .then(() => console.log("MongoDB connected"))
  .catch(err => console.log(err));


app.use(cors({
  origin: function(origin, callback) {
    if (!origin) return callback(null, true);
    
    return callback(null, true);
  },
  credentials: true
}));

app.use(logger('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));
app.use(passport.initialize());

const authRouter = require('./routes/authRouter');
const usersRouter = require('./routes/UsersRouter');
const parkingSpotsRouter = require('./routes/parkingSpots');
const subscriptionsRouter = require('./routes/subscriptions');

app.use('/api/auth', authRouter);
app.use('/api/users', usersRouter);
app.use('/api/spots', parkingSpotsRouter);
app.use('/api/subscriptions', subscriptionsRouter);

app.use(function(req, res, next) {
  next(createError(404));
});

app.use(function(err, req, res, next) {
  const response = {
    message: err.message,
    error: req.app.get('env') === 'development' ? err : {}
  };
  res.status(err.status || 500).json(response);
});

const PORT = process.env.PORT || 3001;
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
