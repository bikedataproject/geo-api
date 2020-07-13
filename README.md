# api

![.NET Core](https://github.com/bikedataproject/api/workflows/.NET%20Core/badge.svg)

The api

# Coding Conventions

- During this project we will be using [C# Google Style guide](https://google.github.io/styleguide/csharp-style.html) + brackets on a newline.
- In a simplified [clean architecture design](https://medium.com/vinarah/clean-architecture-example-c-5990bd4ac8).
- Returning a null value is forbidden. You can return for example `Enumerable.Empty<T>()` or a default value.
- Prefer to use the Empty method on types to return empty variables.
- Use the object representation type instead of primitive ones (`String` instead of `string`).
