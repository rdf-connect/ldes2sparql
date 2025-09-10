# Start from a Node.js ready image
FROM node:lts-alpine
# Add bash (not included in the alpine base image)
RUN apk update && apk upgrade && apk add --update bash
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