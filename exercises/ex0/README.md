# Getting Started

This section should give you an understanding of the base scenario and data. Additionally, we will describe the SAP HANA Cloud Trial setup in case you want to run the exercises yourself. As we will process the data using SQL, the SQL editor of SAP HANA Database Explorer (DBX) is sufficient from a tooling perspective. However, for the "full experience" we recommend DBeaver, QGIS (or Esri ArcGIS Pro) for spatial data, and Python/Jupyter notebooks to work with the SAP HANA client API for machine learning (hana-ml). At the end of this section, you will find links to additional information on SAP HANA Cloud Multi-Model.

## Base Data & Demo Scenario<a name="subex1"></a>

work with struct, evcs, and network
describe and link evcs demo

## Working with the Exercise Scripts

not sure if anything needs to be mentioned

You will find **file paths** in code. Depending on your environment the actual file path will vary based on location and OS type.

## SAP HANA Cloud Trial setup<a name="subex2"></a>

Exercises 2 and 3 can be run on a free SAP HANA Cloud Trial system. To get one, visit [SAP HANA Cloud Trial home](https://www.sap.com/cmp/td/sap-hana-cloud-trial.html). To run the optional exercises 1 (work with JSON data using the Document Store) and 2 (machine learning), you will need a full SAP HANA Cloud. Make sure to enable the **Script Server** and **Document Store**. Refer to [SAP HANA Cloud Administration with SAP HANA Cloud Central](https://help.sap.com/viewer/9ae9104a46f74a6583ce5182e7fb20cb/hanacloud/en-US/e379ccd3475643e4895b526296235241.html) for details.

The HANA database user for exercise 4 (machine learning) requires some roles and privileges
* Roles `AFL__SYS_AFL_AFLPAL_EXECUTE` and `AFL__SYS_AFL_AFLPAL_EXECUTE_WITH_GRANT_OPTION` to execute PAL algorithms
* System privileges `IMPORT` to run data uploads

## DBeaver, QGIS, GDAL, hana-ml, Cytoscape<a name="subex3"></a>

The SAP HANA Database Explorer provides an SQL editor, table viewer and data analysis tools, and a simple graph viewer. For a "full experience" we recommend the following tools in addition.

**DBeaver**<br>an open source database administration and development tool. You can run the exercise scripts in DBeaver and get simple spatial visualizations. See Mathias Kemeter's blog for [installation instructions](https://blogs.sap.com/2020/01/08/good-things-come-together-dbeaver-sap-hana-spatial-beer/).

**QGIS**<br>an open source Geographical Information System (GIS). QGIS can connect to SAP HANA and provides great tools for advanced maps. Again, read Mathias' blog to [get it up and running](https://blogs.sap.com/2021/03/01/creating-a-playground-for-spatial-analytics/).

**hana-ml**, hte Jupyter Notebook to load JSON data into the document store uses the python machine learning client for SAP HANA. There is a lot more in hana-ml for the data scientist - see [pypi.org](https://pypi.org/project/hana-ml/) and [hana-ml reference](https://help.sap.com/doc/1d0ebfe5e8dd44d09606814d83308d4b/latest/en-US/index.html). More detailed guidance on the Python environment setup is given in [Prepare your Python environment](/exercises/ex9_appendix/README.md#appA-sub1)



##  Background Material<a name="subex4"></a>

[SAP HANA Spatial Resources](https://blogs.sap.com/2020/11/02/sap-hana-spatial-resources-reloaded/)<br>
[SAP HANA Graph Resources](https://blogs.sap.com/2021/07/21/sap-hana-graph-resources/)<br>
[SAP HANA Machine Learning Resources](https://blogs.sap.com/2021/05/27/sap-hana-machine-learning-resources/)

## Summary

You are all set...

Continue to - [Exercise 1 - json](../ex1/README.md)
