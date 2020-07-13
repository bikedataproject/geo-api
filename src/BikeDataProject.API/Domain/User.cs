using System;
using System.Collections.Generic;

namespace BikeDataProject.API.Domain
{
    public class User
    {
        public int UserId {get;set;}       

        public string Provider {get;set;} 

        public string AccessToken {get;set;}

        public string RefreshToken {get;set;}

        public DateTime TokenCreationDate {get;set;}

        public List<UserContribution> UserContributions {get;set;}
        
    }
}