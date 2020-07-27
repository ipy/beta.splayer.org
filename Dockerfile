FROM nginx:alpine AS runtime

COPY . /usr/share/nginx/html/
