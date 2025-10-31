# Simple Node.js Application

A minimal Node.js application for AWS ECS.

## Requirements

- Node.js 20.0.0 or higher
- Docker

## Features

- **Express.js** framework
- **Health check endpoint** for ALB integration
- **Simple Docker container**

## API Endpoints

- `GET /` - Application information
- `GET /health` - Health check (for ALB)

## Docker Build

```bash
# Build the image
docker build -t ecs-nodejs-app .

# Run locally
docker run -p 3000:3000 ecs-nodejs-app
```

## Environment Variables

- `PORT` - Server port (default: 3000)

## Health Checks

The application includes a simple health check endpoint at `/health` that returns:

```json
{
  "status": "healthy"
}
```
