using BDPDatabase;

namespace BikeDataProject.API.Models
{
    public static class TracksExtensions
    {
        public static UserContribution ToUserContribution(this Track track, int contributionId, int userId)
        {
            return new UserContribution
            {
                UserId = userId,
                ContributionId = contributionId
            };
        }
    }
}