
-- Create table to store initial data

DROP TABLE tweet_data;

CREATE TABLE tweet_data (
id STRING,
ts STRING,
location STRING,
lat STRING,
lon STRING,
tweet STRING)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t';

LOAD DATA INPATH '/user/mobiletweeter/full_text.txt'
OVERWRITE INTO TABLE tweet_data;

-- Count the distinct number of latitude, longitude pairs for each user and then put them in descending order, retrieving only the first result

SELECT id, count(DISTINCT lat, lon) AS locations
FROM tweet_data
GROUP BY id
ORDER BY locations DESC
LIMIT 1;

