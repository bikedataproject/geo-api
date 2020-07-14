using System;
namespace BikeDataProject.API.Domain
{
    public class Contribution
    {
        public Guid ContributionId {get;set;} = Guid.NewGuid();

        public string UserAgent {get;set;}

        public int Distance {get;set;}

        public DateTimeOffset TimeStampStart {get;set;}

        public DateTimeOffset TimeStampStop {get;set;}

        public int Duration {get;set;} //in seconds

        public byte[] PointsGeom {get;set;}

        public DateTimeOffset[] PointsTime {get;set;}

        
    }
}