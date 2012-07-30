$ ->
    socket = io.connect 'http://local.host'
    socket.on 'distribute', (data) ->
        $('#results').append('<div>' + data.from + '@' + data.channel + ': ' + data.message + '</div>')
 
    $('#channel').on 'submit', (e) ->
        e.preventDefault & e.preventDefault()
        message = $('#message').val()
        socket.emit 'send',
          message: message
          channel: 'strekmann'

        $('#results').append('<div>you@here: ' + message + '</div>')
    $('#modal-send').on 'click', (e) ->
        e.preventDefault & e.preventDefault()
        channel = $('#joinchannel').val()
        $('#joinchannel').val("")
        socket.emit 'join',
          channel: channel
