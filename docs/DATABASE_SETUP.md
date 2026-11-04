# SQL Server and local setup

The API uses SQL Server through `Microsoft.Data.SqlClient`, parameterized ADO.NET calls, and stored procedures. It does not fall back to an in-memory or local database.

## Database availability

No SQL Server instance is configured in this development environment. This Apple Silicon Mac also does not have `sqlcmd` or Docker available. Use an existing SQL Server or provision Azure SQL Database; do not point the app at a fake or sample connection string. A local SQL Server container requires a supported x86-64 Linux host.

Create an empty database named `IciciMailBox` using your SQL Server administration tool. Configure network access/firewall rules and require encrypted connections before connecting.

## Apply the schema and sample data

In the VS Code MSSQL extension, connect to the target `IciciMailBox` database and run these scripts in order:

1. `database/Tables.sql` — idempotently creates the tables and indexes and upgrades the original starter schema.
2. `database/StoredProcedures.sql` — creates or updates the API procedures.
3. `database/SeedData.sql` — **development only**; inserts four branches, categories, demo users, and 20 demo shipments marked `IsDemo = 1`.

The seeded logins share the local-only password `ChangeMe!2026`: `ho.admin` is the master account; `mumbai.operator`, `delhi.operator`, `bengaluru.operator`, and `chennai.operator` are branch accounts. Rotate or deactivate all demo accounts before deployment. Never use them for operational data.

If running scripts with `sqlcmd`, execute from the repository root with a suitably privileged deployment account:

```sh
sqlcmd -S tcp:<server>,1433 -d IciciMailBox -E -b -i database/Tables.sql
sqlcmd -S tcp:<server>,1433 -d IciciMailBox -E -b -i database/StoredProcedures.sql
sqlcmd -S tcp:<server>,1433 -d IciciMailBox -E -b -i database/SeedData.sql
```

For SQL authentication, replace `-E` with `-U <deployment-user> -P` and let `sqlcmd` prompt for the password. Do not put credentials in the repository or command history.

## Configure the API locally

From `backend/IciciMailBox.API`, store local values in .NET user secrets:

```sh
dotnet user-secrets init
dotnet user-secrets set "ConnectionStrings:SqlServer" "Server=tcp:<server>,1433;Initial Catalog=IciciMailBox;Persist Security Info=False;User ID=<user>;Password=<password>;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
dotnet user-secrets set "Authentication:Jwt:SigningKey" "<unique-random-secret-at-least-32-characters>"
dotnet user-secrets set "Frontend:AllowedOrigins:0" "http://localhost:5000"
```

Generate a signing secret locally with `openssl rand -base64 48`, then use its output for the signing key. Never reuse that value between environments. Production deployments should inject secrets from a managed secret store/environment rather than user secrets.

Alternatively, environment variables use .NET's double-underscore convention:

- `ConnectionStrings__SqlServer`
- `Authentication__Jwt__SigningKey`
- `Frontend__AllowedOrigins__0`

For an Azure App Service using a managed identity, use a SQL connection string such as `Server=tcp:<server>,1433;Initial Catalog=IciciMailBox;Authentication=Active Directory Managed Identity;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;`, create the identity as a database user, and grant it the minimum permissions required to execute the application's stored procedures. For local development, use a dedicated least-privilege SQL login or Microsoft Entra authentication.

Run the API with `dotnet run`. `GET /health` checks process liveness; `GET /health/ready` opens the configured SQL connection and returns `503` when SQL Server is unavailable or not configured. Swagger is enabled only in Development.

## Run the Flutter client

```sh
cd frontend/icici_mail_box_app
flutter pub get
flutter run -d chrome --web-port 5000
```

The default API URL is `http://localhost:5053`; set it in the app's API connection settings if needed. For a web deployment, use `flutter build web --dart-define=API_BASE_URL=https://<api-host>` and configure the API's allowed origin to the deployed web origin. The browser client uses secure storage for the JWT; it does not store shipment records in local storage.

## Deploy

Deploy the API to a supported .NET 10 host (for example Azure App Service) and the Flutter web build to a static web host. Configure the production SQL connection, unique JWT signing key, and exact Flutter origin as host settings; enable HTTPS and configure the SQL firewall/private networking. For Azure SQL, grant the API identity database access and execute permission on the stored procedures. Deploy the SQL scripts through a controlled migration/release process before deploying API code that depends on them.

Create production branch operators in the master-only **Administration** screen after the schema and master identity are ready. Add a branch through **Create branch**, then create an operator and assign that branch. Normal users cannot create accounts or change their branch assignment.
