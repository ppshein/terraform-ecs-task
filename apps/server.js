const express = require("express");
const https = require("https");
const fs = require("fs");

const app = express();
const PORT = process.env.PORT || 443;

// Health check endpoint (required for ALB health checks)
app.get("/health", (req, res) => {
  res.status(200).json({
    status: "healthy",
  });
});

// Root endpoint
app.get("/", (req, res) => {
  res.status(200).json({
    message: "Hello from ECS Node.js App with HTTPS",
    port: PORT,
    protocol: "HTTPS",
  });
});

// HTTPS server configuration
const options = {
  key: fs.readFileSync("/app/server.key"),
  cert: fs.readFileSync("/app/server.crt"),
};

// Start HTTPS server
https.createServer(options, app).listen(PORT, "0.0.0.0", () => {
  console.log(`HTTPS Server running on port ${PORT}`);
});

module.exports = app;
