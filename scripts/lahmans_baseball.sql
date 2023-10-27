-- 1. What range of years for baseball games played does the provided database cover?

SELECT
	yearid
FROM teams
GROUP BY yearid
ORDER BY yearid ASC;

-- ANSWER: 1871 THROUGH 2016

-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?

SELECT 
	namefirst
	,namelast
	,namegiven
	,g_all
	,t.name
FROM people AS p
INNER JOIN appearances AS ap
USING (playerid)
INNER JOIN teams AS t
USING (teamid)
WHERE 
	p.height = (
		SELECT MIN(height) 
				FROM people
	)
LIMIT 1;

-- ANSWER: EDDIE GAEDEL (EDWARD CARL), 43", 1 game, St. Louis Browns 

-- 3. Find all players in the database who played at Vanderbilt University. PEOPLE TABLE
--Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. 
--Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

SELECT 
	p.namefirst
	,p.namelast
	,(SUM(sa.salary)::numeric)::money AS total_salary
FROM people AS p
LEFT JOIN collegeplaying
USING (playerid)
LEFT JOIN schools AS s
USING (schoolid)
LEFT JOIN salaries AS sa
USING (playerid)
WHERE UPPER(schoolname) = 'VANDERBILT UNIVERSITY'
GROUP BY namefirst, namelast, s.schoolname
HAVING (SUM(sa.salary)::numeric)::money IS NOT NULL
ORDER BY total_salary DESC;

--ANSWER: "David"	"Price"	"$245,553,888.00"


-- 4. Using the fielding table, group players into three groups based on their position: label players with position 
--OF as "Outfield", those with position 
--"SS", "1B", "2B", and "3B" as "Infield", and those with position 
--"P" or "C" as "Battery". 
--Determine the number of putouts made by each of these three groups in 2016.

WITH X AS (
SELECT 
	CASE 
		WHEN pos = 'OF' THEN 'Outfield'
		WHEN pos = 'SS' THEN 'Infield'
		WHEN pos = '1B' THEN 'Infield'
		WHEN pos = '2B' THEN 'Infield'
		WHEN pos = '3B' THEN 'Infield'
		WHEN pos = 'P' THEN 'Battery'
		WHEN pos = 'C' THEN 'Battery'
		END 
			AS position_groups
	,po
FROM fielding
WHERE yearid = '2016'
)
SELECT
	position_groups
	,SUM(po) AS po_total
FROM X
GROUP BY position_groups

--ANSWER: "Battery"	41424, "Infield"	58934, "Outfield"	29560

-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?


SELECT 
	FLOOR(yearid / 10) * 10 AS decade,
	ROUND(AVG(so::numeric / g::numeric), 2) AS avg_strikeouts,
	ROUND(AVG(hr::numeric / g::numeric), 2) AS avg_hr
FROM teams
WHERE yearid >= 1920
GROUP BY decade
ORDER BY decade;

--ANSWER: strikeouts and homeruns increase throughout decades

-- 6. Find the player who had the most success stealing bases in 2016, where success is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted at least 20 stolen bases.

WITH stats AS (
SELECT 
	playerid
	,namefirst
	,namelast
	,namegiven
	,SUM(sb::numeric) AS stolen_bases
	,SUM(cs::numeric) AS caught_stealing
	,CASE
	WHEN SUM(sb::numeric) + SUM(cs::numeric) = 0 THEN 0
	ELSE SUM(sb::numeric) / (SUM(sb::numeric) + SUM(cs::numeric))
	END AS sb_percentage
FROM people 
INNER JOIN batting
USING (playerid)
WHERE yearid = 2016
GROUP BY playerid
HAVING (SUM(sb::numeric) + SUM(cs::numeric)) >= 20
ORDER BY sb_percentage DESC
	)
SELECT 
	namegiven
	,namefirst
	,namelast
	,stolen_bases
	,caught_stealing
	,sb_percentage 
	,RANK()OVER(ORDER BY sb_percentage DESC, stolen_bases DESC)
FROM stats

-- ANSWER: CHRIS OWINGS 

-- 7. From 1970 – 2016, 
--what is the largest number of wins for a team that did not win the world series? 
-- What is the smallest number of wins for a team that did win the world series? 
--Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. 
--How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

SELECT --LARGEST NUMBER OF WINS FOR TEAM THAT DID NOT WIN WS
	name AS team_name
	,SUM(w) AS wins
	,yearid
	,wswin
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
AND wswin = 'N'
GROUP BY team_name, yearid, wswin
ORDER BY wins DESC;

