# geo-api

<p align="center">
  <a href="https://github.com/bikedataproject/geo-api">
    <img src="https://avatars3.githubusercontent.com/u/64870976?s=200&v=4" alt="Logo" width="80" height="80">
  </a>

  <h3 align="center">Geo Api</h3>

  <p align="center">
    The geo api is used to handle the addition of gps tracks coming from our mobile app but also for the deletion of any user data (either coming from the website or the mobile app).
    <br />
    <a href="https://github.com/bikedataproject/geo-api/issues">Report Bug</a>
    ·
    <a href="https://github.com/bikedataproject/geo-api/issues">Request Feature</a>
  </p>
</p>

## Table of Contents

* [About the Project](#about-the-project)
  * [Built With](#built-with)
* [Getting Started](#getting-started)
  * [Prerequisites](#prerequisites)
  * [Installation](#installation)
* [Usage](#usage)
* [Roadmap](#roadmap)
* [Contributing](#contributing)
* [License](#license)
* [Contact](#contact)

## About The Project

![.NET Core](https://github.com/bikedataproject/geo-api/workflows/.NET%20Core/badge.svg)
![Docker Image CI](https://github.com/bikedataproject/geo-api/workflows/Docker%20Image%20CI%20Build/badge.svg)
![Docker Image CD](https://github.com/bikedataproject/geo-api/workflows/Docker%20Image%20Staging%20CD/badge.svg)

### Built With

* [C#](https://docs.microsoft.com/en-us/dotnet/csharp/programming-guide/)
* [Entity Framework Core](https://docs.microsoft.com/en-us/ef/core/)

## Getting Started

To get a local copy up and running follow these simple steps.

### Prerequisites

For this project to run you need .NET Core 3.1 installed on your computer [you can follow this link to download it (Windows, Linux, macOS](https://dotnet.microsoft.com/download/dotnet-core/3.1)

### Installation
 
1. Clone the repo
```sh
git clone https://github.com/bikedataproject/geo-api.git
```
2. Restore the package.

As we are using a `homemade` NuGet package, create a `nuget.config` file in the local root folder of your freshly cloned repository
Paste the following in the file, replace `GitHubUsername` with your own GitHub username and `AccessPassword` with a GitHub Token [tutorial to get the informations needed in the file](https://docs.github.com/en/packages/using-github-packages-with-your-projects-ecosystem/configuring-dotnet-cli-for-use-with-github-packages):
```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
    <packageSources>
        <clear />
        <add key="nuget.org" value="https://api.nuget.org/v3/index.json" protocolVersion="3" />
        <add key="github" value="https://nuget.pkg.github.com/bikedataproject/index.json" />
    </packageSources>
    <packageSourceCredentials>
        <github>
            <add key="Username" value="GitHubUsername" />
            <add key="ClearTextPassword" value="AccessPassword" />
        </github>
    </packageSourceCredentials>
</configuration>
```
3. Restore the dependencies

In the project folder (`./src/BikeDataProject.API/`), use the following command:
```sh
dotnet restore
```
4. Launch the project

You can launch the project by typing the following command in the project folder (`./src/BikeDataProject.API/`): 
```sh
dotnet run
```

## Usage
This API is used to store gps tracks that comes from our [mobile application](https://github.com/bikedataproject/app) but also to delete data from users (those who linked their Strava account with our service, those who donated their data via .GPX/.FIT files or those who used our mobile application).

## Roadmap

See the [open issues](https://github.com/bikedataproject/geo-api/issues) for a list of proposed features (and known issues).

## Contributing

Contributions are what make the open source community such an amazing place to be learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/MyFeature`)
3. Commit your Changes (`git commit -m 'Add some great feature'`)
4. Push to the Branch (`git push origin feature/MyFeature`)
5. Open a Pull Request with the **develop** branch as its target.

To know more about how to contribute to this project please refer to the `CONTRIBUTING.md` file.

## License

Distributed under the MIT License. See `LICENSE` for more information.

## Contact

Bike Data Project - [@bikedataproject](https://twitter.com/bikedataproject) - dries@openknowledge.be / ben@openknowledge.be

Project Link: [https://github.com/bikedataproject/geo-api](https://github.com/bikedataproject/geo-api)
