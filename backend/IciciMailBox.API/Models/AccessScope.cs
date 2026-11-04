namespace IciciMailBox.API.Models;

public sealed record AccessScope(
    int UserId,
    string Username,
    string DisplayName,
    string RoleName,
    int? BranchId)
{
    public bool IsMaster => RoleName == RoleNames.MasterUser;
}

public static class RoleNames
{
    public const string MasterUser = "MasterUser";
    public const string BranchOperator = "BranchOperator";
}
