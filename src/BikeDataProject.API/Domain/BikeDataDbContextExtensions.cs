using System;
using System.Linq;

namespace BikeDataProject.API.Domain
{
    public static class BikeDataDbContextExtensions
    {
        public static int GetTotalDistance(this BikeDataDbContext dbContext)
        {
            return dbContext.Contributions.Select(c => c.Distance).Sum();
        }

        public static int GetUserId(this BikeDataDbContext dbContext, Guid userId)
        {
            var user = dbContext.Users.FirstOrDefault(user => user.UserIdentifier == userId);
            return user != null ? user.Id : 0;
        }

        public static void AddContribution(this BikeDataDbContext dbContext, Contribution contribution)
        {
            dbContext.Contributions.Add(contribution);
        }

        public static void AddUserContribution(this BikeDataDbContext dbContext, UserContribution userContribution)
        {
            dbContext.UserContributions.Add(userContribution);
        }

        public static void SaveChanges(this BikeDataDbContext dbContext) => dbContext.SaveChanges();
    }
}