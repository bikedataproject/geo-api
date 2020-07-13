using System.Collections.Generic;
using BikeDataProject.API.Domain;
using NetTopologySuite.IO;

namespace BikeDataProject.API.Models
{
    public static class LocationsExtensions
    {
        public static Contribution toContribution(this List<Location> locations)
        {
            var contribution = new Contribution();
            contribution.PointsGeom = new PostGisWriter().Write();

        }
    }
}