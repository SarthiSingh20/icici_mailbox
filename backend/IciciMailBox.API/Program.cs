using System.Text;
using IciciMailBox.API.Data;
using IciciMailBox.API.Interfaces;
using IciciMailBox.API.Repositories;
using IciciMailBox.API.Services;
using Microsoft.Data.SqlClient;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);

var allowedOrigins = builder.Configuration
    .GetSection("Frontend:AllowedOrigins")
    .Get<string[]>() ?? [];
var jwtSigningKey = builder.Configuration["Authentication:Jwt:SigningKey"];
if (string.IsNullOrWhiteSpace(jwtSigningKey) || jwtSigningKey.Length < 32)
{
    throw new InvalidOperationException(
        "Set Authentication__Jwt__SigningKey to a unique value of at least 32 characters through an environment variable or user secret.");
}
var jwtIssuer = builder.Configuration["Authentication:Jwt:Issuer"] ?? throw new InvalidOperationException("JWT issuer is missing.");
var jwtAudience = builder.Configuration["Authentication:Jwt:Audience"] ?? throw new InvalidOperationException("JWT audience is missing.");

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddProblemDetails();
builder.Services.AddHttpContextAccessor();
builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = jwtIssuer,
            ValidateAudience = true,
            ValidAudience = jwtAudience,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSigningKey)),
            ClockSkew = TimeSpan.FromMinutes(1)
        };
    });
builder.Services.AddAuthorization();
builder.Services.AddSwaggerGen(options =>
    options.SwaggerDoc("v1", new()
    {
        Title = "ICICI Mail Box Courier API",
        Version = "v1"
    }));
builder.Services.AddCors(options =>
    options.AddPolicy("Frontend", policy => policy
        .WithOrigins(allowedOrigins)
        .AllowAnyHeader()
        .AllowAnyMethod()));

// ADO.NET composition root — Entity Framework is intentionally not used.
builder.Services.AddSingleton<ISqlConnectionFactory, SqlConnectionFactory>();
builder.Services.AddScoped<ICurrentUser, CurrentUser>();
builder.Services.AddScoped<IShipmentRepository, ShipmentRepository>();
builder.Services.AddScoped<IShipmentService, ShipmentService>();
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddSingleton<IJwtTokenService, JwtTokenService>();

var app = builder.Build();

app.UseExceptionHandler(errorApp => errorApp.Run(async context =>
{
    var exception = context.Features.Get<IExceptionHandlerFeature>()?.Error;
    var logger = context.RequestServices.GetRequiredService<ILogger<Program>>();
    if (exception is not null)
    {
        logger.LogError(exception, "Unhandled request failure for {Path}.", context.Request.Path);
    }

    var sqlException = exception as SqlException;
    var statusCode = exception switch
    {
        UnauthorizedAccessException => StatusCodes.Status403Forbidden,
        KeyNotFoundException => StatusCodes.Status404NotFound,
        ArgumentException => StatusCodes.Status400BadRequest,
        SqlException { Number: 2601 or 2627 } => StatusCodes.Status409Conflict,
        SqlException { Number: 547 } => StatusCodes.Status400BadRequest,
        SqlServerConfigurationException => StatusCodes.Status503ServiceUnavailable,
        _ => StatusCodes.Status500InternalServerError
    };
    var title = statusCode switch
    {
        StatusCodes.Status409Conflict => "A record with the same unique value already exists.",
        StatusCodes.Status503ServiceUnavailable => "The database is temporarily unavailable.",
        StatusCodes.Status500InternalServerError => "An unexpected server error occurred.",
        _ when sqlException?.Number == 547 => "A referenced branch, sender, category, or user is invalid.",
        _ => exception?.Message
    };

    if (sqlException is not null && sqlException.Number is 2 or 53 or 4060 or 18456 or 10928 or 10929 or 40197 or 40501 or 40613)
    {
        statusCode = StatusCodes.Status503ServiceUnavailable;
        title = "The database is temporarily unavailable.";
    }

    await Results.Problem(
        statusCode: statusCode,
        title: title)
        .ExecuteAsync(context);
}));

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(options =>
        options.SwaggerEndpoint("/swagger/v1/swagger.json", "ICICI Mail Box Courier API v1"));
}

app.UseHttpsRedirection();
app.UseCors("Frontend");
app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/health", () => Results.Ok(new { status = "healthy" }))
    .WithName("GetHealth");
app.MapGet("/health/ready", async (
    ISqlConnectionFactory connectionFactory,
    ILogger<Program> logger,
    CancellationToken cancellationToken) =>
{
    try
    {
        await using var connection = connectionFactory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        return Results.Ok(new { status = "ready", database = "connected" });
    }
    catch (SqlException exception)
    {
        logger.LogError(exception, "SQL Server readiness check failed.");
        return Results.Problem(
            statusCode: StatusCodes.Status503ServiceUnavailable,
            title: "SQL Server is unavailable or not configured.");
    }
    catch (SqlServerConfigurationException exception)
    {
        logger.LogError(exception, "SQL Server readiness configuration is invalid.");
        return Results.Problem(
            statusCode: StatusCodes.Status503ServiceUnavailable,
            title: "SQL Server is unavailable or not configured.");
    }
})
    .WithName("GetReadiness");
app.MapControllers();

app.Run();
