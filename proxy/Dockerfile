FROM nginx:latest

RUN apt-get update && apt-get install -y certbot python3-certbot-nginx

CMD ["nginx", "-g", "daemon off;"]
