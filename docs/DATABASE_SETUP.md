# SQL Server and local setup

The API uses SQL Server through `Microsoft.Data.SqlClient`, parameterized ADO.NET calls, and stored procedures. It does not fall back to an in-memory or local database.

## Local database on this Mac

This development setup runs SQL Server 2022 Developer Edition in Docker Desktop, exposed only on `127.0.0.1:1433`. The container is named `icici-mailbox-sql` and stores its data in the persistent Docker volume `icici-mailbox-sql-data`. Its SQL administrator password is stored outside the repository in `~/.config/icici-mailbox/sqlserver.env`, with file permissions restricted to the current user.

Start Docker Desktop, then check or start the container:

```sh
docker ps --filter name=icici-mailbox-sql
docker start icici-mailbox-sql
```

The second command is needed only if the container is stopped. To inspect startup output:

```sh
docker logs --tail 50 icici-mailbox-sql
```

**Apple Silicon caveat:** Microsoft’s SQL Server Linux container is x64-only. This Mac is ARM64, so it runs with `--platform linux/amd64` under Docker emulation. This is unsupported by Microsoft and may be slow or unstable; use it for local development and evaluation only.

The `IciciMailBox` database, schema, stored procedures, sample data, and API user secrets have already been configured on this development Mac. On a fresh database installation, create an empty `IciciMailBox` database and then apply the scripts below. In VS Code, connect to `localhost,1433` with SQL login `sa`; use the password stored in the local env file and enable **Trust Server Certificate** for this local container only.

## Apply the schema and sample data

In the VS Code MSSQL extension, connect to the target `IciciMailBox` database and run these scripts in order:

1. `database/Tables.sql` — idempotently creates the tables and indexes and upgrades the original starter schema.
2. `database/StoredProcedures.sql` — creates or updates the API procedures.
3. `database/SeedData.sql` — **development only**; inserts four branches, categories, demo users, and 20 demo shipments marked `IsDemo = 1`.

The seeded demo accounts share a local-only password. Their sign-in details are in the local, Git-ignored `LOCAL-DEMO-CREDENTIALS.txt` file at the repository root. Rotate or deactivate all demo accounts before deployment. Never use them for operational data.

If running scripts with `sqlcmd`, execute from the repository root with a suitably privileged deployment account:

```sh
sqlcmd -S tcp:<server>,1433 -d IciciMailBox -E -b -i database/Tables.sql
sqlcmd -S tcp:<server>,1433 -d IciciMailBox -E -b -i database/StoredProcedures.sql
sqlcmd -S tcp:<server>,1433 -d IciciMailBox -E -b -i database/SeedData.sql
```

For SQL authentication, replace `-E` with `-U <deployment-user> -P` and let `sqlcmd` prompt for the password. Do not put credentials in the repository or command history.

## Configure the API locally

From `backend/IciciMailBox.API`, store local values in .NET user secrets. User secrets are outside the repository; never commit them.

```sh
dotnet user-secrets init
dotnet user-secrets set "ConnectionStrings:SqlServer" "Server=tcp:<server>,1433;Initial Catalog=IciciMailBox;Persist Security Info=False;User ID=<user>;Password=<password>;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
dotnet user-secrets set "Authentication:Jwt:SigningKey" "<unique-random-secret-at-least-32-characters>"
dotnet user-secrets set "Frontend:AllowedOrigins:0" "http://localhost:8080"
```

Generate a signing secret locally with `openssl rand -base64 48`. Avoid putting real passwords in shell history; this Mac already has its connection string and signing key safely configured in user secrets. `TrustServerCertificate=True` is for the local Docker container only; use certificate validation in deployed environments. Production deployments should inject secrets from a managed secret store/environment rather than user secrets.

Alternatively, environment variables use .NET's double-underscore convention:

- `ConnectionStrings__SqlServer`
- `Authentication__Jwt__SigningKey`
- `Frontend__AllowedOrigins__0`

For an Azure App Service using a managed identity, use a SQL connection string such as `Server=tcp:<server>,1433;Initial Catalog=IciciMailBox;Authentication=Active Directory Managed Identity;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;`, create the identity as a database user, and grant it the minimum permissions required to execute the application's stored procedures. The local Docker setup uses the `sa` account for development convenience only; never use it in a deployed environment.

Run the API with `dotnet run`. `GET /health` checks process liveness; `GET /health/ready` opens the configured SQL connection and returns `503` when SQL Server is unavailable or not configured. Swagger is enabled only in Development.

## Run the app from VS Code

```sh
# Terminal 1: API
cd backend/IciciMailBox.API
dotnet run --launch-profile http

# Terminal 2: Flutter web client
cd frontend/icici_mail_box_app
flutter pub get
flutter run -d chrome --web-port 8080
```

Confirm `http://localhost:5053/health/ready` reports `"ready"` and `"database":"connected"` before signing in. The default API URL is `http://localhost:5053`; port `8080` is included in the development CORS origins. For a web deployment, use `flutter build web --dart-define=API_BASE_URL=https://<api-host>` and configure the API's allowed origin to the deployed web origin. The browser client uses secure storage for the JWT; it does not store shipment records in local storage.

## Deploy

Deploy the API to a supported .NET 10 host (for example Azure App Service) and the Flutter web build to a static web host. Configure the production SQL connection, unique JWT signing key, and exact Flutter origin as host settings; enable HTTPS and configure the SQL firewall/private networking. For Azure SQL, grant the API identity database access and execute permission on the stored procedures. Deploy the SQL scripts through a controlled migration/release process before deploying API code that depends on them.

Create production branch operators in the master-only **Administration** screen after the schema and master identity are ready. Add a branch through **Create branch**, then create an operator and assign that branch. Normal users cannot create accounts or change their branch assignment.
