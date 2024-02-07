# Use the latest Ubuntu base image
FROM ubuntu:latest

# Update package lists and install necessary packages
RUN apt-get update && apt-get install -y \
    nginx \
    nodejs \
    npm \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install PM2 globally using npm
RUN npm install pm2 -g

# Create a directory for the application
WORKDIR /app

# Copy the sample "Hello World" application files into the container
COPY . .

# Install dependencies
RUN npm install

# Expose the port on which the Node.js application will run
EXPOSE 3000

# Configure Nginx
RUN rm /etc/nginx/sites-enabled/default
COPY nginx.conf /etc/nginx/sites-enabled/default

# Start Nginx and the Node.js application using PM2 when the container starts
CMD service nginx start && pm2 start app.js --no-daemon

