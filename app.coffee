conf = require './conf'
express = require 'express'

redis = require 'redis'
connectredis = require 'connect-redis'

#redisstore = connectredis(express)
#sessionstore = new redisstore()

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

app = express.createServer express.bodyParser(),
  express.static(__dirname + "/public"),
  express.cookieParser(),
  express.session secret: conf.secret#, store: sessionstore
  mongooseAuth.middleware()

app.configure  () ->
  app.set('views', __dirname + '/views')
  app.set('view engine', 'jade')

app.get '/', (req, res) ->
  res.render('home')

app.get '/logout', (req, res) ->
  req.logout()
  res.redirect('/')

mongooseAuth.helpExpress(app)

app.listen(3000)
console.log "Running"
