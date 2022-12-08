Through this Bitbucket Pipe, you can copy a compressed (gzip) MySQL dump from AWS S3 to a Digital Ocean MySQL database.

# Bitbucket pipeline example
The example below shows how to use the Bitbucket pipe in your bitbucket-pipelines.yml.

```yaml
script:
  - pipe: docker://programic/pipe-import-database:latest
    variables:
      AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID
      AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY
      AWS_DEFAULT_REGION: $AWS_DEFAULT_REGION
      S3_BUCKET: $S3_BUCKET
      DIGITALOCEAN_ACCESS_TOKEN: $DIGITALOCEAN_ACCESS_TOKEN
      DIGITALOCEAN_DATABASE_ID: $DIGITALOCEAN_DATABASE_ID
      MYSQL_DATABASE: "database-name"
      MYSQL_USER: "bitbucket"
      MYSQL_PASSWORD: $MYSQL_PASSWORD
```