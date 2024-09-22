select count(1) from olympics_history
-- SELECT * from olympics_history_noc_regions

-- 1.How many olympics games have been held?
-- 1. Скільки оліміпйський ігор було проведено?

SELECT count(DISTINCT games) from olympics_history

-- 2. List down all Olympics games held so far.
-- 2. Перелічіть усі Олімпійські ігри, що відбулися до цього часу.

SELECT DISTINCT year, season, city from olympics_history
ORDER BY year ASC

-- 3. Mention the total no of nations who participated in each olympics game?
-- 3. Загальне число націй, які брали участь в олімпійьких іграх

SELECT COUNT (DISTINCT noc), games FROM olympics_history
GROUP BY games
ORDER BY games


-- 3.1. 

WITH all_countries AS
	(
	SELECT games, nr.region
	FROM olympics_history oh
	JOIN olympics_history_noc_regions nr 
	ON nr.noc = oh.noc
	GROUP BY games, nr.region
	)
SELECT games, COUNT(1) AS total_countries
FROM all_countries
GROUP BY games
ORDER BY games


-- 4. Which year saw the highest and lowest no of countries participating in olympics

WITH all_countries AS
	(
	SELECT games, nr.region
	 FROM olympics_history oh
	 JOIN olympics_history_noc_regions nr
	 ON oh.noc = nr.noc
	 GROUP BY games, nr.region
	),
	total_count AS 
	(
	SELECT games, COUNT(1) AS total_countries
	FROM all_countries
	GROUP BY games 
	ORDER BY games
	)
SELECT
	MIN(total_countries)
	, MAX(total_countries)
FROM total_count


-- SELECT DISTINCT
-- CONCAT(FIRST_VALUE)

-- 4.1 Which year saw the highest and lowest no of countries participating in olympics

WITH all_countries AS
	(
	SELECT games, nr.region
	 FROM olympics_history oh
	 JOIN olympics_history_noc_regions nr
	 ON oh.noc = nr.noc
	 GROUP BY games, nr.region
	),
	total_count AS 
	(
	SELECT games, COUNT(1) as total_countries
	FROM all_countries
	GROUP BY games
	)
	SELECT DISTINCT
	concat(first_value(games) over (order by total_countries),
		  ' - '
		  , first_value(total_countries) over(order by total_countries)) as Lowest_countries,
	concat(first_value(games) over(order by total_countries DESC)
		  , ' - '
		  , first_value(total_countries) over(order by total_countries DESC)) as Highest_countries
	FROM total_count
	ORDER BY 1; 
	
	
-- 5. Which nation has participated in all of the olympic games
-- 1) Find how much each country was at the olympic games
-- 2) FIND the count of all of the olympic games +
-- 3) And LIMIT only that countries, count = all of the OG

WITH all_countries AS
	(
	SELECT games, nr.region
	FROM olympics_history oh
	JOIN olympics_history_noc_regions nr
	ON oh.noc = nr.noc
	GROUP BY games, nr.region
	)
SELECT region, COUNT (region)
FROM all_countries
GROUP BY region
HAVING COUNT(region) = 
	(SELECT COUNT (DISTINCT games)
	FROM olympics_history);
	

-- 6. Identify the sport which was played in all summer olympics.
-- 1) Need to choose all summer olympics
-- 2) Count this number
-- 3) To compare these two count (count sport vs count of summer games)


SELECT DISTINCT sport, COUNT(DISTINCT year)
FROM olympics_history
WHERE season = 'Summer' 
GROUP BY sport
HAVING COUNT(DISTINCT year) =
	(SELECT COUNT(DISTINCT year)
	FROM olympics_history
	WHERE season = 'Summer')
ORDER BY sport;

-- 7. Which Sports were just played only once in the olympics.

SELECT sport, COUNT(DISTINCT games)
FROM olympics_history
GROUP BY sport
HAVING COUNT(DISTINCT games) = 1
ORDER BY sport

-- 7.1 Which Sports were just played only once in the olympics.
WITH t1 AS
	(SELECT DISTINCT games, sport
	FROM olympics_history), 
	t2 AS
	(SELECT sport, COUNT(sport) AS no_of_count
	 FROM t1
	GROUP BY sport)
SELECT t2.*, t1.games
FROM t2
JOIN t1 ON t1.sport = t2.sport
WHERE t2.no_of_count = 1
ORDER BY t1.sport

-- 8. Fetch the total no of sports played in each olympic games.

