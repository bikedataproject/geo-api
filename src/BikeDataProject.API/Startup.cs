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
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            services.AddControllers();

            var connectionString = Configuration[$"{Program.EnvVarPrefix}DB"];
            services.AddDbContext<BikeDataDbContext>(ctxt => new BikeDataDbContext(
                connectionString));
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
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

            app.UseRouting();

            app.UseAuthorization();

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllers();
            });
        }
    }
}