SELECT --SMALLEST NUMBER OF WINS FOR TEAM THAT DID WIN WS
	name AS team_name
	,SUM(w) AS wins
	,yearid
	,wswin
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
AND wswin = 'Y'
AND yearid <> 1981 --ADDED FILTER TO EXCLUDE 1981 
GROUP BY team_name, yearid, wswin
ORDER BY wins ASC;

--How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?
--NEED TO FIX
SELECT 
	NAME,
	MAX(W) as max_wins,
	WSWIN,
	YEARID
FROM TEAMS
WHERE yearid BETWEEN 1970 AND 2016
GROUP BY NAME, WSWIN, YEARID, w
ORDER BY YEARID;

/*ANSWER1: 
LARGEST, NO WORLD SERIES: 116 WINS -- 2001 -- SEATTLE MARINERS
SMALLEST, YES WORLD SERIES: 63 LOS ANGELES DODGERS - DUE TO STRIKE IN 1981
EXCLUDING 1981 THE ANSWER IS 83 IN 2016 ST LOUIS CARDINALS */

-- 8. 
--Using the attendance figures from the homegames table, 
--find the teams and parks which had the top 5 average attendance per game in 2016 
--(where average attendance is defined as total attendance divided by number of games). 
--Only consider parks where there were at least 10 games played. 
--Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.

WITH team_info AS (----------------------------TOP 5 QUERY
SELECT
	DISTINCT teamid AS team_id
	,name AS team_name
	,yearid
FROM teams
WHERE yearid = 2016
ORDER BY team_name
)
SELECT
	h.park
	,ti.team_name
	,h.attendance / h.games AS avg_attendance
FROM homegames AS h
INNER JOIN team_info AS ti
ON h.team = ti.team_id
WHERE h.year = 2016
AND games > 10
ORDER BY RANK()OVER(ORDER BY h.attendance / h.games DESC)
LIMIT 5; 

WITH team_info AS (----------------------------BOTTOM 5 QUERY
SELECT
	DISTINCT teamid AS team_id
	,name AS team_name
	,yearid
FROM teams
WHERE yearid = 2016
ORDER BY team_name
)
SELECT
	h.park
	,ti.team_name
	,h.attendance / h.games AS avg_attendance
FROM homegames AS h
INNER JOIN team_info AS ti
ON h.team = ti.team_id
WHERE h.year = 2016
AND games > 10
ORDER BY RANK()OVER(ORDER BY h.attendance / h.games ASC)
LIMIT 5; 

/* ANSWER
TOP 5 AVG ATTENDANCE
"LOS03"	"Los Angeles Dodgers"	45719
"STL10"	"St. Louis Cardinals"	42524
"TOR02"	"Toronto Blue Jays"	41877
"SFO03"	"San Francisco Giants"	41546
"CHI11"	"Chicago Cubs"	39906

BOTTOM 5 AVG ATTENDANCE
"STP01"	"Tampa Bay Rays"	15878
"OAK01"	"Oakland Athletics"	18784
"CLE08"	"Cleveland Indians"	19650
"MIA02"	"Miami Marlins"	21405
"CHI12"	"Chicago White Sox"	21559
*/

9.-- Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

SELECT 
	p.namefirst AS first_name
	,p.namelast AS last_name
	,subquery.NAME AS team_name
	,a.yearid AS year_awarded
FROM people AS p
LEFT JOIN awardsmanagers AS a
USING (playerid)
INNER JOIN 
(
SELECT 
	m.playerid
	,m.yearid
	,t.teamid
	,t.name
FROM managers AS m
LEFT JOIN teams AS t
USING (teamid, yearid)
-- WHERE m.playerid = 'lanieha01' AND M.yearid = '1986'
) AS subquery
USING (playerid, yearid)
WHERE a.awardid IS NOT NULL AND a.lgid IN ('NL', 'AL') AND a.awardid = 'TSN Manager of the Year';


