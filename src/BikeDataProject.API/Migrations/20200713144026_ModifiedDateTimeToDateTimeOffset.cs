using System;
using Microsoft.EntityFrameworkCore.Migrations;

namespace BikeDataProject.API.Migrations
{
    public partial class ModifiedDateTimeToDateTimeOffset : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<DateTimeOffset>(
                name: "TimeStampStop",
                table: "Contributions",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "timestamp without time zone");

            migrationBuilder.AlterColumn<DateTimeOffset>(
                name: "TimeStampStart",
                table: "Contributions",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "timestamp without time zone");

            migrationBuilder.AlterColumn<DateTimeOffset[]>(
                name: "PointsTime",
                table: "Contributions",
                nullable: true,
                oldClrType: typeof(DateTime[]),
                oldType: "timestamp without time zone[]",
                oldNullable: true);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<DateTime>(
                name: "TimeStampStop",
                table: "Contributions",
                type: "timestamp without time zone",
                nullable: false,
                oldClrType: typeof(DateTimeOffset));

            migrationBuilder.AlterColumn<DateTime>(
                name: "TimeStampStart",
                table: "Contributions",
                type: "timestamp without time zone",
                nullable: false,
                oldClrType: typeof(DateTimeOffset));

            migrationBuilder.AlterColumn<DateTime[]>(
                name: "PointsTime",
                table: "Contributions",
                type: "timestamp without time zone[]",
                nullable: true,
                oldClrType: typeof(DateTimeOffset[]),
                oldNullable: true);
        }
    }
}
