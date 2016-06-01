# kong-dev-docker
A docker image for kong that's more appropriate for devleopers

# Layout
This image sets up all of the software and dependencies in such a way as all
important files and directories are under `/kong` on the image.

The goal is to ensure that plugin development and testing of apis/kongfig can
be done from a single repository.

Just run `docker run` with `-v .:/kong` in your repo to mount your app into
a docker image.

The `/kong` folder is mirrored in the `root` directory here, but is like so:
```
  /kong
      /etc
          /nginx
              /nginx.conf
          /luarocks
          kong.yml
      /temp
      /plugins
      /deps
```

## Stage

Alpha

## Author

konobi

