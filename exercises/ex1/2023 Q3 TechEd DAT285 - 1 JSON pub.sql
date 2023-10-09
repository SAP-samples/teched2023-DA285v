/********************************/
-- Exercise 1 - Manage JSON Data
-- Make sure you've imported the OSM street network data by using the Jupyter Notebook
-- https://github.com/SAP-samples/teched2023-DA285v/blob/main/exercises/ex1/2023%20Q3%20TechEd%20DAT285%20OSM%20load.ipynb
/********************************/

-- Create a schema for the data.
CREATE SCHEMA "DAT285";

/********************************/
-- STREET NETWORK
/********************************/
-- Inspect the collection
SELECT * FROM "DAT285"."C_STREET_NETWORK";

SELECT "type", COUNT(*) AS C 
	FROM "DAT285"."C_STREET_NETWORK" 
	GROUP BY "type";

-- There are "way"s and "node"s in the data: street segments and street junctions
SELECT * FROM "DAT285"."C_STREET_NETWORK" WHERE "type" = 'node' LIMIT 10;
SELECT * FROM "DAT285"."C_STREET_NETWORK" WHERE "type" = 'way' LIMIT 10;

-- Use the object style/dot notation to query
SELECT "type", "tags"."highway", COUNT(*) AS C 
	FROM "DAT285"."C_STREET_NETWORK" 
	GROUP BY "type", "tags"."highway" 
	ORDER BY C DESC;

-- The "ways" contain an array of "nodes", e.g. "nodes": [5307728890,7486344791,5307728892,...]
-- We can unnest this array.
SELECT "type", "id", "tags"."name", NODE 
	FROM "DAT285"."C_STREET_NETWORK"
	UNNEST "nodes" AS NODE
	WHERE "type" = 'way'
	LIMIT 100;


/********************************/
-- Let's copy the nodes and the ways documents into tables and create point geometries from lon/lat values.
/********************************/
-- Nodes
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
-- Ways
CREATE TABLE "DAT285"."STREET_NETWORK_WAYS" AS (	
	SELECT TO_BIGINT("id") AS "WAY_ID", "type" AS "TYPE", "tags"."highway" AS "HW", 
		"tags"."name" AS "NAME", "tags"."oneway" AS "ONEWAY", "tags"."maxspeed" AS MAXSPEED 
	FROM "DAT285"."C_STREET_NETWORK" 
	WHERE "type" = 'way' AND "tags"."highway" IS NOT NULL
);
SELECT * FROM "DAT285"."STREET_NETWORK_WAYS";

/********************************/
-- And table for the sequence of waypoints of a way
CREATE COLUMN TABLE "DAT285"."STREET_NETWORK_WAY_NODES"(
	"WAY_ID" BIGINT,
	"NODE_ID" BIGINT,
	"RN" BIGINT GENERATED ALWAYS AS IDENTITY
);
INSERT INTO "DAT285"."STREET_NETWORK_WAY_NODES" ("WAY_ID", "NODE_ID")
	SELECT TO_BIGINT("id") AS "WAY_ID", TO_BIGINT(NODE) AS "NODE_ID" 
	FROM "DAT285"."C_STREET_NETWORK"
	UNNEST "nodes" AS NODE
	WHERE "type" = 'way' AND "tags"."highway" IS NOT NULL
;
SELECT * FROM "DAT285"."STREET_NETWORK_WAY_NODES" ORDER BY "WAY_ID", "RN";



