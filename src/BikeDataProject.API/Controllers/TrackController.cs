using System;
using System.Collections.Generic;
using System.Linq;
using BDPDatabase;
using BikeDataProject.API.Models;
using Microsoft.AspNetCore.Mvc;

namespace BikeDataProject.API.Controllers
{
    /// <summary>
    /// Contains the code needed to handle data coming from the mobile application.
    /// </summary>
    public class TrackController : ControllerBase
    {
        private readonly BikeDataDbContext _dbContext;

        /// <summary>
        /// Instanciates a new instance of the <see cref="TrackController"></see>.
        /// </summary>
        /// <param name="dbContext"></param>
        public TrackController(BikeDataDbContext dbContext) => this._dbContext = dbContext;

        /// <summary>
        /// Gets the total distance.
        /// </summary>
        /// <returns></returns>
        [HttpGet("/Track/Distance")]
        public IActionResult GetTotalDistance()
        {
            var result = this._dbContext.GetTotalDistance();
            return this.Ok(result);
        }

        /// <summary>
        /// Posts a track and stores it.
        /// </summary>
        /// <param name="track">The track.</param>
        /// <param name="test">The test boolean.</param>
        /// <returns></returns>
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
                var userId = this._dbContext.GetUserId(track.UserId);
                if (userId != 0)
                {
                    this._dbContext.AddContribution(contribution);
                    this._dbContext.SaveChanges();
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