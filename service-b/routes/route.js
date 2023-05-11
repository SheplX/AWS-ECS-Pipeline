const express = require("express");
const router = express.Router();
const path = require('path');

router.get("/healthcheck", (req, res) => {
  return res.send("Healthcheck Path !");
});

router.get('/finance', function(req, res) {
  res.render('finance', { 
    service: process.env.SERVICE_1, 
    launchType: process.env.LAUNCH_TYPE
  });
});

router.get('/payment', function(req, res) {
  res.render('payment', { 
    service: process.env.SERVICE_2, 
    launchType: process.env.LAUNCH_TYPE 
  });
});

module.exports = router;