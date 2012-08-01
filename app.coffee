conf = require './conf'
routes = require './routes'

express = require 'express'
connectredis = require 'connect-redis'

connect = require 'connect'
socketio = require 'socket.io'

irc = require 'irc'

_ = require 'underscore'

redisstore = connectredis(express)
sessionstore = new redisstore()

mongoose = require('mongoose')
Schema = mongoose.Schema
ObjectId = mongoose.SchemaTypes.ObjectId

UserSchema = new Schema({})
User

mongooseAuth = require 'mongoose-auth'

UserSchema.plugin mongooseAuth,
  everymodule:
    everyauth:
      User: () ->
        return User
  twitter:
    everyauth:
      myHostname: 'http://local.host:3000'
      consumerKey: conf.twitter.consumerKey
      consumerSecret: conf.twitter.consumerSecret
      redirectPath: '/'
  google:
    everyauth:
      myHostname: 'http://samklang.no:3000'
      appId: conf.google.clientId
      appSecret: conf.google.clientSecret
      scope: 'https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/userinfo.profile'
      redirectPath: '/'
  github:
    everyauth:
      myHostname: 'http://local.host:3000'
      appId: conf.github.clientId
      appSecret: conf.github.clientSecret
      redirectPath: '/'

# Adds login: String
mongoose.model('User', UserSchema)

mongoose.connect('mongodb://localhost/example')

User = mongoose.model('User')

connections = {}

app = express.createServer()

app.configure  () ->
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'jade'
  app.set 'view options', layout: false
  app.use express.bodyParser()
  app.use express.static __dirname + "/static"
  app.use express.cookieParser()
  app.use express.session secret: conf.secret, store: sessionstore
  app.use mongooseAuth.middleware()

app.get '/', routes.index

mongooseAuth.helpExpress app
io = socketio.listen app

app.listen(3000)
console.log "Running"

###########
# socket io
###########
#
# authorization
# req.sessionID is a name used internally by connect?

io.set 'authorization', (req, callback) ->
  if req.headers.cookie
    req.cookie = connect.utils.parseCookie req.headers.cookie
    req.sessionID = req.cookie['connect.sid']
    req.sessionStore = sessionstore
    sessionstore.get req.sessionID, (err, session) ->
      if err || !session
        callback 'No session', false
      else
        req.session = new connect.middleware.session.Session(req, session)
        callback null, true
  else
    return callback 'No cookie', false

io.sockets.on 'connection', (socket) ->
  console.log 'client connected'
  auth = socket.handshake.session.auth
  if auth && auth.loggedIn
    console.log auth.userId
    if auth.twitter
      username = auth.twitter.user.name
    else if auth.google
      username = auth.google.user.name
    if username
      user= username.replace(/\W/g, '')
      if !_.has(connections, user)
        connections[user] = new irc.Client 'oslo.irc.no', user
        console.log "created for " + user
      
      console.log connections[user]
      socket.join(user)
      channels = _.map connections[user].chans, (obj, key) ->
        return key.replace /^#/, ''

      socket.emit 'channels',
        channels: channels

  socket.on 'say', (data) ->
    console.log data.message
    console.log data.channel
    auth = socket.handshake.session.auth
    if auth.twitter
      username = auth.twitter.user.name
    else if auth.google
      username = auth.google.user.name
    if username
      user = username.replace(/\W/g, '')
      console.log user
      connections[user].say("#" + data.channel, data.message)

  socket.on 'joinchannel', (data) ->
    console.log "join"
    console.log data.channel
    auth = socket.handshake.session.auth
    if auth.twitter
      username = auth.twitter.user.name
    else if auth.google
      username = auth.google.user.name
    if username
      user = username.replace(/\W/g, '')
      console.log user
      connections[user].join("#" + data.channel)
      connections[user].addListener 'message#' + data.channel, (from, message) ->
        console.log(data.channel)
        console.log(from)
        console.log message
        io.sockets.in(user).emit 'distribute',
          channel: data.channel
          from: from
          message: message
