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

The dashboard deliberately shows demonstration figures until it is connected. Open the **API connection** icon in the Flutter app bar and set the API URL to `http://localhost:5053` when running both projects on this Mac.

## Courier workflow

The Inbound and Outbound navigation items provide separate shipment forms and registers. Each form captures a tracking number, sender/customer, origin and destination branches, recipient name, and recipient address. New records begin as `Pending`; the register supports local search and status updates.

Before using these screens against a database, rerun `database/Tables.sql` and `database/StoredProcedures.sql` to add the `Direction` column and the shipment/master procedures. Then run `database/SeedData.sql` if a demonstration record is wanted.

## API baseline

- `GET /health`
- `GET /api/dashboard/summary` — calls `dbo.usp_Shipment_GetDashboardSummary` with ADO.NET
- `GET /api/masters/branches` and `GET /api/masters/customers` — dropdown data
- `GET /api/shipments?direction=Inbound|Outbound&search=<text>` — shipment register
- `POST /api/shipments` — creates a shipment and audit event
- `PATCH /api/shipments/{shipmentId}/status` — updates status and writes an audit event

## Packages

Backend: `Microsoft.Data.SqlClient` 7.1.1, `Swashbuckle.AspNetCore` 10.3.1, and .NET 10 cryptography servicing package 10.0.14.

Flutter: `http`, `flutter_riverpod`, `intl`, `flutter_secure_storage`, and `shared_preferences`.
