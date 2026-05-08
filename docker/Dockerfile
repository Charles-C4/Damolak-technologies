FROM nginx:alpine

# Removed default nginx static files
RUN rm -rf /usr/share/nginx/html/*

# Copied my static site
COPY app/site /usr/share/nginx/html
# Copied my nginx configuration
COPY docker/nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]