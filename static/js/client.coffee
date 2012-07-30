$ ->
    socket = io.connect 'http://localhost'
    socket.on 'distribute', (data) ->
        $('#results').append('<div>' + data.from + ': ' + data.message + '</div>')
 
    $('#channel').on 'submit', (e) ->
        e.preventDefault & e.preventDefault()
        message = $('#message').val()
        socket.emit 'send', {'message': message}
        $('#results').append('<div>' + message + '</div>')
