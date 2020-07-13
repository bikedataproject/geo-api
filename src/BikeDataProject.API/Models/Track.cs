using System.Collections.Generic;

namespace BikeDataProject.API.Models
{
    /// <summary>
    /// Contains the definition for a track from the associated mobile app.
    /// </summary>
    public class Track
    {
        public IList<Location> Locations {get;set;}

        public int UserId {get;set;}
    }
}