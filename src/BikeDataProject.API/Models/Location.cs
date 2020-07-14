using System;

namespace BikeDataProject.API.Models
{
    public class Location
    {

        public double Latitude { get; set; }

        public double Longitude { get; set; }

        public double Altitude { get; set; }

        public DateTimeOffset Timestamp { get; set; }

        public bool IsFromMockProvider { get; set; }
    }
}