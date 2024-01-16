### Stage 1 -- Node.js
### ==================

# Use an official Node.js runtime as a parent image
FROM node:18 as staticlayer

# Set the working directory to /app
WORKDIR /app

# Copy package.json and package-lock.json to the working directory
COPY package*.json ./
COPY Gruntfile.js ./

# Copy the rest of the application code to the working directory (note that we
# need to do this here so that we have access to the static files to build)
COPY src ./src

# Install Node.js dependencies and run postinstall script
RUN npm install

### Stage 2 -- Python
### =================

# Use an official Python runtime as a parent image
FROM python:3.10

# Set the working directory to /app
WORKDIR /app

# Copy the dependencies file to the working directory
COPY app-requirements.txt .
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Prepare the static files
COPY --from=staticlayer /app/src ./src
ARG SHAREABOUTS_FLAVOR=cycle1
RUN python src/manage.py collectstatic

# Expose the port the app runs on
ENV PORT=8000
EXPOSE $PORT

# Start the web server with gunicorn
CMD ["/bin/bash", "-c", "gunicorn -b 0.0.0.0:$PORT -w 4 src.project.wsgi"]
