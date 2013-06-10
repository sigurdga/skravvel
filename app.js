var conf = require('./settings.js');
var routes = require('./routes.js');
var express = require('express');
var connectredis = require('connect-redis');
var connect = require('connect');
var socketio = require('socket.io');
var irc = require('irc');
var _ = require('underscore');
var mongoose = require('mongoose');
var cookie = require('cookie');
var passport = require('passport');
var GoogleStrategy = require('passport-google-oauth').OAuth2Strategy;

var redisstore = connectredis(express);
var sessionstore = new redisstore();

var Schema = mongoose.Schema;
var UserSchema = new Schema({});
var User;

passport.serializeUser(function(user, done) {
    console.log("serialize");
  done(null, user);
});

passport.deserializeUser(function(obj, done) {
    console.log("deserialize");
  done(null, obj);
});

passport.use(new GoogleStrategy({
    clientID: conf.google.clientId,
    clientSecret: conf.google.clientSecret,
    callbackURL: "http://localhost:3001/auth/google/callback"
  },
  function(accessToken, refreshToken, profile, done) {
    // asynchronous verification, for effect...
    process.nextTick(function () {

      // To keep the example simple, the user's Google profile is returned to
      // represent the logged-in user. In a typical application, you would want
      // to associate the Google account with a user record in your database,
      // and return that user instead.
      return done(null, profile);
    });
  }
));


mongoose.model('User', UserSchema);
mongoose.connect('mongodb://localhost/skravvel');
User = mongoose.model('User');

var connections = {};

var app = require('express')();
var server = require('http').createServer(app);
var io = require('socket.io').listen(server);

app.configure(function () {
    app.set('views', __dirname + '/views');
    app.set('view engine', 'jade');
    app.set('view options', {layout: false});
    app.use(express.bodyParser());
    app.use(express.static(__dirname + '/static'));
    app.use(express.cookieParser());
    app.use(express.session({secret: conf.secret, store: sessionstore}));
    app.use(passport.initialize());
    app.use(passport.session());
    app.use(app.router);
});

app.get('/', routes.index);
app.get('/auth/google',
        passport.authenticate('google',
                              { scope: ['https://www.googleapis.com/auth/userinfo.profile',
                                  'https://www.googleapis.com/auth/userinfo.email'] }),
                                  function(req, res){
                                  // function will not be called.
                                  });

app.get('/auth/google/callback',
  passport.authenticate('google', { failureRedirect: '/login' }),
  function(req, res) {
    res.redirect('/');
  });

app.get('/logout', function(req, res){
  req.logout();
  res.redirect('/');
});

server.listen(conf.port);

io.set('authorization', function (req, callback) {
    if (req.headers.cookie) {
        req.cookie = connect.utils.parseSignedCookies(cookie.parse(decodeURIComponent(req.headers.cookie)),conf.secret);
        req.sessionID = req.cookie['connect.sid'];
        req.sessionStore = sessionstore;
        console.log(req.sessionID);
        sessionstore.get(req.sessionID, function(err, session) {
            if (err || !session) {
                return callback('No session', false);
            } else {
                req.session = new connect.middleware.session.Session(req, session);
                return callback(null, true);
            }
        });
    } else {
        return callback('No cookie', false);
    }
});

var connections = {};

io.sockets.on('connection', function (socket) {
    var passport = socket.handshake.session.passport;

    if (passport.user) {
        var username = passport.user.displayName.replace(/\W/g, '');
        console.log(username);
        if (username){
            if (!_.has(connections, username)) {
                connections[username] = new irc.Client('oslo.irc.no', username);
                console.log("connected " + username);
            }

            console.log(connections[username]);
            socket.join(username);
            channels = _.map(connections[username].chans, function(object, key) {
                return key.replace(/^#/, '');
            });
            socket.emit('channels', {channels: channels});
        }
    }

    socket.on('say', function (data) {
        console.log(data.channel);
        console.log(data.message);

        var passport = socket.handshake.session.passport;
        var username;

        if (passport.user) {
            username = passport.user.displayName.replace(/\W/g, '');
        }
        if (username) {
            connections[username].say("#" + data.channel, data.message);
        }
    });

    socket.on('joinchannel', function (data) {
        console.log("join");
        console.log(data.channel);
        var passport = socket.handshake.session.passport;
        var username;

        if (passport.user) {
            username = passport.user.displayName.replace(/\W/g, '');
        }
        if (username) {
            console.log(username);
            connections[username].join("#" + data.channel);
            connections[username].addListener('message#' + data.channel, function (from, message) {
                console.log(data.channel);
                console.log(from);
                console.log(message);
                io.sockets.in(username).emit('distribute', {channel: data.channel, from:from, message: message});
            });
        }
    });
});
