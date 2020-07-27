using System;
using System.Runtime.Serialization;

namespace BikeDataProject.API.Models
{
    /// <summary>
    /// Represents an object of type <see cref="Location"></see>.
    /// </summary>
    public class Location
    {

        /// <summary>
        /// The latitude. 
        /// </summary>
        /// <value>Double representing the Latitude.</value>
        public double Latitude { get; set; }

        /// <summary>
        /// The longitude.
        /// </summary>
        /// <value>Double representing the Longitude.</value>
        public double Longitude { get; set; }

        /// <summary>
        /// The altitude.
        /// </summary>
        /// <value>Double representing the Altitude.</value>
        public double Altitude { get; set; }

        /// <summary>
        /// The date time offset.
        /// </summary>
        /// <value>DateTime alongside with a timezone</value>
        public DateTimeOffset DateTimeOffset { get; set; }

        /// <summary>
        /// Is From Mock Provider.
        /// </summary>
        /// <c>True</c> if the data comes from a mock provider <c>False</c> if it does not come from a mock provider.
        public bool IsFromMockProvider { get; set; }
    }
}