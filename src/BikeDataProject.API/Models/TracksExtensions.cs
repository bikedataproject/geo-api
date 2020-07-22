using System.Collections.Generic;
using System.Linq;
using BDPDatabase;

namespace BikeDataProject.API.Models
{
    /// <summary>
    /// Contains the extensions for the <see cref="Track"></see> objects.
    /// </summary>
    public static class TracksExtensions
    {
        /// <summary>
        /// Convert a contribution identifier and a user identifier to a UserContribution permitting to link and index them in the database. 
        /// </summary>
        /// <param name="track">A track.</param>
        /// <param name="contributionId">A contribution identifier.</param>
        /// <param name="userId">A user identifier.</param>
        /// <returns>A <see cref="UserContribution"></see>.</returns>
        public static UserContribution ToUserContribution(this Track track, int contributionId, int userId)
        {
            return new UserContribution
            {
                UserId = userId,
                ContributionId = contributionId
            };
        }

        /// <summary>
        /// Converts a <see cref="Track"></see> into a collection of <see cref="Location"></see>.
        /// </summary>
        /// <param name="track">A track.</param>
        /// <returns>A collection of <see cref="Location"></see>.</returns>
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
                    if (location.DateTimeOffset.Ticks < (track.Locations.ElementAt(index + 1)).DateTimeOffset.Ticks)
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