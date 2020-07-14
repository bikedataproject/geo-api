using System;

namespace BikeDataProject.API.Domain
{
    public class UserContribution
    {
        public Guid UserContributionId {get;set;} = Guid.NewGuid();

        public Guid UserId {get;set;}
        
        public Guid ContributionId {get;set;}
        
    }
}