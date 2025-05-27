# Start from a Node.js ready image
FROM node:lts-alpine
# Set current working directory
WORKDIR /rdfc-pipeline
# Copy configuration files
COPY . .
# Install dependencies
RUN npm ci
# Set command run by the container
RUN chmod +x run.sh
ENTRYPOINT [ "./run.sh" ]