using BikeDataProject.API.Models;
using BDPDatabase;
using Microsoft.AspNetCore.Mvc;
using Serilog;
using System;
using System.Collections.Generic;
using System.Linq;

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
        public IActionResult ReceiveGpsTrack([FromBody] Track track, [FromQuery] bool? test)
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

        /// <summary>
        /// Deletes contribution for a certain user identifier.
        /// </summary>
        /// <param name="userId">The user identifier.</param>
        /// <param name="test">The test parameter.</param>
        /// <returns>Status code to confirm (or not) that those had been deleted.</returns>
        [HttpDelete("/Track/DeleteTracks")]
        public IActionResult DeleteContributions([FromQuery] Guid userId, [FromQuery] bool? test)
        {
            if (userId == null || (test.HasValue && test.Value && userId == Guid.Empty))
            {
                return this.BadRequest();
            }

            try
            {
                var id = this._dbContext.GetUserId(userId);
                var contributionIds = this._dbContext.GetContributionsIds(id);

                var contributions = new List<Contribution>();
                var userContributions = this._dbContext.GetUserContributionsByContributionIds(contributionIds).ToList();

                foreach (var contributionId in contributionIds)
                {
                    contributions.Add(new Contribution() { ContributionId = contributionId });
                }

                this._dbContext.DeleteContributions(contributions, userContributions);
            }
            catch (Exception e)
            {
                Log.Error(e, $"Error not handled while trying to delete a contribution, userId: ${userId}");
                return new StatusCodeResult(500);
            }

            return this.Ok($"Contributions for user #${userId} had been deleted.");
        }
    }
}