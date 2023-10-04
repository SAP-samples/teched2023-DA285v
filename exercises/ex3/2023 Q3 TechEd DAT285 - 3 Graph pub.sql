/********************************/
-- Ex 3
-- Make sure you've imported the street network data
-- 1 either by using the Jupyter Notebook and running Ex 1 
-- 2 or the SAP HANA Cloud Database Explorer

/********************************/
SELECT * FROM "DAT285"."STREET_NETWORK_VERTICES";
SELECT * FROM "DAT285"."STREET_NETWORK_WAYS";
SELECT * FROM "DAT285"."STREET_NETWORK_WAY_NODES" ORDER BY "WAY_ID", "RN";

/********************************/
-- Create edges from the waypoints
CREATE TABLE "DAT285"."STREET_NETWORK_EDGES"(
	"EDGE_ID" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	"WAY_ID" BIGINT,
	"SOURCE" BIGINT NOT NULL,
	"TARGET" BIGINT NOT NULL,
	"SHAPE_4326" ST_GEOMETRY(4326),
	"SHAPE_3857" ST_GEOMETRY(3857),
	"LENGTH" DOUBLE
);

	
INSERT INTO "DAT285"."STREET_NETWORK_EDGES" ("WAY_ID", "SOURCE", "TARGET", "SHAPE_4326", "SHAPE_3857", "LENGTH")
WITH "CANDIDATES" AS (
	SELECT N.*, GEOM."POINT_4326", GEOM."POINT_3857"
		FROM "DAT285"."STREET_NETWORK_WAY_NODES" AS N -- the way nodes ARE ordered BY ROW number
		LEFT JOIN "DAT285"."STREET_NETWORK_VERTICES" AS GEOM ON N.NODE_ID = GEOM.NODE_ID -- the street vertices contain the geometry
	)
	SELECT N1."WAY_ID" AS "WAY_ID", N1."NODE_ID" AS "SOURCE", N2."NODE_ID" AS "TARGET", 
		ST_MAKELINE(N1."POINT_4326", N2."POINT_4326") AS "SHAPE_4326",
		ST_MAKELINE(N1."POINT_3857", N2."POINT_3857") AS "SHAPE_3857",
		ST_MAKELINE(N1."POINT_3857", N2."POINT_3857").ST_LENGTH('meter') AS "LENGTH"
		FROM "CANDIDATES" AS N1
		INNER JOIN "CANDIDATES" AS N2 ON N1."WAY_ID" = N2."WAY_ID" AND N1.RN + 1 = N2.RN -- joining the candidates WITH itself
		ORDER BY "WAY_ID";

SELECT * FROM "DAT285"."STREET_NETWORK_EDGES"; 

-- Adding additional attributes to the edges
CREATE OR REPLACE VIEW "DAT285"."V_STREET_NETWORK_EDGES" AS ( 	
	SELECT E."EDGE_ID", E."SOURCE", E."TARGET", E."WAY_ID", E."SHAPE_4326", E."SHAPE_3857", E."LENGTH", 
		W."TYPE", W."HW", W."NAME", W."ONEWAY", W."MAXSPEED"
	FROM "DAT285"."STREET_NETWORK_EDGES" AS E
	LEFT JOIN "DAT285"."STREET_NETWORK_WAYS" AS W ON E."WAY_ID" = W."WAY_ID"
);
SELECT * FROM "DAT285"."V_STREET_NETWORK_EDGES";

CREATE OR REPLACE VIEW "DAT285"."V_STREET_NETWORK_VERTICES" AS (
	SELECT * FROM "DAT285"."STREET_NETWORK_VERTICES" 
);




/********************************/
-- simplification
-- identify the nodes that belong to two or more ways. these are the relevant nodes on which to split the ways to make edges
SELECT NODE_ID, COUNT(DISTINCT WAY_ID) AS "WAYS" FROM "DAT285"."STREET_NETWORK_WAY_NODES" GROUP BY NODE_ID ORDER BY "WAYS" DESC;
-- persist
ALTER TABLE "DAT285"."STREET_NETWORK_VERTICES" ADD ("NO_WAYS" INT);
MERGE INTO "DAT285"."STREET_NETWORK_VERTICES" AS G USING
	(SELECT NODE_ID, COUNT(DISTINCT WAY_ID) AS "NO_WAYS" FROM "DAT285"."STREET_NETWORK_WAY_NODES" GROUP BY NODE_ID) AS N
	ON G.NODE_ID = N.NODE_ID
	WHEN MATCHED THEN UPDATE SET G.NO_WAYS = N.NO_WAYS;

