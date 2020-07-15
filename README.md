# geo-api

## About this repository

![.NET Core](https://github.com/bikedataproject/geo-api/workflows/.NET%20Core/badge.svg)
![Docker Image CI](https://github.com/bikedataproject/geo-api/workflows/Docker%20Image%20CI/badge.svg)

This repository holds code to register new users, either from our own application or using a third-party platform.

## How to build & run this project

```bash
docker build -t registration-api:latest .
docker run -d -p 80:80 --name registration registration-api:latest
```

## Coding conventions

- During this project we will be using [C# Google Style guide](https://google.github.io/styleguide/csharp-style.html) + brackets on a newline.
- Prefer to use the Empty method on types to return empty variables.
