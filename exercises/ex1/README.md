# Exercise 1 - Manage JSON Data

This exercise is optional. It requires a Python environment and SAP HANA Cloud system with the **JSON Document Server** enabled. If you have a SAP HANA Cloud trial or free tier, skip this exercise.

In this exercise, we will use the SAP HANA Cloud JSON Document Store and the [Python machine learning client for SAP HANA](https://pypi.org/project/hana-ml/) (hana-ml) to retrieve street network data from [OpenStreetMap](https://www.openstreetmap.org) and store JSON data in the database.


## Exercise 1.1 Importing OpenStreetMap Street Network Data

First of all, create a new schema "DAT285" in your database, e.g. using the SAP HANA Database Explorer.
```SQL
CREATE SCHEMA "DAT285";
```
![](./images/DBX.png)

Now open the Jupyter Notebook [2023 Q3 TechEd DAT285 OSM load.ipynb](2023%20Q3%20TechEd%20DAT285%20OSM%20load.ipynb) and make sure you have installed pandas, hana-ml, and requests.

```python
# Import required libraries
import hana_ml
import pandas as pd
import requests
from hana_ml.dataframe import ConnectionContext
```
Next, connect to you SAP HANA Cloud database.
```python
# Connect to SAP HANA Cloud
# The JSON Document Store has to be enabled.
# This does NOT work with SAP HANA Cloud free tier or trial!

# Connect using secure store
# cc = ConnectionContext(userkey='[userkey]', encrypt=True)

host = '[YourHostName]' # e.g. somecharacters.hanacloud.ondemand.com
port = 443
user = '[YourUser]' # e.g. DBADMIN
password = '[YourUserPassword]'
cc= ConnectionContext(
    address=host, 
    port=port, 
    user=user, 
    password=password, 
    encrypt='true'
    )
schema="DAT285"
print('HANA version:', cc.hana_version())
print('hana-ml version:', hana_ml.__version__)
print('pandas version:', pd.__version__)
```
We'll use the [overpass turbo API](https://overpass-turbo.eu/) to retriev data from OSM.
```python
# All car ways
# way["highway"]["area"!~"yes"]["highway"!~"abandoned|bridleway|bus_guideway|construction|corridor|cycleway|elevator|escalator|footway|path|pedestrian|planned|platform|proposed|raceway|service|steps|track"]["motor_vehicle"!~"no"]["motorcar"!~"no"]["service"!~"alley|driveway|emergency_access|parking|parking_aisle|private"]

# Orlando area (28.365266048079008,-81.54412854399905, 28.62735114041908, -81.25956141698434)
overpass_query = """
    [out:json];
    (
    way(28.365266048079008,-81.54412854399905, 28.62735114041908, -81.25956141698434)["highway"]["area"!~"yes"]["highway"!~"abandoned|bridleway|bus_guideway|construction|corridor|cycleway|elevator|escalator|footway|path|pedestrian|planned|platform|proposed|raceway|service|steps|track"]["motor_vehicle"!~"no"]["motorcar"!~"no"]["service"!~"alley|driveway|emergency_access|parking|parking_aisle|private"];
    );
    out body;
    >;
    out skel qt;
"""
overpass_url = "http://overpass-api.de/api/interpreter"
response = requests.get(overpass_url, params={'data': overpass_query})
data = response.json()
```
We use `create_collection_from_elemets` to store the data in SAP HANA Cloud JSON Document Store.
```python
# The overpass API resturns JSON which we can store in the SAP HANA Document Store.
from hana_ml.docstore import create_collection_from_elements
coll = create_collection_from_elements(
    connection_context = cc,
    schema = schema,
    collection_name = 'C_STREET_NETWORK',
    elements = data["elements"], 
    drop_exist_coll = True
    )
```

## Exercise 1.2 Inspect, Query, and Transform JSON Data

Let's switch back to the Database Explorer and inspect the street network collection.

![](images/json.png)

## Summary

You've now loaded OSM Street Network data into the SAP HANA Cloud JSON Document Store

Continue to - [Exercise 2 - Spatial](../ex2/README.md)

