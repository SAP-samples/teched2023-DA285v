CREATE SCHEMA DAT285;
CREATE PREDEFINED SPATIAL REFERENCE SYSTEM IDENTIFIED BY 4269;

/********************************/
-- Ex 1
-- Make sure you've imported the street network data
-- 1 either by using the Jupyter Notebook 
-- 2 or the SAP HANA Cloud Database Explorer 
/********************************/

/********************************/
-- ROAD NETWORK
/********************************/
CREATE TABLE "DAT285"."STREET_NETWORK_VERTICES" (
	"NODE_ID" BIGINT PRIMARY KEY,
	"TYPE" NVARCHAR(10),
	"POINT_4326" ST_GEOMETRY(4326),
	"POINT_3857" ST_GEOMETRY(3857)
);
INSERT INTO "DAT285"."STREET_NETWORK_VERTICES"
	SELECT TO_BIGINT("id") AS "NODE_ID", "type" AS "TYPE", 
		NEW ST_POINT("lon", "lat", 4326) AS "POINT_4326",
		NEW ST_POINT("lon", "lat", 4326).ST_TRANSFORM(3857) AS "POINT_3857"
	FROM "DAT285"."C_STREET_NETWORK" WHERE "type" = 'node'
;
SELECT * FROM "DAT285"."STREET_NETWORK_VERTICES";


/********************************/
-- ways
CREATE TABLE "DAT285"."STREET_NETWORK_WAYS" AS (	
	SELECT TO_BIGINT("id") AS "WAY_ID", "type" AS "TYPE", "tags"."highway" AS HW, "tags"."name" AS "NAME", "tags"."oneway" AS "ONEWAY", 
		"tags"."maxspeed" AS MAXSPEED 
	FROM "DAT285"."C_STREET_NETWORK" 
	WHERE "type" = 'way' AND "tags"."highway" IS NOT NULL
);
SELECT * FROM "DAT285"."STREET_NETWORK_WAYS";

/********************************/
-- a table for the waypoints of the way
CREATE COLUMN TABLE "DAT285"."STREET_NETWORK_WAY_NODES"(
	"WAY_ID" BIGINT,
	"TYPE" NVARCHAR(5000) NOT NULL ,
	"NODE_ID" BIGINT,
	"RN" BIGINT GENERATED ALWAYS AS IDENTITY
);
INSERT INTO "DAT285"."STREET_NETWORK_WAY_NODES" ("WAY_ID", "TYPE", "NODE_ID")
	SELECT TO_BIGINT("id") AS "WAY_ID", "type" AS "TYPE", TO_BIGINT(N) AS "NODE_ID" 
	FROM "DAT285"."C_STREET_NETWORK"
	UNNEST "nodes" AS N
	WHERE "type" = 'way' AND "tags"."highway" IS NOT NULL
;
SELECT * FROM "DAT285"."STREET_NETWORK_WAY_NODES" ORDER BY "WAY_ID", "RN";



