# Simple Node.js Dockerfile
FROM node:20-alpine

# Install OpenSSL for certificate generation
RUN apk add --no-cache openssl

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy application code
COPY . .

# Set certificate password as build argument
ARG certificatePassword=defaultpassword

# Configure SSL and publish
RUN openssl genrsa -des3 -passout pass:${certificatePassword} -out server.key 2048 \
    && openssl rsa -passin pass:${certificatePassword} -in server.key -out server.key \
    && openssl req -sha256 -new -key server.key -out server.csr -subj '/CN=localhost' \
    && openssl x509 -req -sha256 -days 365 -in server.csr -signkey server.key -out server.crt

# Expose HTTPS port
EXPOSE 443

# Start the application
CMD ["npm", "start"]