CREATE TABLE "DAT285"."STREET_NETWORK_EDGES_SIMPLIFIED"(
	"EDGE_ID" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	"WAY_ID" BIGINT,
	"SOURCE" BIGINT NOT NULL,
	"TARGET" BIGINT NOT NULL,
	"SHAPE_4326" ST_GEOMETRY(4326),
	"SHAPE_3857" ST_GEOMETRY(3857),
	"LENGTH" DOUBLE
);

-- 
INSERT INTO "DAT285"."STREET_NETWORK_EDGES_SIMPLIFIED" ("WAY_ID", "SOURCE", "TARGET", "SHAPE_4326", "SHAPE_3857", "LENGTH")
WITH "CANDIDATES" AS (
	SELECT *, COUNT("SEGMENT_MARKER") OVER (PARTITION BY "WAY_ID" ORDER BY RN ASC) AS "SEG" FROM (
		SELECT N.*, GEOM."NO_WAYS", GEOM."POINT_4326", GEOM."POINT_3857",
			CASE 
				WHEN LAG(N.NODE_ID, 1) OVER(PARTITION BY N.WAY_ID ORDER BY RN ASC) IS NULL THEN 'start'
				WHEN LEAD(N.NODE_ID, 1) OVER(PARTITION BY N.WAY_ID ORDER BY RN ASC) IS NULL THEN 'end' 
				WHEN GEOM.NO_WAYS > 1 THEN 'inter' END AS "SEGMENT_MARKER"
			FROM "DAT285"."STREET_NETWORK_WAY_NODES" AS N
			INNER JOIN "DAT285"."STREET_NETWORK_VERTICES" AS GEOM ON N."NODE_ID" = GEOM."NODE_ID"
		)
	),
	"SEGMENTS" AS (
		SELECT "WAY_ID", "SEG", ST_MAKELINEAGGR("POINT_4326" ORDER BY RN ASC) AS "LINE_4326", ST_MAKELINEAGGR("POINT_3857" ORDER BY RN ASC) AS "LINE_3857" 
			FROM "CANDIDATES" GROUP BY "WAY_ID", "SEG"
	),
	"WAYPOINTS" AS (SELECT * FROM "CANDIDATES" WHERE "SEGMENT_MARKER" IS NOT NULL) 
SELECT N1."WAY_ID", N1."NODE_ID" AS "SOURCE", N2."NODE_ID" AS "TARGET", 
		S.LINE_4326.ST_ADDPOINT(N2."POINT_4326", -1) AS "LINE_4326",
		S.LINE_3857.ST_ADDPOINT(N2."POINT_3857", -1) AS "LINE_3857", 
		S.LINE_3857.ST_ADDPOINT(N2."POINT_3857", -1).ST_LENGTH('meter') AS "LENGTH"
	FROM "WAYPOINTS" AS N1
	LEFT JOIN "SEGMENTS" AS S ON N1."WAY_ID" = S."WAY_ID" AND N1."SEG" = S."SEG"
	INNER JOIN "WAYPOINTS" AS N2 ON N1."WAY_ID" = N2."WAY_ID" AND N1."SEG" + 1 = N2."SEG"
	ORDER BY N1."WAY_ID", N1."RN"
;

SELECT * FROM "DAT285"."STREET_NETWORK_EDGES_SIMPLIFIED";
SELECT * FROM "DAT285"."STREET_NETWORK_EDGES_SIMPLIFIED" WHERE "WAY_ID" = 991152375;
SELECT * FROM "DAT285"."STREET_NETWORK_EDGES" WHERE "WAY_ID" = 991152375;

-- add a flag if node appears in the edges_simplified table
ALTER TABLE "DAT285"."STREET_NETWORK_VERTICES" ADD("EDGE_SIMPLIFIED_RELEVANT" BOOLEAN DEFAULT FALSE);
UPDATE "DAT285"."STREET_NETWORK_VERTICES"
	SET "EDGE_SIMPLIFIED_RELEVANT" = TRUE 
	WHERE NODE_ID IN (SELECT "SOURCE" FROM "DAT285"."STREET_NETWORK_EDGES_SIMPLIFIED")
		OR NODE_ID IN (SELECT "TARGET" FROM "DAT285"."STREET_NETWORK_EDGES_SIMPLIFIED");

-- 
CREATE OR REPLACE VIEW "DAT285"."V_STREET_NETWORK_EDGES_SIMPLIFIED" AS ( 	
	SELECT E."EDGE_ID", E."SOURCE", E."TARGET", E."WAY_ID", E."SHAPE_4326", E."SHAPE_3857", E."LENGTH", W."TYPE", W."HW", W."NAME", W."ONEWAY", W."MAXSPEED"
	FROM "DAT285"."STREET_NETWORK_EDGES_SIMPLIFIED" AS E
	LEFT JOIN "DAT285"."STREET_NETWORK_WAYS" AS W ON E."WAY_ID" = W."WAY_ID"
);

