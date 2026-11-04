# ICICI Mail Box Courier Management System

Courier-management application using Flutter, ASP.NET Core 10, SQL Server, ADO.NET, and stored procedures.

## Layout

- `backend/IciciMailBox.API` — Controller → Service → Repository API
- `frontend/icici_mail_box_app` — responsive Flutter Material 3 client with branch and head-office views
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
2. Run `database/Tables.sql`, `database/StoredProcedures.sql`, and `database/SeedData.sql`, in that order.
3. Configure `ConnectionStrings__SqlServer` and `Authentication__Jwt__SigningKey` using user secrets locally or environment variables in deployment.
4. Start the API:

   ```bash
   cd backend/IciciMailBox.API
   dotnet run
   ```

5. Confirm `https://localhost:<port>/health/ready` reports `"ready"` and open Swagger in development.
6. Start the Flutter client:

   ```bash
   cd frontend/icici_mail_box_app
   flutter run
   ```

The dashboard and shipment registers read live SQL Server data; connection errors are shown rather than replaced with demonstration statistics. Open **API connection settings** and set the API URL when running the API somewhere other than `http://localhost:5053`.

## Explore the UI without SQL Server

To preview the interfaces before a SQL Server has been provisioned, start Flutter with the explicit UI-preview flag:

```bash
cd frontend/icici_mail_box_app
flutter run -d chrome --dart-define=ENABLE_UI_PREVIEW=true
```

Choose **Preview as branch operator** or **Preview as master user** on the sign-in page. Preview shipments, filters, status updates, account administration, and audit history use in-memory sample data only. The app displays a preview banner; changes are temporary and are not sent to or saved in SQL Server. This flag is off by default. Omit it for normal database-backed sign-in.

## Courier workflow

The Inbound and Outbound navigation items provide separate shipment forms and registers. Forms capture a unique tracking number, sender name and organization, origin and destination branches, package type, description, weight, recipient, handling date, courier, and remarks. Branch operators are restricted by the API to shipments involving their assigned branch; master users can filter across branches. New records begin as `Pending`. Status changes are recorded in shipment history and audit logs. The master dashboard includes organization-wide totals, branch distribution, recent shipments, user/branch administration, CSV report export, and audit activity.

`database/SeedData.sql` installs clearly marked demonstration data (20 sample shipments, four branch operators, and one head-office account). Its shared development password is documented only for local testing; replace or remove demo accounts before deployment.

## API baseline

- `GET /health`
- `GET /health/ready` — checks SQL Server connectivity
- `POST /api/auth/login` and `GET /api/auth/me`
- `GET /api/dashboard/summary` — branch-scoped for operators, organization-wide for master
- `GET /api/dashboard/branches` — master-only branch distribution
- `GET /api/masters/branches` and `GET /api/masters/customers` — dropdown data
- `GET /api/shipments` — shipment register with direction, branch, status, date, and search filters
- `GET /api/shipments/export` — CSV report with the same access scope and filters
- `POST /api/shipments` — creates a shipment and audit event
- `PATCH /api/shipments/{shipmentId}/status` and `GET /api/shipments/{shipmentId}/events`
- `GET /api/users`, `POST /api/users`, `PATCH /api/users/{id}/active`, `POST /api/branches`, `GET /api/audit` — master-only administration

## Demo sign-in (local testing only)

Run the seed script to create accounts. The default local-only password is `ChangeMe!2026`:

- Master: `ho.admin`
- Branch operators: `mumbai.operator`, `delhi.operator`, `bengaluru.operator`, `chennai.operator`

Do not use these demo accounts in a deployed environment. Create operational users through the master-only administration screen and deactivate/remove the seeded accounts.

## Packages

Backend: `Microsoft.Data.SqlClient` 7.1.1, `Swashbuckle.AspNetCore` 10.3.1, and .NET 10 cryptography servicing package 10.0.14.

Flutter: `http`, `flutter_riverpod`, `intl`, `flutter_secure_storage`, and `shared_preferences`.
