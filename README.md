# wordpress-docker
# WordPress Project Setup with Docker and Nginx Reverse Proxy

## Project Structure

```bash
wordpress-project/
├── proxy/
│   ├── docker-compose.yml
│   ├── conf.d/
│   │   └── wordpress.conf
│   └── Dockerfile
|└── wordpress/
|         ├── docker-compose.yml
|         ├── nginx/
|         │   └── nginx.conf
|         ├── mysql_data/          # Auto-created by Docker
|         ├── wordpress_data/      # Auto-created by Docker
|_script.sh    └── .env
```



## 1. Proxy Setup

### proxy/docker-compose.yml

```yaml
version: '3.8'

services:
  nginx:
    build: .
    container_name: proxy_server
    restart: always
    ports:
      - "80:80"
    volumes:
      - ./conf.d:/etc/nginx/conf.d
      - ./letsencrypt:/etc/letsencrypt  # Persist certificates
    networks:
      - wordpress_network

networks:
  wordpress_network:
    name: wordpress_network
    external: true
```

### proxy/Dockerfile

```dockerfile
FROM nginx:latest

RUN apt-get update && apt-get install -y certbot python3-certbot-nginx

CMD ["nginx", "-g", "daemon off;"]
```

### proxy/conf.d/wordpress.conf

```nginx
server {
    listen 80;
    server_name w.ofgo.in;

    location / {
        proxy_pass http://wordpress_nginx:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
    }
}
```

## 2. WordPress Setup

### wordpress/docker-compose.yml

```yaml
version: '3.8'

services:
  db:
    image: mysql:8.0
    container_name: wordpress_mysql
    volumes:
      - mysql_data:/var/lib/mysql
    env_file:
      - .env
    networks:
      - wordpress_network

  wordpress:
    image: wordpress:fpm
    container_name: wordpress_app
    volumes:
      - wordpress_data:/var/www/html
    env_file:
      - .env
    networks:
      - wordpress_network

  nginx:
    image: nginx:latest
    container_name: wordpress_nginx
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - wordpress_data:/var/www/html
    networks:
      - wordpress_network

volumes:
  mysql_data:
  wordpress_data:

networks:
  wordpress_network:
    name: wordpress_network
```

### wordpress/nginx/nginx.conf

```nginx
server {
    listen 80;
    server_name localhost;

    root /var/www/html;
    index index.php;

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 7d;
        access_log off;
        try_files $uri =404;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass wordpress:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }
}
```

### wordpress/.env

```ini
# MySQL
MYSQL_ROOT_PASSWORD=root
MYSQL_DATABASE=wordpress
MYSQL_USER=admin
MYSQL_PASSWORD=admin123

# WordPress
WORDPRESS_DB_HOST=db:3306
WORDPRESS_DB_USER=admin
WORDPRESS_DB_PASSWORD=admin123
WORDPRESS_DB_NAME=wordpress

# URLs
WORDPRESS_HOME=http://w.ofgo.in
WORDPRESS_SITEURL=http://w.ofgo.in
```

## 3. Unified Setup Script (setup.sh)

```bash
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

echo "Setup complete! Access at http://w.ofgo.in"
```

### We need to give proper permission for the proxy_server letsecrypt direc
##  For that we need execute below command
```bash
sudo chown -R ubuntu:ubuntu ./letsencrypt
sudo chmod -R 755 ./letsencrypt
```

### After running docker initially It runs on <ec2-ip>/wp-admin

## That time we need to install wordpress and give the password and title & the required feild.

# Then once the setup is done login as admin and update the siteurl and home to https endpoint on saving we will loose the connection but then we need to update the DNS record and proxy_serve configuration updating the DNS name then in .env too we need to update the url's after that we can exec to proxy_server and run certbot.
<img width="1312" alt="Screenshot 2025-02-03 at 9 50 36 PM" src="https://github.com/user-attachments/assets/b48ff7c9-89f6-4356-a771-3f4a3f14ec43" />


### Common Issues

1. **File Not Found Error for docker-compose.yml**

   - Ensure the script is executed from the project root: `cd ~/wordpress-project && ./setup.sh`
   - Adjust paths in the script to be relative to the working directory.

2. **Docker Daemon Permission Denied**

   - Run: `sudo usermod -aG docker $USER`
   - Log out and log back in, then retry.

3. **Check if Containers Are Running**

   ```bash
   docker ps
   ```

4. **Verify Logs for Errors**

   ```bash
   docker logs wordpress_app
   ```




