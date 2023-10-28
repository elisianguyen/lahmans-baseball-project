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
	namefirst
	,namelast
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

SELECT --SMALLEST NUMBER OF WINS FOR TEAM THAT DID WIN WS (WINDOW FUNCTION)
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

WITH maxwinsbyyear AS (
SELECT
	yearid
	,MAX(w) AS max_wins
    FROM teams
    WHERE yearid BETWEEN 1970 AND 2016
	AND yearid <> 1981 
    GROUP BY yearid
	ORDER BY yearid
)
SELECT
	COUNT(*) AS count_seasons
	,ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM maxwinsbyyear)),2) AS percentage
FROM maxwinsbyyear AS mw
JOIN TEAMS T
ON MW.YEARID = T.YEARID
WHERE mw.max_wins = t.w
    AND t.wswin = 'Y';

/*ANSWER1: 
LARGEST, NO WORLD SERIES: 116 WINS -- 2001 -- SEATTLE MARINERS
SMALLEST, YES WORLD SERIES: 63 LOS ANGELES DODGERS - DUE TO STRIKE IN 1981
EXCLUDING 1981 THE ANSWER IS 83 IN 2016 ST LOUIS CARDINALS */
--ANSWER 2: 26.09%

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
	playerid
	,awardid
	,lgid AS al
FROM awardsmanagers
WHERE awardid = 'TSN Manager of the Year'


10.-- Find all players who hit their career highest number of home runs in 2016. 
--Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. 
--Report the players' first and last names and the number of home runs they hit in 2016.

SELECT 
	p.namefirst AS first_name
	,p.namelast AS last_name
	,MAX(s.hr) AS max_hr
FROM 
(
SELECT 
	playerid
	,yearid
	,hr
FROM batting
WHERE yearid = '2016'
) AS s
INNER JOIN people AS p
USING (playerid)
WHERE EXTRACT(YEARS FROM AGE(p.finalgame::DATE, p.debut::DATE)) >= 10
GROUP BY playerid, P.finalgame, p.debut, p.namefirst, p.namelast
HAVING MAX(s.hr) > 0
ORDER BY max_hr DESC;

-- Open-ended questions

-- Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.


-- In this question, you will explore the connection between number of wins and attendance.

-- Does there appear to be any correlation between attendance at home games and number of wins?
-- Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.
-- It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?