/* ANSWER
"John"	"McNamara"	"Boston Red Sox"	1986
"Hal"	"Lanier"	"Houston Astros"	1986
"Sparky"	"Anderson"	"Detroit Tigers"	1987
"Buck"	"Rodgers"	"Montreal Expos"	1987
"Tony"	"LaRussa"	"Oakland Athletics"	1988
"Jim"	"Leyland"	"Pittsburgh Pirates"	1988
"Frank"	"Robinson"	"Baltimore Orioles"	1989
"Don"	"Zimmer"	"Chicago Cubs"	1989
"Jeff"	"Torborg"	"Chicago White Sox"	1990
"Jim"	"Leyland"	"Pittsburgh Pirates"	1990
"Tom"	"Kelly"	"Minnesota Twins"	1991
"Bobby"	"Cox"	"Atlanta Braves"	1991
"Tony"	"LaRussa"	"Oakland Athletics"	1992
"Jim"	"Leyland"	"Pittsburgh Pirates"	1992
"Johnny"	"Oates"	"Baltimore Orioles"	1993
"Bobby"	"Cox"	"Atlanta Braves"	1993
"Buck"	"Showalter"	"New York Yankees"	1994
"Felipe"	"Alou"	"Montreal Expos"	1994
"Mike"	"Hargrove"	"Cleveland Indians"	1995
"Don"	"Baylor"	"Colorado Rockies"	1995
"Johnny"	"Oates"	"Texas Rangers"	1996
"Bruce"	"Bochy"	"San Diego Padres"	1996
"Davey"	"Johnson"	"Baltimore Orioles"	1997
"Dusty"	"Baker"	"San Francisco Giants"	1997
"Joe"	"Torre"	"New York Yankees"	1998
"Bruce"	"Bochy"	"San Diego Padres"	1998
"Jimy"	"Williams"	"Boston Red Sox"	1999
"Bobby"	"Cox"	"Atlanta Braves"	1999
"Jerry"	"Manuel"	"Chicago White Sox"	2000
"Dusty"	"Baker"	"San Francisco Giants"	2000
"Lou"	"Piniella"	"Seattle Mariners"	2001
"Larry"	"Bowa"	"Philadelphia Phillies"	2001
"Mike"	"Scioscia"	"Anaheim Angels"	2002
"Bobby"	"Cox"	"Atlanta Braves"	2002
"Tony"	"Pena"	"Kansas City Royals"	2003
"Bobby"	"Cox"	"Atlanta Braves"	2003
"Ron"	"Gardenhire"	"Minnesota Twins"	2004
"Bobby"	"Cox"	"Atlanta Braves"	2004
"Ozzie"	"Guillen"	"Chicago White Sox"	2005
"Bobby"	"Cox"	"Atlanta Braves"	2005
"Jim"	"Leyland"	"Detroit Tigers"	2006
"Joe"	"Girardi"	"Florida Marlins"	2006
"Eric"	"Wedge"	"Cleveland Indians"	2007
"Bob"	"Melvin"	"Arizona Diamondbacks"	2007
"Joe"	"Maddon"	"Tampa Bay Rays"	2008
"Fredi"	"Gonzalez"	"Florida Marlins"	2008
"Mike"	"Scioscia"	"Los Angeles Angels of Anaheim"	2009
"Jim"	"Tracy"	"Colorado Rockies"	2009
"Ron"	"Gardenhire"	"Minnesota Twins"	2010
"Buddy"	"Black"	"San Diego Padres"	2010
"Joe"	"Maddon"	"Tampa Bay Rays"	2011
"Kirk"	"Gibson"	"Arizona Diamondbacks"	2011
"Buck"	"Showalter"	"Baltimore Orioles"	2012
"Davey"	"Johnson"	"Washington Nationals"	2012
"John"	"Farrell"	"Boston Red Sox"	2013
"Clint"	"Hurdle"	"Pittsburgh Pirates"	2013
"Buck"	"Showalter"	"Baltimore Orioles"	2014
"Matt"	"Williams"	"Washington Nationals"	2014
"Paul"	"Molitor"	"Minnesota Twins"	2015
"Terry"	"Collins"	"New York Mets"	2015
*/

10.-- Find all players who hit their career highest number of home runs in 2016. 
--Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. 
--Report the players' first and last names and the number of home runs they hit in 2016.

SELECT --MAX HOMERUNS
	p.namefirst
	,p.namelast
	,b.hr AS highest_hr
	,CAST(p.debut AS DATE) AS debut
	,CAST(p.finalgame AS DATE) AS final_game
	,DATEDIFF(yyyy, p.debut, p.finalgame)
FROM BATTING AS b
INNER JOIN people AS p
USING (playerid)
WHERE yearid = 2016
ORDER BY highest_hr DESC;

SELECT * FROM PEOPLE

-- Open-ended questions

-- Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

-- In this question, you will explore the connection between number of wins and attendance.

-- Does there appear to be any correlation between attendance at home games and number of wins?
-- Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.
-- It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?