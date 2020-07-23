using System;

namespace BikeDataProject.API.Models
{
    /// <summary>
    /// Contains the attributes for the publishment of data.
    /// </summary>
    public class PublishData
    {
        /// <summary>
        /// The total number of rides.
        /// </summary>
        public long TotalRides {get;set;}

        /// <summary>
        /// The total distance.
        /// </summary>
        public long TotalDistance {get;set;}

        /// <summary>
        /// The total duration.
        /// </summary>
        public long TotalDuration {get;set;}
    }
}