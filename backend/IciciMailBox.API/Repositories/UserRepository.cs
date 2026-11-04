using System.Data;
using IciciMailBox.API.DTOs;
using IciciMailBox.API.Interfaces;
using IciciMailBox.API.Models;
using Microsoft.Data.SqlClient;

namespace IciciMailBox.API.Repositories;

public sealed class UserRepository(ISqlConnectionFactory connectionFactory) : IUserRepository
{
    public async Task<AuthenticatedUser?> GetByUsernameAsync(string username, CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = Command(connection, "dbo.usp_User_GetByUsername");
        command.Parameters.Add("@Username", SqlDbType.NVarChar, 80).Value = username;
        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);

        if (!await reader.ReadAsync(cancellationToken))
        {
            return null;
        }

        return new AuthenticatedUser(
            reader.GetInt32(reader.GetOrdinal("UserId")),
            reader.GetString(reader.GetOrdinal("Username")),
            reader.GetString(reader.GetOrdinal("DisplayName")),
            (byte[])reader.GetValue(reader.GetOrdinal("PasswordHash")),
            (byte[])reader.GetValue(reader.GetOrdinal("PasswordSalt")),
            reader.GetInt32(reader.GetOrdinal("PasswordIterations")),
            reader.GetBoolean(reader.GetOrdinal("IsActive")),
            reader.GetString(reader.GetOrdinal("RoleName")),
            IntOrNull(reader, "BranchId"),
            StringOrNull(reader, "BranchName"));
    }

    public async Task UpdateLastLoginAsync(int userId, CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = Command(connection, "dbo.usp_User_UpdateLastLogin");
        command.Parameters.Add("@UserId", SqlDbType.Int).Value = userId;
        await connection.OpenAsync(cancellationToken);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<UserDto>> GetUsersAsync(CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = Command(connection, "dbo.usp_User_GetAll");
        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        var users = new List<UserDto>();
        while (await reader.ReadAsync(cancellationToken))
        {
            users.Add(new UserDto(
                reader.GetInt32(reader.GetOrdinal("UserId")),
                reader.GetString(reader.GetOrdinal("Username")),
                reader.GetString(reader.GetOrdinal("DisplayName")),
                reader.GetBoolean(reader.GetOrdinal("IsActive")),
                reader.GetString(reader.GetOrdinal("RoleName")),
                IntOrNull(reader, "BranchId"),
                StringOrNull(reader, "BranchName"),
                DateTimeOrNull(reader, "LastLoginUtc"),
                reader.GetDateTime(reader.GetOrdinal("CreatedUtc"))));
        }

        return users;
    }

    public async Task<IReadOnlyList<AuditLogDto>> GetAuditLogsAsync(int limit, CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = Command(connection, "dbo.usp_AuditLog_GetRecent");
        command.Parameters.Add("@Limit", SqlDbType.Int).Value = limit;
        await connection.OpenAsync(cancellationToken);
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        var logs = new List<AuditLogDto>();
        while (await reader.ReadAsync(cancellationToken))
        {
            logs.Add(new AuditLogDto(
                reader.GetInt64(reader.GetOrdinal("AuditLogId")),
                IntOrNull(reader, "UserId"),
                StringOrNull(reader, "Username"),
                StringOrNull(reader, "DisplayName"),
                reader.GetString(reader.GetOrdinal("Action")),
                reader.GetString(reader.GetOrdinal("EntityType")),
                StringOrNull(reader, "EntityId"),
                StringOrNull(reader, "Detail"),
                reader.GetDateTime(reader.GetOrdinal("OccurredUtc"))));
        }

        return logs;
    }

    public async Task<int> CreateUserAsync(
        CreateUserRequest request,
        byte[] passwordHash,
        byte[] passwordSalt,
        int iterations,
        int createdByUserId,
        CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = Command(connection, "dbo.usp_User_Create");
        command.Parameters.Add("@Username", SqlDbType.NVarChar, 80).Value = request.Username;
        command.Parameters.Add("@DisplayName", SqlDbType.NVarChar, 160).Value = request.DisplayName;
        command.Parameters.Add("@PasswordHash", SqlDbType.VarBinary, 64).Value = passwordHash;
        command.Parameters.Add("@PasswordSalt", SqlDbType.VarBinary, 32).Value = passwordSalt;
        command.Parameters.Add("@PasswordIterations", SqlDbType.Int).Value = iterations;
        command.Parameters.Add("@RoleName", SqlDbType.NVarChar, 40).Value = request.RoleName;
        command.Parameters.Add("@BranchId", SqlDbType.Int).Value = request.BranchId;
        command.Parameters.Add("@CreatedByUserId", SqlDbType.Int).Value = createdByUserId;
        await connection.OpenAsync(cancellationToken);
        return Convert.ToInt32(await command.ExecuteScalarAsync(cancellationToken));
    }

    public async Task SetUserActiveAsync(int userId, bool isActive, int changedByUserId, CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = Command(connection, "dbo.usp_User_SetActive");
        command.Parameters.Add("@UserId", SqlDbType.Int).Value = userId;
        command.Parameters.Add("@IsActive", SqlDbType.Bit).Value = isActive;
        command.Parameters.Add("@ChangedByUserId", SqlDbType.Int).Value = changedByUserId;
        await connection.OpenAsync(cancellationToken);
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    public async Task<int> CreateBranchAsync(CreateBranchRequest request, int createdByUserId, CancellationToken cancellationToken)
    {
        await using var connection = connectionFactory.CreateConnection();
        await using var command = Command(connection, "dbo.usp_Branch_Create");
        command.Parameters.Add("@BranchCode", SqlDbType.NVarChar, 20).Value = request.BranchCode;
        command.Parameters.Add("@BranchName", SqlDbType.NVarChar, 120).Value = request.BranchName;
        command.Parameters.Add("@City", SqlDbType.NVarChar, 100).Value = request.City;
        command.Parameters.Add("@CreatedByUserId", SqlDbType.Int).Value = createdByUserId;
        await connection.OpenAsync(cancellationToken);
        return Convert.ToInt32(await command.ExecuteScalarAsync(cancellationToken));
    }

    private static SqlCommand Command(SqlConnection connection, string procedureName) =>
        new(procedureName, connection) { CommandType = CommandType.StoredProcedure };

    private static int? IntOrNull(SqlDataReader reader, string column) =>
        reader.IsDBNull(reader.GetOrdinal(column)) ? null : reader.GetInt32(reader.GetOrdinal(column));

    private static string? StringOrNull(SqlDataReader reader, string column) =>
        reader.IsDBNull(reader.GetOrdinal(column)) ? null : reader.GetString(reader.GetOrdinal(column));

    private static DateTime? DateTimeOrNull(SqlDataReader reader, string column) =>
        reader.IsDBNull(reader.GetOrdinal(column)) ? null : reader.GetDateTime(reader.GetOrdinal(column));
}
