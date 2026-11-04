using IciciMailBox.API.Interfaces;
using Microsoft.Data.SqlClient;

namespace IciciMailBox.API.Data;

public sealed class SqlConnectionFactory(IConfiguration configuration) : ISqlConnectionFactory
{
    public SqlConnection CreateConnection()
    {
        var connectionString = configuration.GetConnectionString("SqlServer");

        if (string.IsNullOrWhiteSpace(connectionString) || connectionString.Contains("YOUR_SQL_SERVER", StringComparison.Ordinal))
        {
            throw new SqlServerConfigurationException(
                "A real ConnectionStrings:SqlServer value is required. Use user secrets or environment variables; do not commit credentials.");
        }

        try
        {
            return new SqlConnection(new SqlConnectionStringBuilder(connectionString).ConnectionString);
        }
        catch (ArgumentException exception)
        {
            throw new SqlServerConfigurationException("ConnectionStrings:SqlServer is invalid.", exception);
        }
    }
}
