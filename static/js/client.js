(function() {

  $(function() {
    var socket;
    socket = io.connect('http://local.host');
    socket.on('distribute', function(data) {
      return $('#results').append('<div>' + data.from + ': ' + data.message + '</div>');
    });
    return $('#channel').on('submit', function(e) {
      var message;
      e.preventDefault & e.preventDefault();
      message = $('#message').val();
      socket.emit('send', {
        'message': message
      });
      return $('#results').append('<div>' + message + '</div>');
    });
  });

}).call(this);
