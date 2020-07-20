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
        /// <value><c>True</c> is the data comes from a mock provider <c>False</c> if it's the otherwise case.</value>
        public bool IsFromMockProvider { get; set; }
    }
}