# Petrol station admin

Angular admin shell for petrol station store management (stores, fuel products, prices, inventory). Uses the real ASP.NET Core admin APIs; configure the API origin in `src/environments/`.

This project was generated using [Angular CLI](https://github.com/angular/angular-cli) version 19.2.24.

## API base URL

- **Development:** edit `src/environments/environment.ts` → `apiBaseUrl` (default `http://localhost:5274`; match your backend URL and port).
- **Production:** edit `src/environments/environment.production.ts` before `ng build` (production replaces `environment.ts` via `angular.json` `fileReplacements`).

HTTP calls should go through `ApiHttpService`, which prefixes paths with `apiBaseUrl`.

Feature modules expose strongly typed `*ApiService` classes under `src/app/features/*/services/` (see `StoresApiService`, `FuelProductsApiService`, etc.). They return RxJS `Observable` values and use `handleApiError<T>()` so failures surface as `ApiRequestError` with optional ASP.NET `ProblemDetails` in `problem.detail`.

## Development server

To start a local development server, run:

```bash
ng serve
```

Once the server is running, open your browser and navigate to `http://localhost:4200/`. The application will automatically reload whenever you modify any of the source files.

## Code scaffolding

Angular CLI includes powerful code scaffolding tools. To generate a new component, run:

```bash
ng generate component component-name
```

For a complete list of available schematics (such as `components`, `directives`, or `pipes`), run:

```bash
ng generate --help
```

## Building

To build the project run:

```bash
ng build
```

This will compile your project and store the build artifacts in the `dist/` directory. By default, the production build optimizes your application for performance and speed.

## Running unit tests

To execute unit tests with the [Karma](https://karma-runner.github.io) test runner, use the following command:

```bash
ng test
```

## Running end-to-end tests

For end-to-end (e2e) testing, run:

```bash
ng e2e
```

Angular CLI does not come with an end-to-end testing framework by default. You can choose one that suits your needs.

## Additional Resources

For more information on using the Angular CLI, including detailed command references, visit the [Angular CLI Overview and Command Reference](https://angular.dev/tools/cli) page.
