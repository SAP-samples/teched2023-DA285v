/********************************/
-- Exercise 2 - Work with Spatial Data
/********************************/
-- Create a schema for the data (if you haven't already done so in exercise 1).
CREATE SCHEMA "DAT285";
-- The geometries of the building structures are defined in a spatial reference system.
-- We need to make SAP HANA aware of the spatial reference system.
CREATE PREDEFINED SPATIAL REFERENCE SYSTEM IDENTIFIED BY 4269;

/********************************/
-- Make sure you've imported the charging stations and the building structures data
-- by using the SAP HANA Cloud Database Explorer 
/********************************/


/*******************************/
-- Charging Stations
/*******************************/
-- Review the charging stations data
SELECT * FROM "DAT285"."CHARGING_STATIONS";
SELECT COUNT(*) FROM "DAT285"."CHARGING_STATIONS";

-- The location is encoded in two columns: Latitude and Longitude
-- We will create a "real" geometries
ALTER TABLE "DAT285"."CHARGING_STATIONS" ADD ("POINT_4326" ST_GEOMETRY(4326));
ALTER TABLE "DAT285"."CHARGING_STATIONS" ADD ("POINT_3857" ST_GEOMETRY(3857));
UPDATE "DAT285"."CHARGING_STATIONS" SET "POINT_4326" = NEW ST_POINT("Longitude", "Latitude", 4326);
UPDATE "DAT285"."CHARGING_STATIONS" SET "POINT_3857" = "POINT_4326".ST_TRANSFORM(3857);
-- Convert the "open Date" string values to dates
ALTER TABLE "DAT285"."CHARGING_STATIONS" ALTER ("Open Date" DATE);
-- and add a primary key
ALTER TABLE "DAT285"."CHARGING_STATIONS" ADD PRIMARY KEY ("ID");

-- Let's run a basic spatial clustering to understand the spatial distribution of charging stations
SELECT ST_ClusterID() AS "LOCATION_ID", ST_ClusterCell() AS "CCELL", COUNT(*) AS "NUM_STATIONS"
	FROM "DAT285"."CHARGING_STATIONS"
	GROUP CLUSTER BY "POINT_3857" USING HEXAGON X CELLS 500;

-- To bring this data to QGIS, we will simply wrap a view around.
CREATE OR REPLACE VIEW "DAT285"."V_CHARGING_STATIONS_HEX_CLUSTER" AS (
SELECT ST_ClusterID() AS "LOCATION_ID", ST_ClusterCell() AS "CCELL", COUNT(*) AS "NUM_STATIONS"
	FROM "DAT285"."CHARGING_STATIONS"
	GROUP CLUSTER BY "POINT_3857" USING HEXAGON X CELLS 500
);
	

/*******************************/
-- Building Structures
/*******************************/
-- Review the building structures data
SELECT * FROM "DAT285"."STRUCTURES";
SELECT COUNT(*) FROM "DAT285"."STRUCTURES";

-- The building data contains information about its use: Occupancy Classification
SELECT "occ_cls", COUNT(*) AS C
	FROM "DAT285"."STRUCTURES"
	GROUP BY "occ_cls"
	ORDER BY C DESC;
SELECT "prim_occ", COUNT(*) AS C
	FROM "DAT285"."STRUCTURES"
	GROUP BY "prim_occ"
	ORDER BY C DESC;

-- Let's explore some spatial feature using the building structures data
-- 1 Inspection
SELECT 
	"SHAPE_3857".ST_GeometryType() AS "GEOTYPE", 
	"SHAPE_3857".ST_SRID() AS "SRID", 
	"SHAPE_3857".ST_Area('meter') AS "AREA_M2", "SHAPE_3857" 
	FROM "DAT285"."STRUCTURES";


-- 2 Format conversion - single column
SELECT 
	"SHAPE_3857".ST_AsEWKT() AS "EWKT", 
	"SHAPE_3857".ST_AsGeoJSON() AS "GEOJSON", 
	"SHAPE_3857".ST_TRANSFORM(4326).ST_GeoHash(10) AS "GEOHASH", 
	ST_GeomFromGeoHash("SHAPE_3857".ST_TRANSFORM(4326).ST_GeoHash(10), 4326) AS "GEO_FROM_GEOHASH", 
	"SHAPE_3857" 
	FROM "DAT285"."STRUCTURES";
-- Format conversion - multi column format
WITH DAT AS (
	SELECT TO_INT("id") AS "ID", "occ_cls" AS "OCC_CLS", "SHAPE_3857" FROM "DAT285"."STRUCTURES" LIMIT 10
	)
SELECT 
	ST_AsEsriJSON("ID", "OCC_CLS", "SHAPE_3857".ST_TRANSFORM(4326) AS "SHAPE_4326", object_id_name => 'ID', coordinate_precision => 6, format => 'COMPACT') AS ESRI_JSON,
	ST_AsGeoJSON("ID", "OCC_CLS", "SHAPE_3857".ST_TRANSFORM(4326) AS "SHAPE_4326", feature_id_name => 'ID', coordinate_precision => 6, format => 'COMPACT') AS GEO_JSON
	FROM DAT;


-- 3 Generation - buffer, centroid, voronois
SELECT 
	"SHAPE_3857", 
	"SHAPE_3857".ST_Buffer(20, 'meter') AS "BUFFER", 
	"SHAPE_3857".ST_Centroid() AS "CENTROID" 
	FROM "DAT285"."STRUCTURES" LIMIT 100;

WITH DAT AS (
	SELECT "SHAPE_3857", "SHAPE_3857".ST_Centroid() AS "CENTROID" FROM "DAT285"."STRUCTURES" LIMIT 50
	)
SELECT "SHAPE_3857", "CENTROID", ST_VoronoiCell("CENTROID", 5) OVER () AS "V_CELL" 
	FROM DAT;


-- 4 Calculation - distance
SELECT "SHAPE_3857", ST_GeomFromWKT('POINT (-9071710.86541748 3307249.678466797)', 3857) AS P, 
	"SHAPE_3857".ST_Distance(ST_GeomFromWKT('POINT (-9071710.86541748 3307249.678466797)', 3857)) AS "DIST"
	FROM "DAT285"."STRUCTURES" 
	ORDER BY DIST ASC 
	LIMIT 100;




/********************************/
-- Generate features from Buildung Structures
-- These features will be leveraged for landuse classification later
/********************************/
-- Generate hexagon grid cells that covers our area
-- What's the spatial extent of our data?
SELECT "P1".ST_MAKELINE("P2").ST_ASEWKT() AS "LINE_3857", 
	"P1".ST_MAKELINE("P2").ST_TRANSFORM(4326).ST_ASEWKT() AS "LINE_4326", 
	"ENV".ST_ASEWKT() AS "RECT_3857", 
	ENV.ST_TRANSFORM(4326).ST_ASEWKT() AS "RECT_4326" FROM (
		SELECT NEW ST_POINT("ENV".ST_XMIN(), "ENV".ST_YMIN(), 3857) AS "P1", NEW ST_POINT("ENV".ST_XMAX(), "ENV".ST_YMAX(), 3857) AS "P2", "ENV" FROM (
			SELECT ST_EnvelopeAggr("SHAPE_3857") AS "ENV" FROM "DAT285"."STRUCTURES"
	)
);

-- Generate a hex grid
CREATE OR REPLACE VIEW "DAT285"."V_GRID" AS
	SELECT "I"||'#'||"J" AS "ID", "GEOM" AS "CLUSTER_CELL", GEOM.ST_CENTROID() AS "CENTROID" 
		FROM ST_HexagonGrid(
			500, 
			'VERTICAL', 
			ST_GEOMFROMEWKT('SRID=3857;LINESTRING (-9077450.8667 3295104.0223,-9045772.999 3328301.14435)')
		);
SELECT * FROM "DAT285"."V_GRID";

-- intersects and intersection
SELECT GRI."ID", "CLUSTER_CELL", STRU."id" AS "STRUCTURE_ID", 
	GRI."CLUSTER_CELL".ST_INTERSECTION(STRU."SHAPE_3857") AS "INTERSECTION", 
	GRI."CLUSTER_CELL".ST_INTERSECTION(STRU."SHAPE_3857").ST_AREA() AS "AREA", 
	STRU."occ_cls" AS "FEATURE"
	FROM "DAT285"."V_GRID" AS GRI
	INNER JOIN "DAT285"."STRUCTURES" AS STRU ON STRU."SHAPE_3857".ST_INTERSECTS(GRI."CLUSTER_CELL") = 1
	WHERE GRI."ID" = '-12079#3828';

-- Now we can use this hex grid and calculate the area covered by buildings
CREATE OR REPLACE VIEW "DAT285"."V_GRID_FEATURES_STRUCTURE_OCCCLS" AS ( 
	SELECT 'grid' AS "TYPE", "ID", "CLUSTER_CELL", 'structure' AS "FEATURE_TYPE", "FEATURE", "SUM_AREA",
		SUM("CNT") OVER(PARTITION BY "ID") AS "#FEATURES_IN_CELL",
		SUM("SUM_AREA") OVER(PARTITION BY "ID") AS "SUM_AREA_IN_CELL",
		SUM("SUM_AREA") OVER(PARTITION BY "FEATURE") AS "SUM_AREA_OF_FEATURE",
		SUM("CNT") OVER(PARTITION BY "FEATURE") AS "#CELLS_OF_FEATURE"
		FROM (
			SELECT "ID", "CLUSTER_CELL", "FEATURE", SUM("AREA") AS "SUM_AREA", 1 AS "CNT"
				FROM (
					SELECT GRI."ID", "CLUSTER_CELL", STRU."id" AS "STRUCTURE_ID", "CLUSTER_CELL".ST_INTERSECTION("SHAPE_3857").ST_AREA() AS "AREA",	"occ_cls" AS "FEATURE"
						FROM "DAT285"."V_GRID" AS GRI
						INNER JOIN "DAT285"."STRUCTURES" AS STRU ON STRU."SHAPE_3857".ST_INTERSECTS(GRI."CLUSTER_CELL") = 1
				)
				GROUP BY "ID", "CLUSTER_CELL", "FEATURE"
		)
);

SELECT "ID", "FEATURE", "SUM_AREA", "#FEATURES_IN_CELL", "SUM_AREA_IN_CELL", "SUM_AREA_OF_FEATURE"
	FROM "DAT285"."V_GRID_FEATURES_STRUCTURE_OCCCLS" ORDER BY "ID", "SUM_AREA";

CREATE TABLE "DAT285"."T_GRID_FEATURES_STRUCTURE_OCCCLS" AS (SELECT * FROM "DAT285"."V_GRID_FEATURES_STRUCTURE_OCCCLS");
SELECT * FROM "DAT285"."T_GRID_FEATURES_STRUCTURE_OCCCLS" ORDER BY "ID" DESC, "SUM_AREA" DESC;

