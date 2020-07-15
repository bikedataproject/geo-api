using System.Collections.Generic;
using System.Linq;
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
        public static List<Location> ToLocations(this Track track)
        {
            List<Location> locations = new List<Location>();
            foreach (var location in track.Locations)
            {
                int index = track.Locations.IndexOf(location);
                if (location.IsFromMockProvider)
                {
                    continue;
                }

                if (index != track.Locations.Count - 1)
                {
                    if (location.Timestamp < track.Locations.ElementAt(index + 1).Timestamp)
                    {
                        locations.Add(location);
                    }
                }
                else
                {
                    locations.Add(location);
                }
            }

            return locations;
        }
    }
}