namespace IciciMailBox.API.Data;

public sealed class SqlServerConfigurationException(string message, Exception? innerException = null)
    : Exception(message, innerException);
