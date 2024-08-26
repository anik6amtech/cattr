# Stage 1: PHP & Node.js Build Stage
FROM php:8.3-fpm AS php-build

# Install dependencies for PHP
RUN apt-get update && apt-get install -y \
    git \
    zip \
    unzip \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libwebp-dev \
    && docker-php-ext-install pdo_mysql zip

# Configure and install GD extension
RUN docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg \
    --with-webp \
    && docker-php-ext-install gd

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy project files
COPY . .

# Install PHP dependencies
RUN composer install

# Install Node.js and Yarn
RUN apt-get update && apt-get install -y curl gnupg \
    && curl -sL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && npm install --global yarn

# Install Node.js dependencies and build assets
COPY package.json yarn.lock ./
RUN yarn
# Stage 2: Nginx
FROM nginx:alpine

# Copy built files from the build stage
COPY --from=php-build /var/www/html /usr/share/nginx/html

# Copy custom nginx configuration
COPY default.conf /etc/nginx/conf.d/default.conf

# Expose port 80 for incoming web traffic
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]

# Stage 3: Laravel Setup & Migrate
FROM php-build AS laravel-setup

# Set working directory
WORKDIR /var/www/html

# Start Laravel server
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]

# Expose the application port
EXPOSE 8000
