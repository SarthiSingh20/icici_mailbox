# ICICI Mail Box Courier Management System

Courier-management starter workspace using Flutter, ASP.NET Core 10, SQL Server, ADO.NET, and stored procedures. Entity Framework is intentionally not used.

## Layout

- `backend/IciciMailBox.API` — Controller → Service → Repository API
- `frontend/icici_mail_box_app` — responsive Flutter Material 3 admin shell
- `database` — SQL Server tables, stored procedures, and sample data
- `docs` — environment and database setup notes

## Prerequisites verified on this Mac

- Apple Silicon Flutter 3.47.9 / Dart 3.13.7
- .NET SDK 10.0.403
- Git, Homebrew, Visual Studio Code, C# Dev Kit, Flutter/Dart, MSSQL extensions
- CocoaPods and Postman

Full Xcode is still required to run Flutter on an iOS simulator or physical iOS device.

## First run

1. Provision or obtain a remote SQL Server/Azure SQL database, then follow [database setup](docs/DATABASE_SETUP.md).
2. Run the SQL scripts in the order shown in the database setup document.
3. Start the API:

   ```bash
   cd backend/IciciMailBox.API
   dotnet run
   ```

4. Open `https://localhost:<port>/swagger` in development after the API starts.
5. Start the Flutter client:

   ```bash
   cd frontend/icici_mail_box_app
   flutter run
   ```

Set the client API base URL through `ApiClient.saveBaseUrl` when adding settings or sign-in UI. Its initial dashboard uses demonstration data until the API is connected.

## API baseline

- `GET /health`
- `GET /api/dashboard/summary` — calls `dbo.usp_Shipment_GetDashboardSummary` with ADO.NET

## Packages

Backend: `Microsoft.Data.SqlClient` 7.1.1, `Swashbuckle.AspNetCore` 10.3.1, and .NET 10 cryptography servicing package 10.0.14.

Flutter: `http`, `flutter_riverpod`, `intl`, `flutter_secure_storage`, and `shared_preferences`.
