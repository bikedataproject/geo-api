using Microsoft.EntityFrameworkCore.Migrations;

namespace BikeDataProject.API.Migrations
{
    public partial class FillUserContributionsRelation : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateIndex(
                name: "IX_UserContributions_UserId",
                table: "UserContributions",
                column: "UserId");

            migrationBuilder.AddForeignKey(
                name: "FK_UserContributions_Users_UserId",
                table: "UserContributions",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "UserId",
                onDelete: ReferentialAction.Cascade);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_UserContributions_Users_UserId",
                table: "UserContributions");

            migrationBuilder.DropIndex(
                name: "IX_UserContributions_UserId",
                table: "UserContributions");
        }
    }
}
