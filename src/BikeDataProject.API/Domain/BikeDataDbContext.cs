using Microsoft.EntityFrameworkCore;

namespace BikeDataProject.API.Domain
{
    public class BikeDataDbContext : DbContext
    {
        public DbSet<User> Users { get; set; }
        public DbSet<Contribution> Contributions { get; set; }
        public DbSet<UserContribution> UserContributions { get; set; }

        private readonly string _connectionInfo;

        public BikeDataDbContext()
        {
            // Only used during migrations
            _connectionInfo = "Host=127.0.0.1;Port=5433;Database=bikedata;Username=postgres;Password=mixbeton";
        }

        public BikeDataDbContext(string connectionInfo)
        {
            _connectionInfo = connectionInfo;
        }

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            optionsBuilder.UseNpgsql(_connectionInfo);
        }
    }
}