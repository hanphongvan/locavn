using Httm.XangDau.Api.Features.Auth.Registration.Persistence;
using Httm.XangDau.Api.Features.Auth.Registration.PasswordReset;
using Httm.XangDau.Api.Features.Auth.Registration.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Httm.XangDau.Api.Features.Auth.Registration;

public static class RegistrationDependencyInjection
{
    public static IServiceCollection AddPublicUserRegistration(this IServiceCollection services, IConfiguration configuration)
    {
        services.Configure<PasswordResetOptions>(configuration.GetSection(PasswordResetOptions.SectionName));
        services.Configure<SmtpOptions>(configuration.GetSection(SmtpOptions.SectionName));
        services.AddScoped<IPasswordResetEmailSender, SmtpPasswordResetEmailSender>();
        services.AddScoped<IForgotPasswordService, ForgotPasswordService>();
        services.AddScoped<IResetPasswordFromTokenService, ResetPasswordFromTokenService>();

        services.AddScoped<IUserRegistrationWriteRepository, UserRegistrationWriteRepository>();
        services.AddScoped<IUserRegistrationService, UserRegistrationService>();
        services.AddScoped<IChangePasswordService, ChangePasswordService>();
        return services;
    }
}
