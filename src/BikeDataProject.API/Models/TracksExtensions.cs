using BikeDataProject.API.Domain;

namespace BikeDataProject.API.Models
{
    public static class TracksExtensions
    {
       public static UserContribution ToUserContribution(this Track track, Contribution contribution)
       {
           return new UserContribution
           {
               UserId = track.UserId,
               ContributionId = contribution.ContributionId 
           };
       } 
    }
}