using System.Linq;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using BDPDatabase;
using Microsoft.AspNetCore.HttpOverrides;

namespace BikeDataProject.API
{
    /// <summary>
    /// Contains the code handling the software startup.
    /// </summary>
    public class Startup
    {
        /// <summary>
        /// Initiates a new instance of the <see cref="Startup"></see> class.
        /// </summary>
        /// <param name="configuration"></param>
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        /// <summary>
        /// The configuration.
        /// </summary>
        public IConfiguration Configuration { get; }

        /// <summary>
        /// This method gets called by the runtime. Use this method to add services to the container.
        /// </summary>
        /// <param name="services">A collection of services.</param>
        public void ConfigureServices(IServiceCollection services)
        {
            services.AddControllers();

            var connectionString = Configuration[$"{Program.EnvVarPrefix}DB"];
            services.AddDbContext<BikeDataDbContext>(ctxt => new BikeDataDbContext(
                connectionString));

            services.AddSwaggerDocument();
        }

        /// <summary>
        /// This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        /// </summary>
        /// <param name="app"></param>
        /// <param name="env"></param>
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }

            var options = new ForwardedHeadersOptions
            {
                ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedHost | ForwardedHeaders.XForwardedProto
            };
            options.KnownNetworks.Clear();
            options.KnownProxies.Clear();

            app.UseForwardedHeaders(options);
            app.Use((context, next) =>
            {
                if (!context.Request.Headers.TryGetValue("X-Forwarded-PathBase", out var pathBases)) return next();
                context.Request.PathBase = pathBases.First();
                if (context.Request.PathBase.Value.EndsWith("/"))
                {
                    context.Request.PathBase =
                        context.Request.PathBase.Value.Substring(0, context.Request.PathBase.Value.Length - 1);
                }
                // ReSharper disable once InvertIf
                if (context.Request.Path.Value.StartsWith(context.Request.PathBase.Value))
                {
                    var after = context.Request.Path.Value.Substring(
                        context.Request.PathBase.Value.Length,
                        context.Request.Path.Value.Length - context.Request.PathBase.Value.Length);
                    context.Request.Path = after;
                }
                return next();
            });

            app.UseOpenApi(settings =>
            {
                settings.PostProcess = (document, req) =>
                {
                    document.Info.Version = "v1";
                    document.Info.Title = "Bike Data Project - Geo API";
                    document.Info.Description = "An API allowing for the logging of GPS data..";
                    document.Info.TermsOfService = string.Empty;
                    document.Info.Contact = new NSwag.OpenApiContact()
                    {
                        Name = "Open Knowledge Belgium VZW/ASBL",
                        Email = "dries@openknowledge.be",
                        Url = "https://www.bikedataproject.info"
                    };
                };
            });
            app.UseSwaggerUi3();

            app.UseRouting();

            app.UseAuthorization();

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllers();
            });
        }
    }
}