SELECT games, COUNT(DISTINCT sport)
FROM olympics_history
GROUP BY games
-- HAVING COUNT(DISTINCT games) = 1
ORDER BY 2 DESC

-- 9. Fetch oldest athletes to win a gold medal

SELECT *
FROM olympics_history
WHERE age != 'NA' AND Medal = 'Gold'
ORDER BY age DESC
LIMIT 18


-- 10. Find the Ratio of male and female athletes participated in all olympic games.

/* 
SELECT f1.a1/f2.b1 as Female_Male
FROM 
(
	SELECT sex, COUNT(1) as a1
	FROM olympics_history
	WHERE sex = 'F' 
) as f1,
FROM (
	SELECT sex, COUNT(1) as b1
	FROM olympics_history
	WHERE sex = 'M' 
) AS f2
*/


WITH query_1 AS
	(
		SELECT sex, COUNT(1) as a1
		FROM olympics_history
		WHERE sex = 'F'
		GROUP BY sex
	),
		query_2 AS
	(
		SELECT sex, COUNT(1) as b1
		FROM olympics_history
		WHERE sex = 'M' 
		GROUP BY sex
	)
SELECT CONCAT ('1:', ROUND(query_2.b1/query_1.a1::numeric, 1)) as ratio
FROM query_1, query_2


-- 11. Fetch the top 5 athletes who have won the most gold medals.

SELECT name, team, sport, COUNT(medal)
FROM olympics_history
WHERE Medal = 'Gold'
GROUP BY name, team, sport
ORDER BY COUNT(medal) DESC
LIMIT 5

-- 12. Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).

SELECT name, team, sport, COUNT(medal)
FROM olympics_history
WHERE Medal != 'NA'
GROUP BY name, team, sport
ORDER BY COUNT(medal) DESC
LIMIT 5

--13. Fetch the top 5 most successful countries in olympics. Success is defined by no of medals w
SELECT nr.region, COUNT(medal)
FROM olympics_history oh
JOIN olympics_history_noc_regions nr 
ON oh.noc=nr.noc
WHERE oh.medal != 'NA'
GROUP BY nr.region
ORDER BY COUNT(medal) DESC
LIMIT 5


WITH t1 as
	(SELECT region as country, count(medal) as medals
	FROM olympics_history o
	JOIN olympics_history_noc_regions nc on o.noc = nc.noc
	WHERE medal <> 'NA'
	GROUP BY region
	ORDER BY medals DESC),
	t2 as
	(SELECT *, dense_rank() OVER(ORDER BY medals DESC) as rnk
	FROM t1)
SELECT *
FROM t2
WHERE rnk <= 5;

-- 14. List down total gold, silver and bronze medals won by each country.
SELECT nr.region, COUNT(medal)
FROM olympics_history oh
JOIN olympics_history_noc_regions nr 
ON oh.noc=nr.noc
WHERE oh.medal != 'NA'
GROUP BY nr.region
ORDER BY COUNT(medal) DESC
LIMIT 5

with t1 as
(select
region as country,
sum(case when medal = 'Gold' then 1 else 0 end) as Gold,
sum(case when medal = 'Silver' then 1 else 0 end) as Silver,
sum(case when medal = 'Bronze' then 1 else 0 end) as Bronze
from olympics_history o
join olympics_history_noc_regions nc on o.noc = nc.noc
group by region
order by Gold desc, Silver desc, Bronze desc);

-- 15. List down total gold, silver and bronze medals won by each country 
-- corresponding to each olympic games.
SELECT games, nr.region
	, SUM(CASE WHEN medal = 'Gold' then 1 else 0 end) as Gold
	, SUM(CASE WHEN medal = 'Silver' then 1 else 0 end) as Silver
	, SUM(CASE WHEN medal = 'Bronze' then 1 else 0 end) as Bronze
FROM olympics_history oh
JOIN olympics_history_noc_regions nr 
ON oh.noc=nr.noc
WHERE oh.medal != 'NA'
GROUP BY games, nr.region
ORDER BY games DESC, COUNT(medal) DESC


-- 16. Identify which country won the most gold, most silver and most bronze medals 
-- in each olympic games.


-- 1) ВИДІЛЯЄМО всі стовчики, які нам потрібні. + об'єднуємо інформацію з двох таблиць для актуалізації країн
-- 2) СУМУЄ загальну к-сть медалей окремо золото, срібло і бронза
-- 3) Індексуємо кожне значення по сумі
-- 4) вибираємо ігру, країну та к-сть. 
-- 5) ПОЄДНУЄМО 

