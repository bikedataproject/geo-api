using System;
using System.Collections.Generic;
using System.Linq;
using BDPDatabase;
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
        public IActionResult ReceiveGpsTrack([FromBody]Track track, [FromQuery]bool? test)
        {
            if (!track.Locations.Any() || track.UserId == null || ((!test.HasValue || !test.Value) && track.UserId == Guid.Empty))
            {
                return this.NoContent();
            }

            var locations = track.ToLocations();

            try
            {
                var contribution = locations.ToContribution();
                this._dbContext.AddContribution(contribution);
                var userId = this._dbContext.GetUserId(track.UserId);
                if (userId != 0)
                {
                    this._dbContext.AddUserContribution(track.ToUserContribution(contribution.ContributionId, userId));
                    this._dbContext.SaveChanges();
                }

                return this.Ok();
            }
            catch (Exception e)
            {
                return this.Problem(e.Message, statusCode: 500);
            }
        }
    }
}