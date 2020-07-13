using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

namespace BikeDataProject.API.Migrations
{
    public partial class FillContributionsTable : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Contributions",
                columns: table => new
                {
                    ContributionId = table.Column<int>(nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    UserAgent = table.Column<string>(nullable: true),
                    Distance = table.Column<int>(nullable: false),
                    TimeStampStart = table.Column<DateTime>(nullable: false),
                    TimeStampStop = table.Column<DateTime>(nullable: false),
                    Duration = table.Column<int>(nullable: false),
                    PointsGeom = table.Column<byte[]>(nullable: true),
                    PointsTime = table.Column<DateTime[]>(nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Contributions", x => x.ContributionId);
                });
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Contributions");
        }
    }
}
