/********************************/
-- Ex 4
-- Make sure you've run ex 2 
/********************************/

/************************************/
-- Landuse classification
-- 1 We used a hexagon grid to tesselate our area
-- 2 For each hex cell we calculated the areas of the different building types
-- 3 Then, we run k means clustering to derive landuse clusters
/************************************/
-- This is the view we built in U1
SELECT * FROM "DAT285"."T_GRID_FEATURES_STRUCTURE_OCCCLS" ORDER BY "ID";


/*******************************/
-- metadata, ie list of features used in the model
CREATE OR REPLACE VIEW "DAT285"."PAL_METADATA_FOR_STRUC_CLUSTERING" AS (
	SELECT DISTINCT "FEATURE", 'CONTINUOUS' AS "FEATURE_TYPE" 
		FROM "DAT285"."V_GRID_FEATURES_STRUCTURE_OCCCLS" 
);
SELECT * FROM "DAT285"."PAL_METADATA_FOR_STRUC_CLUSTERING";


/*******************************/
-- data x features
CREATE OR REPLACE VIEW "DAT285"."PAL_DATA_FOR_STRUC_CLUSTERING" AS (
	SELECT TO_NVARCHAR("ID") AS "ID", "FEATURE", TO_NVARCHAR("VALUE") AS "VALUE", 1 AS "PURPOSE" FROM (
		SELECT OBJ."ID", FEAT."FEATURE", COALESCE(OBS."SUM_AREA"/OBS."SUM_AREA_IN_CELL", 0) AS "VALUE" 
			FROM (SELECT DISTINCT "ID" FROM "DAT285"."V_GRID_FEATURES_STRUCTURE_OCCCLS") AS OBJ
			FULL OUTER JOIN "DAT285"."PAL_METADATA_FOR_STRUC_CLUSTERING" AS FEAT ON 1 = 1
			LEFT OUTER JOIN "DAT285"."V_GRID_FEATURES_STRUCTURE_OCCCLS" AS OBS ON OBJ."ID" = OBS."ID" AND FEAT."FEATURE" = OBS."FEATURE"
	)
);
SELECT * FROM "DAT285"."PAL_DATA_FOR_STRUC_CLUSTERING" ORDER BY "ID" DESC, "FEATURE";


/*******************************/
-- Parameter table to configure the k means algorithm
DROP TABLE "DAT285"."PAL_PARAMS_FOR_STRUC_CLUSTERING"; 
CREATE COLUMN TABLE "DAT285"."PAL_PARAMS_FOR_STRUC_CLUSTERING" (
	"NAME" VARCHAR (50),
	"INT_VALUE" INTEGER,
	"DOUBLE_VALUE" DOUBLE,
	"STRING_VALUE" VARCHAR (100)
); 

-- AKMEANS
INSERT INTO "DAT285"."PAL_PARAMS_FOR_STRUC_CLUSTERING" VALUES ('FUNCTION', NULL, NULL, 'AKMEANS');
INSERT INTO "DAT285"."PAL_PARAMS_FOR_STRUC_CLUSTERING" VALUES ('THREAD_RATIO', NULL, 1.0, NULL); 
--INSERT INTO "DAT285"."PAL_PARAMS_FOR_STRUC_CLUSTERING" VALUES ('N_CLUSTERS', 6, NULL, NULL);
INSERT INTO "DAT285"."PAL_PARAMS_FOR_STRUC_CLUSTERING" VALUES ('N_CLUSTERS_MIN', 2, NULL, NULL);
INSERT INTO "DAT285"."PAL_PARAMS_FOR_STRUC_CLUSTERING" VALUES ('N_CLUSTERS_MAX', 9, NULL, NULL);
INSERT INTO "DAT285"."PAL_PARAMS_FOR_STRUC_CLUSTERING" VALUES ('INIT', 4, NULL, NULL);
INSERT INTO "DAT285"."PAL_PARAMS_FOR_STRUC_CLUSTERING" VALUES ('DISTANCE_LEVEL', 2, NULL, NULL); 
INSERT INTO "DAT285"."PAL_PARAMS_FOR_STRUC_CLUSTERING" VALUES ('MAX_ITER', 100, NULL, NULL); 
INSERT INTO "DAT285"."PAL_PARAMS_FOR_STRUC_CLUSTERING" VALUES ('TOL', NULL, 1.0E-6, NULL); 
--INSERT INTO "DAT285"."PAL_PARAMS_FOR_STRUC_CLUSTERING" VALUES ('CATEGORY_WEIGHTS', NULL, 0.5, NULL);


