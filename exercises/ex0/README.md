# Working with the SAP HANA Cloud JSON Document Store

In this exercise, you will...

## Level 2 Heading

After completing these steps you will have....

1.	Click here.
<br>![](/exercises/ex0/images/00_00_0010.png)

2.	Insert this code.
``` SQL
/********************************/
-- Unit 2 Manage JSON
/********************************/
-- We have imported OSM street network and POIs via python/overpass into a collection


/********************************/
-- ROAD NETWORK
/********************************/
-- Query COLLECTION
SELECT * FROM "HANA10"."C_STREET_NETWORK" WHERE "type" = 'node' LIMIT 10;
SELECT * FROM "HANA10"."C_STREET_NETWORK" WHERE "type" = 'way' LIMIT 10;

SELECT "type", COUNT(*) AS C 
	FROM "HANA10"."C_STREET_NETWORK" 
	GROUP BY "type";

SELECT "type", "tags"."highway", COUNT(*) AS C 
	FROM "HANA10"."C_STREET_NETWORK" 
	GROUP BY "type", "tags"."highway" 
	ORDER BY C DESC;

-- The "ways" contain an array of "nodes", e.g. "nodes": [99549558,1029814722,8502705960,1700923338]
-- We can unnest this array.
-- We will later use unnesting to create a graph from the street network
SELECT "type", "id", "tags"."name", NODE 
	FROM "HANA10"."C_STREET_NETWORK"
	UNNEST "nodes" AS NODE
	WHERE "type" = 'way' LIMIT 100;



/********************************/
-- POIS
/********************************/
SELECT COUNT(*) FROM "HANA10"."C_POIS";

SELECT * FROM "HANA10"."C_POIS" LIMIT 10;

SELECT "tags" FROM "HANA10"."C_POIS" LIMIT 10;

SELECT "tags"."amenity", COUNT(*) AS C 
	FROM "HANA10"."C_POIS" 
	GROUP BY "tags"."amenity" 
	ORDER BY C DESC;
  ```

## Summary

Now that you have ... 
Continue to - [Exercise 1 - Exercise 1 Description](../ex1/README.md)
