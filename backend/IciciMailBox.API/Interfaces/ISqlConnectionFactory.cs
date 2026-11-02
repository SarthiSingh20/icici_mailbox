using Microsoft.Data.SqlClient;

namespace IciciMailBox.API.Interfaces;

public interface ISqlConnectionFactory
{
    SqlConnection CreateConnection();
}
