# SQL Server setup

This Apple Silicon Mac should use Azure SQL Database or an existing remote SQL Server instance. Microsoft supports SQL Server Linux container images only on Intel/AMD x86-64 Linux hosts; do not rely on an ARM64 local SQL Server container. Azure SQL Edge is retired and is not a suitable new local-development choice.

## Connect with VS Code

1. Open the `icici-mail-box` folder in VS Code.
2. Open the MSSQL extension and choose **Add Connection**.
3. Enter the server host, database name, SQL or Microsoft Entra authentication, and encryption settings provided by the database administrator.
4. Select the `IciciMailBox` database and run the files in this order: `database/Tables.sql`, `database/StoredProcedures.sql`, then `database/SeedData.sql`.

## Configure the API safely

Do not put real credentials in `appsettings.json`. From `backend/IciciMailBox.API`, initialize user secrets and set a development connection string:

```bash
dotnet user-secrets init
dotnet user-secrets set "ConnectionStrings:SqlServer" "Server=tcp:YOUR_SERVER,1433;Database=IciciMailBox;User Id=YOUR_USER;Password=YOUR_PASSWORD;Encrypt=True;TrustServerCertificate=False;"
```

The `DashboardController` calls `dbo.usp_Shipment_GetDashboardSummary` through ADO.NET. There is no Entity Framework dependency.
