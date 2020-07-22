using System;
using System.Collections.Generic;

namespace BikeDataProject.API.Models
{
    /// <summary>
    /// Contains the definition for a track from the associated mobile app.
    /// </summary>
    public class Track
    {
        /// <summary>
        /// The locations.
        /// </summary>
        /// <parameter name="Locations">A collection of <see cref="Location"></see>.</parameter>
        /// <returns>A new collection of <see cref="Location"></see>. if there's no predefined value.</returns>
        public IList<Location> Locations { get; set; } = new List<Location>();

        /// <summary>
        /// The user identifier. 
        /// </summary>
        /// <value>A guid</value>
        public Guid UserId { get; set; }
    }
}