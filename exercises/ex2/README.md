# Exercise 2 - Working with Spatial Data

In this exercise, we will analyse building structures and charging stations.
The building structures are sourced from the [FEMA Geospatial Ressource Center](https://gis-fema.hub.arcgis.com/pages/usa-structures) which provide geopackage files which can be opened in [QGIS](https://blogs.sap.com/2021/03/01/creating-a-playground-for-spatial-analytics/) and drag-and-dropped into SAP HANA. The charging station data is provided by the [National Renewable Energy Laboratory](https://www.nrel.gov/) as csv download or via an API.

For convenience, table exports can be found in the [data folder](../../data/).

Before loading the data, create a schema (if you haven't already done so in exercise 1) and create the spatial reference system in which the building structures geometries are defined.

```SQL
CREATE SCHEMA "DAT285";

CREATE PREDEFINED SPATIAL REFERENCE SYSTEM IDENTIFIED BY 4269;
```

Load the table exports `CHARGING_STATIONS.tar.gz` and `BUILDING_STRUCTURES.tar.gz` via the Database Explorer. Right-click on "catalog" and choose "Import Catalog Objects".

![](images/dbx1.png)

In the following dialog, choose the `.tar.gz` file and hit "import".

![](images/dbx2.png)

## Exercise 2.1 Basic analysis of charging stations point data<a name="21"></a>

Make sure you have loaded the charging stations table.




## Exercise 2.2 Analysis of building structures data

After completing these steps you will have...

1.	Enter this code.
```sql
SELECT * FROM DUMMY;
```

2.	Click here.
<br>![](/exercises/ex2/images/02_02_0010.png)

## Summary

You've now ...

Continue to - [Exercise 3 - Analyze Networks](../ex3/README.md)
