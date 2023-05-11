require("dotenv/config");
const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const app = express();
const morgan = require("morgan");
const path = require('path');
const router = require('./routes/route.js');
app.enable("trust proxy");
app.use(morgan("dev"));
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.json({ limit: "50mb" }));
app.use(express.urlencoded({ extended: true }));
app.use(express.urlencoded({ limit: "50mb", extended: true }));
app.use((req, res, next) => {
    res.setHeader("Access-Control-Allow-Origin", "*");
    res.setHeader("Access-Control-Allow-Headers", "*");
    next();
});
app.use(router);
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use('/', router);

const port = process.env.PORT || 3000;
const server = app.listen(port, () => console.log(`App listening at port ${port}`));
module.exports = server;

// const dotenv = require('dotenv');
// dotenv.config();
