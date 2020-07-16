using System;
using NetTopologySuite.Geometries;

namespace BikeDataProject.API.Models
{
    public static class Helpers
    {
        /// <summary>
        /// Converts degrees to radians
        /// </summary>
        /// <param name="deg">The degree.</param>
        /// <returns>Degree converted in radian.</returns>
        public static double deg2rad(double deg)
        {
            return (deg * Math.PI / 180.0);
        }

        /// <summary>
        /// Converts radians to degrees
        /// </summary>
        /// <param name="rad">The radian.</param>
        /// <returns>Degree as radian.</returns>
        public static double rad2deg(double rad)
        {
            return (rad / Math.PI * 180.0);
        }
        /// <summary>
        /// Calculates the distance between two coordinates.
        /// </summary>
        /// <param name="coord1">The first coordinate.</param>
        /// <param name="coord2">The second coordinate.</param>
        /// <returns>Distance between the two coordinates in meters</returns>
        public static double calculateDistance(Coordinate coord1, Coordinate coord2)
        {
            double theta = coord1.X - coord2.X;
            double dist = (Math.Sin(deg2rad(coord1.Y)) * Math.Sin(deg2rad(coord2.Y))) +
                        (Math.Cos(deg2rad(coord1.Y)) * Math.Cos(deg2rad(coord2.Y)) * Math.Cos(deg2rad(theta)));
            dist = Math.Acos(dist);
            dist = rad2deg(dist);
            dist = dist * 60 * 1.1515 * 1.609344; // to kilometers
            dist = dist * 1000; // to meters
            return dist;
        }
    }
}