# Use official PHP image with necessary extensions
FROM php:7.4-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    sqlite3 \
    libsqlite3-dev \
    zip \
    unzip

# Install PHP extensions
RUN docker-php-ext-install pdo_sqlite mbstring exif pcntl bcmath gd

# Copy env file
COPY .env.example .env

RUN php artisan key:generate

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Set working directory
WORKDIR /var/www/html

# Fix git ownership before copying files
RUN git config --global --add safe.directory /var/www/html

# Create SQLite database directory
RUN mkdir -p /var/www/html/database/db \
    && touch /var/www/html/database/db/database.sqlite \
    && chown -R www-data:www-data /var/www/html/database/db \
    && chmod 775 /var/www/html/database/db

# Copy application files
COPY . .

# Install dependencies
RUN composer install --dev --optimize-autoloader --ignore-platform-reqs

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage

# Expose port 8000 and start php-fpm server
EXPOSE 8000

# Start server and migrate database
CMD ["sh", "-c", "php artisan migrate --force && php artisan serve --host=0.0.0.0 --port=8000"]
