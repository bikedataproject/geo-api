using System.Collections.Generic;
using System.Linq;
using BikeDataProject.API.Domain;
using BikeDataProject.API.Models;
using Microsoft.AspNetCore.Mvc;

namespace BikeDataProject.API.Controllers
{
    public class TrackController : ControllerBase
    {
        private readonly BikeDataDbContext _dbContext;

        public TrackController(BikeDataDbContext dbContext) => this._dbContext = dbContext;

        [HttpGet("/Track/Distance")]
        public IActionResult GetTotalDistance()
        {
            var result = this._dbContext.GetTotalDistance();
            return this.Ok(result);
        }

        [HttpPost("/Track/StoreTrack")]
        public IActionResult ReceiveGpsTrack(Track track)
        {
            /*
             * [x] 1st step: We have to check the values to determine it's valid
             * 2nd step: Format the coordinates into a byte array (PostGisWriter)
             * 3rd step: Insert in the database
             */
            ICollection<Location> locations = new List<Location>();
            foreach (var location in track.Locations)
            {
                int index = track.Locations.IndexOf(location);
                if (location.IsFromMockProvider)
                {
                    continue;
                }                

                if (index != track.Locations.Count - 1)
                {
                    if (location.Timestamp < track.Locations.ElementAt(index + 1).Timestamp)
                    {
                        locations.Add(location);
                    }
                }
                else
                {
                    locations.Add(location);
                }
            }



            return this.NoContent();
        }
    }
}