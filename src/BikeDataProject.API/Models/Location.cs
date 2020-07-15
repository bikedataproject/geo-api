using System;
using System.Runtime.Serialization;

namespace BikeDataProject.API.Models
{
    public class Location
    {

        public double Latitude { get; set; }

        public double Longitude { get; set; }

        public double Altitude { get; set; }

        public DateTimeOffset DateTimeOffset { get; set; }

        public bool IsFromMockProvider { get; set; }
    }
}