CREATE OR REPLACE VIEW "DAT285"."V_STREET_NETWORK_VERTICES_SIMPLIFIED" AS (
	SELECT * FROM "DAT285"."STREET_NETWORK_VERTICES" 
	WHERE "EDGE_SIMPLIFIED_RELEVANT" = TRUE 
);

SELECT COUNT(*) FROM "DAT285"."V_STREET_NETWORK_VERTICES";
SELECT COUNT(*) FROM "DAT285"."V_STREET_NETWORK_VERTICES_SIMPLIFIED";



/*************************/
-- simplified graph
/*************************/
CREATE OR REPLACE GRAPH WORKSPACE "DAT285"."STREET_NETWORK_GRAPH_SIMPLIFIED"
	EDGE TABLE "DAT285"."V_STREET_NETWORK_EDGES_SIMPLIFIED"
		SOURCE COLUMN "SOURCE"
		TARGET COLUMN "TARGET"
		KEY COLUMN "EDGE_ID"
	VERTEX TABLE "DAT285"."V_STREET_NETWORK_VERTICES_SIMPLIFIED"
		KEY COLUMN "NODE_ID";

	

/*************************/
-- Run community detection
/*************************/
SELECT "LENGTH" FROM "DAT285"."STREET_NETWORK_EDGES_SIMPLIFIED" ORDER BY "LENGTH" DESC;

-- community detection on streets
CREATE OR REPLACE PROCEDURE "DAT285"."GS_COMMUNITY" (
	OUT o_res TABLE("NODE_ID" BIGINT, "COMM" BIGINT)
)
LANGUAGE GRAPH READS SQL DATA AS
BEGIN
	Graph g = Graph("DAT285","STREET_NETWORK_GRAPH_SIMPLIFIED");
	--SEQUENCE<MULTISET<VERTEX>> communities = COMMUNITIES_LOUVAIN(:g, 1, (Edge e) => DOUBLE{ return 8400.0-:e."LENGTH"; } );
	SEQUENCE<MULTISET<VERTEX>> communities = COMMUNITIES_LOUVAIN(:g, 1, (Edge e) => DOUBLE{ return 1.0 - :e."LENGTH"/8400.0; } );
	MAP<VERTEX, BIGINT> communityMap = TO_ORDINALITY_MAP(:communities);
	o_res = SELECT :v."NODE_ID", :communityMap[:v] FOREACH v in VERTICES(:g);
END;
CALL "DAT285"."GS_COMMUNITY"(?);


-- store the community information in the vertex table
ALTER TABLE "DAT285"."STREET_NETWORK_VERTICES" ADD ("COMM" BIGINT);
DO()
BEGIN
	CALL "DAT285"."GS_COMMUNITY"(o_res);
	MERGE INTO "DAT285"."STREET_NETWORK_VERTICES" AS DAT
		USING :o_res AS UPD ON DAT.NODE_ID = UPD.NODE_ID
		WHEN MATCHED THEN UPDATE SET DAT."COMM" = UPD."COMM";
END;

-- Rebuild view
CREATE OR REPLACE VIEW "DAT285"."V_STREET_NETWORK_VERTICES_SIMPLIFIED" AS (
	SELECT * FROM "DAT285"."STREET_NETWORK_VERTICES" 
	WHERE "EDGE_SIMPLIFIED_RELEVANT" = TRUE 
);


SELECT COUNT(DISTINCT "COMM") FROM "DAT285"."V_STREET_NETWORK_VERTICES_SIMPLIFIED";

SELECT "COMM", COUNT(*) AS C 
	FROM "DAT285"."V_STREET_NETWORK_VERTICES_SIMPLIFIED"
	GROUP BY "COMM" ORDER BY C DESC;

-- persist communities
SELECT "COMM", ST_UNIONAGGR("VC") AS "SHAPE_3857" FROM (
	SELECT "COMM", ST_VoronoiCell("POINT_3857", -5) OVER() AS VC
	FROM "DAT285"."V_STREET_NETWORK_VERTICES_SIMPLIFIED"
) GROUP BY COMM;
CREATE TABLE "DAT285"."T_COMMUNITIES_VOR" AS (
	SELECT COMM, ST_UNIONAGGR(VC) AS SHAPE_3857 FROM (
		SELECT COMM, ST_VoronoiCell("POINT_3857", -5) OVER() AS VC
		FROM "DAT285"."V_STREET_NETWORK_VERTICES_SIMPLIFIED"
	) GROUP BY COMM HAVING COUNT(*) > 5
);