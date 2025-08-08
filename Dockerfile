# Start from a Node.js ready image
FROM node:lts-alpine
# Create the folder for keeping the state
RUN mkdir -p /state
RUN mkdir -p /performance
# Set current working directory
WORKDIR /rdfc-pipeline
# Copy configuration files
COPY . .
# Install dependencies
RUN npm ci
# Set command run by the container
RUN chmod +x run.sh
ENTRYPOINT [ "./run.sh" ]