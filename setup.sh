#!/bin/bash

# Create directory structure
mkdir -p proxy/conf.d wordpress/nginx
mkdir -p wordpress/wordpress_data wordpress/mysql_data

# Download WordPress core
if [ ! -f wordpress/wordpress_data/wp-settings.php ]; then
    echo "Downloading WordPress..."
    wget -q https://wordpress.org/latest.tar.gz -O wordpress/latest.tar.gz
    tar -xzf wordpress/latest.tar.gz -C wordpress/wordpress_data --strip-components=1
    rm wordpress/latest.tar.gz
fi

# Set permissions (dev only)
chmod -R 777 wordpress/wordpress_data
chmod -R 777 wordpress/mysql_data

# Start containers
echo "Starting containers..."
sudo docker-compose -f wordpress/docker-compose.yml up -d
sudo docker-compose -f proxy/docker-compose.yml up -d

# Wait for containers to initialize
sleep 15  # Give containers time to start

# Fix permissions inside container
echo "Setting file ownership..."
sudo docker exec wordpress_app chown -R www-data:www-data /var/www/html

echo "Setup complete! Access at http://wordd.ofgo.in"
