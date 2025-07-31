const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const routes = require('./index');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Routes
app.use('/api', routes);

// Test route
app.get('/', (req, res) => {
  res.send('Bienvenue sur le serveur DALILI API');
});

// Start server
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});