using IciciMailBox.API.Models;

namespace IciciMailBox.API.Interfaces;

public interface ICurrentUser
{
    AccessScope Require();
}
