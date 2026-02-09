# Simple dev Dockerfile for Dashboard
FROM node:18-alpine

WORKDIR /app

# Install dependencies (including dev)
COPY package*.json ./
RUN npm install

# Copy source
COPY . .

# Expose Vite default port
EXPOSE 5173

# Run in dev mode, exposing to network
CMD ["npm", "run", "dev", "--", "--host"]
