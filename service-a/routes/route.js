const express = require("express");
const router = express.Router();
const path = require('path');

router.get("/healthcheck", (req, res) => {
  return res.send("Healthcheck Path !");
});

router.get('/medical', function(req, res) {
  res.render('medical', { 
    service: process.env.SERVICE_1, 
    launchType: process.env.LAUNCH_TYPE
  });
});

router.get('/security', function(req, res) {
  res.render('security', { 
    service: process.env.SERVICE_2, 
    launchType: process.env.LAUNCH_TYPE 
  });
});

module.exports = router;