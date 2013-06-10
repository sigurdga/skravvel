exports.index = function (req, res) {
    res.render('index', {title: 'IRC', user: req.user});
};
