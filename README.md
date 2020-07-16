# geo-api

## About this repository

![.NET Core](https://github.com/bikedataproject/geo-api/workflows/.NET%20Core/badge.svg)
![Docker Image CI](https://github.com/bikedataproject/geo-api/workflows/Docker%20Image%20CI/badge.svg)

This repository holds code to register GPS tracks coming from the mobile application.

## How to build & run this project

```bash
# Creating the image
docker build -t geo-api:latest .
# Create the container based on the downloaded/created image
docker run -d --name geo-api geo-api:latest
```

## Coding conventions

- During this project we will be using [C# Google Style guide](https://google.github.io/styleguide/csharp-style.html) + brackets on a newline.
- Prefer to use the Empty method on types to return empty variables.
