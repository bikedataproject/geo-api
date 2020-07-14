using System;
namespace BikeDataProject.API.Domain
{
    public class Contribution
    {
        public int ContributionId { get; set; }

        public string UserAgent { get; set; }

        public int Distance { get; set; }

        public DateTimeOffset TimeStampStart { get; set; }

        public DateTimeOffset TimeStampStop { get; set; }

        public int Duration { get; set; } //in seconds

        public byte[] PointsGeom { get; set; }

        public DateTimeOffset[] PointsTime { get; set; }


    }
}