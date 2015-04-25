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

LOAD DATA INPATH '/user/popularhashtags/full_text.txt'
OVERWRITE INTO TABLE tweet_data;              
 
-- Split all tweets into individual words to allow for the extraction of hashtags   

DROP TABLE split_tweets;

CREATE TABLE split_tweets AS
SELECT id, ts, sptweets
FROM tweet_data
LATERAL VIEW EXPLODE(SPLIT(LOWER(tweet), '[ .,:~-­‐]')) WordTable as sptweets;

-- Extract only hashtags from the previous table and create an ordered list of aggregate counts 

SELECT REGEXP_EXTRACT(sptweets, '(#)[a-­‐z0-­‐9_](\\w+)', 0), COUNT(*) as htct
FROM split_tweets
WHERE REGEXP_EXTRACT(sptweets, '(#)[a-­‐z0-­‐9_](\\w+)', 0) != '' 
GROUP BY REGEXP_EXTRACT(sptweets, '(#)[a-­‐z0-­‐9_](\\w+)', 0) 
ORDER BY htct descLIMIT 5;
