using System.Linq;

namespace BikeDataProject.API.Domain
{
    public static class BikeDataDbContextExtensions
    {
       public static int GetTotalDistance(this BikeDataDbContext dbContext)
       {
          return dbContext.Contributions.Select(c => c.Distance).Sum();
       } 
    }
}