using System;

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
    }
}