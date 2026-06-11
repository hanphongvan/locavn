using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.Extensions.Options;
using MimeKit;

namespace Httm.XangDau.Api.Features.Auth.Registration.PasswordReset;

public sealed class SmtpPasswordResetEmailSender(
    IOptions<SmtpOptions> smtpOptions,
    ILogger<SmtpPasswordResetEmailSender> logger) : IPasswordResetEmailSender
{
    /// <inheritdoc />
    public async Task SendPasswordResetLinkAsync(string toEmail, string resetLink, CancellationToken cancellationToken = default)
    {
        var smtp = smtpOptions.Value;
        if (string.IsNullOrWhiteSpace(smtp.Host))
        {
            logger.LogWarning("SMTP Host is empty; password reset email was not sent.");
            return;
        }

        if (string.IsNullOrWhiteSpace(smtp.FromAddress))
        {
            logger.LogWarning("SMTP FromAddress is empty; password reset email was not sent.");
            return;
        }

        var message = new MimeMessage();
        message.From.Add(new MailboxAddress(smtp.FromName ?? "Quanh tôi", smtp.FromAddress));
        message.To.Add(MailboxAddress.Parse(toEmail));
        message.Subject = PasswordResetEmailTemplates.Subject;
        message.Body = new TextPart("plain") { Text = PasswordResetEmailTemplates.BuildPlainTextBody(resetLink) };

        using var client = new SmtpClient();
        var secure = smtp.UseStartTls ? SecureSocketOptions.StartTlsWhenAvailable : SecureSocketOptions.Auto;
        await client
            .ConnectAsync(smtp.Host, smtp.Port, secure, cancellationToken)
            .ConfigureAwait(false);
        try
        {
            if (!string.IsNullOrEmpty(smtp.UserName))
            {
                await client
                    .AuthenticateAsync(smtp.UserName, smtp.Password ?? string.Empty, cancellationToken)
                    .ConfigureAwait(false);
            }

            await client.SendAsync(message, cancellationToken).ConfigureAwait(false);
        }
        finally
        {
            if (client.IsConnected)
                await client.DisconnectAsync(true, cancellationToken).ConfigureAwait(false);
        }
    }
}
