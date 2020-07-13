using BikeDataProject.API.Domain;
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
    }
}