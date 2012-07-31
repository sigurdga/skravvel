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
      myHostname: 'http://localhost:3000'
      appId: conf.google.clientId
      appSecret: conf.google.clientSecret
      redirectPath: '/'
      scope: 'https://www.google.com/m8/feeds'

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
      console.log auth.twitter
      username = auth.twitter.user.name.replace(/\W/g, '')
      if !_.has(connections, username)
        connections[username] = new irc.Client 'oslo.irc.no', username 
        #connections[username] = "IKFEA"
        console.log "created for " + username
      
      console.log connections[username]
      socket.join(username)
      channels = _.map connections[username].chans, (obj, key) ->
        return key.replace /^#/, ''

      socket.emit 'channels',
        channels: channels

  socket.on 'say', (data) ->
    console.log data.message
    console.log data.channel
    auth = socket.handshake.session.auth
    if auth and auth.twitter.user.name
      user = auth.twitter.user.name.replace(/\W/g, '')
      console.log user
      connections[user].say("#" + data.channel, data.message)

  socket.on 'joinchannel', (data) ->
    console.log "join"
    console.log data.channel
    if socket.handshake.session.auth
      auth = socket.handshake.session.auth
      if auth.loggedIn and auth.twitter and auth.twitter.user.name
        user = auth.twitter.user.name.replace(/\W/g, '')
        console.log user
        #socket.join(user)
        io.sockets.in(user).emit 'distribute',
          channel: data.channel
          message: "Velkommen"
          from: "OPS"
        connections[user].join("#" + data.channel)
        connections[user].addListener 'message#' + data.channel, (from, message) ->
          console.log(data.channel)
          console.log(from)
          console.log message
          io.sockets.in(user).emit 'distribute',
            channel: data.channel
            from: from
            message: message
