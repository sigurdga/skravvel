exports.index = (req, res) ->
  console.log ">___"
  console.log req.user
  res.render 'index',
    title: 'IRC'