/*******************************/
-- RUN
DROP TABLE "DAT285"."PAL_LANDUSE_STRUC_RESULT";
DROP TABLE "DAT285"."PAL_LANDUSE_STRUC_CENTERS";
DO BEGIN
	meta_data_tab = SELECT * FROM "DAT285"."PAL_METADATA_FOR_STRUC_CLUSTERING";
	data_tab = SELECT * FROM "DAT285"."PAL_DATA_FOR_STRUC_CLUSTERING"; 
	params_tab = SELECT * FROM "DAT285"."PAL_PARAMS_FOR_STRUC_CLUSTERING";

	CALL "_SYS_AFL"."PAL_UNIFIED_CLUSTERING_PIVOT"(:meta_data_tab, :data_tab, :params_tab, res, centers, model, stats, optparams, t1, t2);

	CREATE TABLE "DAT285"."PAL_LANDUSE_STRUC_RESULT" AS (SELECT * FROM :res);
	CREATE TABLE "DAT285"."PAL_LANDUSE_STRUC_CENTERS" AS (SELECT "CLUSTER_ID", TO_NVARCHAR("VARIABLE_NAME") AS "FEATURE", TO_DOUBLE("VALUE") AS "VALUE" FROM :centers);	
END;


/***************************/
-- Inspect clusters
-- Cluster sizes
SELECT "CLUSTER_ID", COUNT(*) AS C 
	FROM "DAT285"."PAL_LANDUSE_STRUC_RESULT" 
	GROUP BY "CLUSTER_ID"
	ORDER BY "CLUSTER_ID";
-- Cluster descriptions
CREATE OR REPLACE VIEW "DAT285"."PAL_LANDUSE_STRUCTURE_CLUSTER_DESCRIPTION" AS (
	SELECT "CLUSTER_ID", STRING_AGG("FEATURE"||' ('||ROUND("VALUE", 3)||')', '; ') AS "DESCRIPTION" 
		FROM (
			SELECT "CLUSTER_ID", "FEATURE", "VALUE", ROW_NUMBER() OVER (PARTITION BY "CLUSTER_ID" ORDER BY "VALUE" DESC) AS RN
				FROM "DAT285"."PAL_LANDUSE_STRUC_CENTERS"
		)
		WHERE RN <= 3
		GROUP BY "CLUSTER_ID"
);
SELECT * FROM "DAT285"."PAL_LANDUSE_STRUCTURE_CLUSTER_DESCRIPTION" ORDER BY "CLUSTER_ID";

-- Generate a result view for visualization
CREATE OR REPLACE VIEW "DAT285"."O_LANDUSE_STRUCTURES" AS (
	SELECT G."ID", G."CLUSTER_CELL", C."CLUSTER_ID", C."DISTANCE", C."SLIGHT_SILHOUETTE", T."DESCRIPTION", 
	LEFT(T."DESCRIPTION", LOCATE(T."DESCRIPTION", ' ')) AS "DESCRIPTION_SHORT"
		FROM "DAT285"."V_GRID" AS G 
		INNER JOIN "DAT285"."PAL_LANDUSE_STRUC_RESULT" AS C ON G."ID" = C."ID"
		LEFT JOIN "DAT285"."PAL_LANDUSE_STRUCTURE_CLUSTER_DESCRIPTION" AS T ON C."CLUSTER_ID" = T."CLUSTER_ID"
);
SELECT * FROM "DAT285"."O_LANDUSE_STRUCTURES";




	
	
	
	