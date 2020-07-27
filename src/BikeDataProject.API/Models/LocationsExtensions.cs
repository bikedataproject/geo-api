using System;
using System.Collections.Generic;
using System.Linq;
using BDPDatabase;
using NetTopologySuite.Geometries;
using NetTopologySuite.IO;
using static BikeDataProject.API.Models.Helpers;

namespace BikeDataProject.API.Models
{
    /// <summary>
    /// Contains all the extension methods for the <see cref="Location"></see> objects.
    /// </summary>
    public static class LocationsExtensions
    {
        /// <summary>
        /// Gets a list of <see cref="Location"></see> and returns a <see cref="Contribution"></see>.
        /// </summary>
        /// <param name="locations">Locations.</param>
        /// <returns>A <see cref="Contribution"></see>.</returns>
        public static Contribution ToContribution(this List<Location> locations)
        {
            var coordinates = new Coordinate[locations.Count];
            var timeOffsets = new DateTimeOffset[locations.Count];
            var distance = 0.0;
            //loops over the list of locations and converts it to an array of coordinates that is later added to the Contribution structure.
            for (int i = 0; i < locations.Count; i++)
            {
                var location = locations.ElementAt(i);
                coordinates[i] = new Coordinate(location.Longitude, location.Latitude);
                timeOffsets[i] = location.DateTimeOffset;

                if (i > 0 && i < locations.Count)
                {
                    var coord1 = coordinates[i];
                    var coord2 = coordinates[i - 1];     
                    distance += calculateDistance(coord1, coord2);
                }
            }
            var duration = (locations.Last().DateTimeOffset - locations.First().DateTimeOffset).TotalSeconds;
            return new Contribution()
            {
                PointsGeom = new PostGisWriter().Write(new LineString(coordinates)),
                UserAgent = Constants.MobileAppUserAgent,
                TimeStampStart = locations.First().DateTimeOffset,
                TimeStampStop = locations.Last().DateTimeOffset,
                PointsTime = timeOffsets,
                Distance = Convert.ToInt32(distance),
                Duration = Convert.ToInt32(Math.Round(duration))
            };
        }        
    }
}