FROM node:18-alpine
WORKDIR /app
# Copy only backend files
COPY backend/package*.json ./
RUN npm install
COPY backend/server.js ./
EXPOSE 3000
CMD ["node", "server.js"]
