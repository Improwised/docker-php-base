# docker-php-base

Base container image for modern PHP applications built on top of Alpine Linux. Targeted for containerizing Laravel.

## Usage

* Create a `Dockerfile` in root of your PHP project.

```dockerfile
FROM improwised/php-base:7.4

# Copy Composer
COPY ./composer.* /var/www/

# Install dependencies
RUN composer install --no-scripts --no-autoloader

# Copy app
COPY . /var/www

# Generate autoload and fix permissions
RUN set -ex \
  && composer dump-autoload --optimize \
  && chown -R nginx:nginx /var/www
```

* Build your application Docker image for Production

```
docker build -t my-laravel-app .
docker run -it --rm --name my-running-app my-laravel-app
```
