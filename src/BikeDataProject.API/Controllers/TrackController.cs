using System;
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
            if (!track.Locations.Any() || track.UserId == 0)
            {
                return this.NoContent();
            }

            List<Location> locations = new List<Location>();
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

            try
            {
                var contribution = locations.ToContribution();
                this._dbContext.AddContribution(contribution);
                this._dbContext.AddUserContribution(track.ToUserContribution(contribution));
                return this.Ok();
            }
            catch (Exception e)
            {
                return this.Problem(e.Message, statusCode: 500);
            }
        }
    }
}