WITH query_1 AS
(
	SELECT games, region as country, medal
	FROM olympics_history oh
	JOIN olympics_history_noc_regions nr 
	ON oh.noc=nr.noc
	WHERE medal <> 'NA'
),
	medal_table as(
	select games, country,
	SUM(CASE WHEN medal = 'Gold' THEN 1 ELSE 0 END) as gold_cnt, 
	SUM(CASE WHEN medal = 'Silver' THEN 1 ELSE 0 END) as silver_cnt,
	SUM(CASE WHEN medal = 'Bronze' THEN 1 ELSE 0 END) as bronze_cnt
	FROM query_1
	GROUP BY games, country
	), 
	ranked_medals AS (
	SELECT games, country, gold_cnt, silver_cnt, bronze_cnt, 
	ROW_NUMBER() OVER(PARTITION BY games ORDER BY gold_cnt DESC) AS gold_count, 
	ROW_NUMBER() OVER(PARTITION BY games ORDER BY silver_cnt DESC) AS silver_count, 
	ROW_NUMBER() OVER(PARTITION BY games ORDER BY bronze_cnt DESC) AS bronze_count
	FROM medal_table
	)
	
SELECT 
	g.games
	, g.country as gold_country
	, g.gold_cnt as gold_medals
	, s.country as silver_country
	, s.silver_cnt as silver_medals
	, b.country as bronze_country
	, b.bronze_cnt as bronze_medals
FROM ranked_medals g
LEFT JOIN ranked_medals s ON g.games = s.games and s.silver_count = 1
LEFT JOIN ranked_medals b ON b.games = g.games and b.bronze_count = 1
WHERE g.gold_count = 1
ORDER BY g.games;

-- ANOTHER OPTION

with query_1 as
(SELECT 
 	games
 	, region,
	COUNT(CASE WHEN medal = 'Gold' THEN medal END) AS Gold,
	COUNT(CASE WHEN medal = 'Silver' THEN medal END) AS Silver,
	COUNT(CASE WHEN medal = 'Bronze' THEN medal END) AS Bronze
FROM olympics_history oh
JOIN olympics_history_noc_regions nr 
ON oh.noc=nr.noc
GROUP BY games,region)
SELECT DISTINCT 
	games
	, concat(first_value(region) over(partition by games order by gold DESC)
	, ' - '
	, first_value(Gold) over(partition by games order by gold DESC)) AS Max_Gold
	, concat(first_value(region) over(partition by games order by silver DESC)
	, ' - '
	, first_value(Silver) over(partition by games order by silver DESC)) AS Max_Silver
	, concat(first_value(region) over(partition by games order by bronze DESC)
	, ' - '
	, first_value(Bronze) over(partition by games order by bronze desc)) AS Max_Bronze
FROM query_1
ORDER BY games;


-- 17. Identify which country won the most gold, most silver, most bronze medals 
-- and the most medals in each olympic games.

-- THE same as the option above


-- 18. Which countries have never won gold medal but have won silver/bronze medals?

WITH query_1 AS
(
	SELECT 
	region as country
	, SUM(CASE WHEN medal = 'Gold' THEN 1 ELSE 0 END) AS Gold_medal
	, SUM(CASE WHEN medal = 'Silver' THEN 1 ELSE 0 END) AS Silver_medal
	, SUM(CASE WHEN medal = 'Bronze' THEN 1 ELSE 0 END) AS Bronze_medal
	FROM olympics_history oh
	JOIN olympics_history_noc_regions nr 
	ON oh.noc = nr.noc
	GROUP BY country
)

SELECT 
	country
	, Gold_medal
	, Silver_medal
	, Bronze_medal
FROM query_1
WHERE Gold_medal=0 AND (Silver_medal + Bronze_medal) >0
GROUP BY country, Gold_medal, Silver_medal, Bronze_medal
ORDER BY 

-- 19. In which Sport/event, Ukraine has won highest medals.

SELECT 
	team
	, sport
	, COUNT(medal) as Highest_count
FROM olympics_history
WHERE team = 'Ukraine'
GROUP BY team, sport
ORDER BY Highest_count DESC


-- 20. 20. Break down all olympic games where Ukraine won medal for Hockey and how many 
-- medals in each olympic games

SELECT 
	games
	, team
	, sport
	, COUNT(medal) as Volley_count
FROM olympics_history
WHERE team = 'Ukraine' and sport = 'Volleyball'
GROUP BY games, team, sport
ORDER BY Volley_count DESC






