-- Create tables to store initial data

DROP TABLE tweet_data;
DROP TABLE cities;

CREATE TABLE tweet_data (   
 id STRING,                
 ts STRING,             
 location STRING,          
 lat STRING,               
 lon STRING,               
 tweet STRING)             
 ROW FORMAT DELIMITED      
 FIELDS TERMINATED BY '\t';

CREATE TABLE cities (
id STRING,
city STRING,
countrycode STRING,
lat STRING,
lon STRING,
timezoneid STRING)
ROW FORMAT DELIMITED  
FIELDS TERMINATED BY '\t';

LOAD DATA INPATH '/user/top10cities/full_text.txt'
OVERWRITE INTO TABLE tweet_data;              

LOAD DATA INPATH '/user/top10cities/cities15000.txt'
OVERWRITE INTO TABLE cities;   

-- Extract integer part from latitude and longitude coordinates to allow for equality testing and convert them to float for distance calculations    

DROP TABLE tweet_data_extract;
DROP TABLE cities_extract;                 

CREATE TABLE tweet_data_extract AS
SELECT id, ts, location, lat, lon, CAST(REGEXP_EXTRACT(lat, '(-?\\d{2,3})(\\.)(.*)',1) as FLOAT) as lat_t, CAST(REGEXP_EXTRACT(lon, '(-?\\d{2,3})(\\.)(.*)',1) as FLOAT) as lon_t, tweet
FROM tweet_data;

CREATE TABLE cities_extract AS
SELECT id, city, countrycode, lat, lon, CAST(REGEXP_EXTRACT(lat, '(-?\\d{2,3})(\\.)(.*)',1) as FLOAT) as lat_t, CAST(REGEXP_EXTRACT(lon, '(-?\\d{2,3})(\\.)(.*)',1) as FLOAT) as lon_t, timezoneid
FROM cities;

-- Join the two tables on the truncated latitude and longitude coordinates

DROP TABLE joined_data;

CREATE TABLE joined_data AS
SELECT a.lat_t, a.lon_t, a.id, a.ts, a.lat, a.lon, a.tweet, b.lat as lat2, b.lon as lon2, b.city
FROM tweet_data_extract a JOIN cities_extract b
ON a.lat_t = b.lat_t AND a.lon_t = b.lon_t;

-- Calculate the distance from the location of a tweet to each nearby city using the Euclidean distance formula

DROP TABLE distances;

CREATE TABLE distances AS                                                                            
SELECT id, ts, tweet, city, SQRT((lat-lat2)*(lat-lat2) + (lon - lon2)*(lon -lon2)) as dist            
FROM joined_data;  

-- Identify the minimum distance for each tweet

DROP TABLE min_dist;

CREATE TABLE min_dist AS
SELECT id, ts, tweet, min(dist) as min_distance
FROM distances
GROUP BY id, ts, tweet;

-- Identify the city associated with each minimum distance

DROP TABLE closest_city;

CREATE TABLE closest_city AS                                           
SELECT a.id, a.ts, a.tweet, b.city                                      
FROM min_dist a JOIN distances b                                        
ON a.id = b.id AND a.ts = b.ts AND a.tweet = b.tweet AND a.min_distance = b.dist;

-- Find aggregate counts for each city and order them to find the top 10 cities

SELECT city, count(*) as cnt
FROM closest_city
GROUP BY city
ORDER BY cnt desc
LIMIT 10;

