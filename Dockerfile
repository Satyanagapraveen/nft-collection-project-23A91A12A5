# Use official lightweight Node.js image
FROM node:18-alpine

# Set working directory inside container
WORKDIR /app

# Copy package.json and package-lock.json first
# This allows Docker to cache npm install layer for faster builds
COPY package*.json ./

# Install dependencies (Hardhat, test frameworks, etc.)
RUN npm install

# Copy rest of the project into container
COPY . .

# Compile the smart contracts
RUN npx hardhat compile

# Default command: run the full test suite
CMD ["npx", "hardhat", "test"]
