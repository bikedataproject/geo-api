using System;
using System.Collections.Generic;
using System.Linq;
using BDPDatabase;
using NetTopologySuite.Geometries;
using NetTopologySuite.IO;
using static BikeDataProject.API.Models.Helpers;

namespace BikeDataProject.API.Models
{
    public static class LocationsExtensions
    {
        public static Contribution ToContribution(this List<Location> locations)
        {
            var coordinates = new Coordinate[locations.Count];
            var timeOffsets = new DateTimeOffset[locations.Count];
            var distance = 0.0;
            for (int i = 0; i < locations.Count; i++)
            {
                var location = locations.ElementAt(i);
                coordinates[i] = new Coordinate(location.Longitude, location.Latitude);
                timeOffsets[i] = location.Timestamp;

                if (i < locations.Count - 1)
                {
                    var coord1 = coordinates[i];
                    var coord2 = coordinates[i + 1];

                    double theta = coord1.X - coord2.X;
                    double dist = (Math.Sin(deg2rad(coord1.Y)) * Math.Sin(deg2rad(coord2.Y))) +
                        (Math.Cos(deg2rad(coord1.Y)) * Math.Cos(deg2rad(coord2.Y)) * Math.Cos(deg2rad(theta)));
                    dist = Math.Acos(dist);
                    dist = rad2deg(dist);
                    dist = dist * 60 * 1.1515 * 1.609344; // to kilometers
                    dist = dist * 1000; // to meters

                    distance += dist;
                }
            }
            var lineString = new LineString(coordinates);
            var duration = (locations.Last().Timestamp - locations.First().Timestamp).TotalSeconds;

            return new Contribution()
            {
                PointsGeom = new PostGisWriter().Write(lineString),
                UserAgent = Constants.MobileAppUserAgent,
                TimeStampStart = locations.First().Timestamp,
                TimeStampStop = locations.Last().Timestamp,
                PointsTime = timeOffsets,
                Distance = Convert.ToInt32(distance),
                Duration = Convert.ToInt32(Math.Round(duration))
            };
        }
    }
}