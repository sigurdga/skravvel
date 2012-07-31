$ ->
    socket = io.connect 'http://local.host'
    socket.on 'distribute', (data) ->
      channel = $('#' + data.channel)
      if channel.length
        $('#' + data.channel + ' .results').append('<div>' + data.from + ': ' + data.message + '</div>')
        results = $('#' + data.channel + ' .results')
        results.animate({scrollTop: results[0].scrollHeight}, 1000)

    socket.on 'channels', (data) ->
      for channel in data.channels
        channel_div = $('#' + channel)
        if not channel_div.length
          $('#channels').append '<li><a href="#' + channel+ '" id="tab-' + channel + '" data-toggle="tab">' + channel + '</a></li>'
          $('#screens').append '<div class="tab-pane" id="' + channel + '"><div class="results"></div></form></div>'
      $('#channels a:last').tab('show')
      if data.channels.length
        $('#say').removeClass("hide")
 
    $('#say').on 'submit', (e) ->
        e.preventDefault & e.preventDefault()
        #if socket.handshake.session.auth
        #auth = socket.handshake.session.auth
        #if auth.loggedIn and auth.twitter and auth.twitter.user.name
        #user = auth.twitter.user.name.replace(/\W/g, '')
        user = "you"
        message = $('#message').val()
        $('#message').val("")
        active = $('#screens div.active')
        channel = active.attr('id')
        socket.emit 'say',
          message: message
          channel: channel

        $("#" + channel + ' .results').append('<div>' + user + ': ' + message + '</div>')

    $('#channeljoin').on 'click', (e) ->
        e.preventDefault & e.preventDefault()
        channel = $('#joinchannel').val()
        $('#joinchannel').val("")
        if not $('#' + channel).length
          $('#channels').append '<li><a href="#' + channel+ '" id="tab-' + channel + '" data-toggle="tab">' + channel + '</a></li>'
          $('#screens').append '<div class="tab-pane" id="' + channel + '"><div class="results"></div></form></div>'
          $('#tab-' + channel).tab 'show'

          socket.emit('joinchannel', {channel: channel})
          $('#say').removeClass("hide")

        else
          $('#tab-' + channel).tab 'show'
