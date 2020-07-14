using System.Linq;

namespace BikeDataProject.API.Domain
{
    public static class BikeDataDbContextExtensions
    {
        public static int GetTotalDistance(this BikeDataDbContext dbContext)
        {
            return dbContext.Contributions.Select(c => c.Distance).Sum();
        }

        public static void AddContribution(this BikeDataDbContext dbContext, Contribution contribution)
        {
            dbContext.Contributions.Add(contribution);
            dbContext.SaveChanges();
        }

        public static void AddUserContribution(this BikeDataDbContext dbContext, UserContribution userContribution)
        {
            dbContext.UserContributions.Add(userContribution);
            dbContext.SaveChanges();
        }
    }
}