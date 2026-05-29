using Httm.XangDau.Api.Features.Account;
using Httm.XangDau.Api.Features.Admin;
using Httm.XangDau.Api.Features.Auth.Apple;
using Httm.XangDau.Api.Features.Auth.Google;
using Httm.XangDau.Api.Features.Auth.Registration;
using Httm.XangDau.Api.Features.BadReports;
using Httm.XangDau.Api.Features.CitizenReports;
using Httm.XangDau.Api.Features.ClientTelemetry;
using Httm.XangDau.Api.Features.AppVersionPolicy;
using Httm.XangDau.Api.Features.Fuel;
using Httm.XangDau.Api.Features.FuelReporting;
using Httm.XangDau.Api.Features.Geography;
using Httm.XangDau.Api.Features.Httm;
using Httm.XangDau.Api.Features.Inventory;
using Httm.XangDau.Api.Features.Leader;
using Httm.XangDau.Api.Features.LeaderAi;
using Httm.XangDau.Api.Features.Pricing;
using Httm.XangDau.Api.Features.Reports;
using Httm.XangDau.Api.Features.StoreAdmin;
using Httm.XangDau.Api.Features.StationRatings;
using Httm.XangDau.Api.Features.Stations;
using Httm.XangDau.Api.Features.Surveys;
using Httm.XangDau.Api.Features.UserVehicles;
using Microsoft.Extensions.Configuration;

namespace Httm.XangDau.Api.Features;

/// <summary>Registers feature-specific services (queries, validators, etc.).</summary>
public static class FeatureDependencyInjection
{
    public static IServiceCollection AddFeatureModules(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddFuelReportingFeature();
        services.AddAccountFeature();
        services.AddStationsFeature(configuration);
        services.AddGeographyFeature();
        services.AddHttmFeature();
        services.AddHttmPhase2Features();
        services.AddSurveysFeature();
        services.AddPricingFeature();
        services.AddInventoryFeature();
        services.AddReportsFeature();
        services.AddLeaderFeature();
        services.AddLeaderAiFeature(configuration);
        services.AddCitizenReportsFeature();
        services.AddBadReportsFeature();
        services.AddAdminFeature();
        services.AddPublicUserRegistration(configuration);
        services.AddGoogleAuth(configuration);
        services.AddAppleAuth(configuration);
        services.AddStoreAdminFeature();
        services.AddStationRatingsFeature();
        services.AddUserVehiclesFeature();
        services.AddFuelFeature();
        services.AddClientTelemetry(configuration);
        services.AddAppVersionPolicyFeature();
        return services;
    }
}
