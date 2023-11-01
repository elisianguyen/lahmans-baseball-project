-- 1. What range of years for baseball games played does the provided database cover?

SELECT
	yearid
FROM teams
GROUP BY yearid
ORDER BY yearid ASC;

-- ANSWER: The range of years the database covers are 1871 through 2016

-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?

SELECT 
    p.namefirst ||' '||p.namelast AS player_name,
	p.height,
	ap.g_all AS game_count,
	t.name AS team_name
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

-- ANSWER: EDDIE GAEDEL, 43", 1 game, St. Louis Browns 

-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

SELECT 
    p.namefirst ||' '|| p.namelast,
	(SUM(sa.salary)::numeric)::money AS total_salary
FROM people AS p
LEFT JOIN collegeplaying AS cp
USING (playerid)
LEFT JOIN schools AS s
USING (schoolid)
LEFT JOIN salaries AS sa
USING (playerid)
WHERE UPPER(schoolname) = 'VANDERBILT UNIVERSITY'
GROUP BY p.namefirst, p.namelast, s.schoolname
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
		END AS position_groups,
		po AS position_count
	FROM fielding
	WHERE yearid = '2016'
)
SELECT
	position_groups,
	SUM(position_count) AS pos_total
FROM X
GROUP BY position_groups;




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
		playerid,
		namefirst,
		namelast,
		namegiven,
		SUM(sb::numeric) AS stolen_bases,
		SUM(cs::numeric) AS caught_stealing,
		CASE
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
	namefirst,
	namelast,
	sb_percentage,
	RANK() OVER (ORDER BY sb_percentage DESC, stolen_bases DESC)
FROM stats;


-- ANSWER: CHRIS OWINGS 91.3%

-- 7. From 1970 – 2016, 
--what is the largest number of wins for a team that did not win the world series? 
-- What is the smallest number of wins for a team that did win the world series? 
--Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. 
--How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

SELECT -- LARGEST NUMBER OF WINS FOR TEAM THAT DID NOT WIN WS
	name AS team_name,
	SUM(w) AS wins,
	yearid,
	wswin
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
	AND wswin = 'N'
GROUP BY team_name, yearid, wswin
ORDER BY wins DESC;

SELECT -- SMALLEST NUMBER OF WINS FOR TEAM THAT DID WIN WS (WINDOW FUNCTION)
	name AS team_name,
	SUM(w) AS wins,
	yearid,
	wswin
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
	AND wswin = 'Y'
	AND yearid <> 1981 -- ADDED FILTER TO EXCLUDE 1981
GROUP BY team_name, yearid, wswin
ORDER BY wins ASC;

--How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

WITH maxwinsbyyear AS (
	SELECT
		yearid,
		MAX(w) AS max_wins
	FROM teams
	WHERE yearid BETWEEN 1970 AND 2016
		AND yearid <> 1981
	GROUP BY yearid
	ORDER BY yearid
)

SELECT
	COUNT(*) AS count_seasons,
	ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM maxwinsbyyear)), 2) AS percentage
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

WITH team_info AS ( --TOP 5 QUERY
	SELECT
		DISTINCT teamid AS team_id,
		name AS team_name,
		yearid
	FROM teams
	WHERE yearid = 2016
	ORDER BY team_name
)

SELECT
	h.park,
	ti.team_name,
	h.attendance / h.games AS avg_attendance
FROM homegames AS h
INNER JOIN team_info AS ti
	ON h.team = ti.team_id
WHERE h.year = 2016
	AND games > 10
ORDER BY RANK() OVER (ORDER BY h.attendance / h.games DESC)
LIMIT 5;


WITH team_info AS ( -- BOTTOM 5 QUERY
	SELECT
		DISTINCT teamid AS team_id,
		name AS team_name,
		yearid
	FROM teams
	WHERE yearid = 2016
	ORDER BY team_name
)

SELECT
	h.park,
	ti.team_name,
	h.attendance / h.games AS avg_attendance
FROM homegames AS h
INNER JOIN team_info AS ti
	ON h.team = ti.team_id
WHERE h.year = 2016
	AND games > 10
ORDER BY RANK() OVER (ORDER BY h.attendance / h.games ASC)
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

/* ANSWER: 
DAVEY JOHNSON WON ONCE IN AL AND ONCE IN NL
JIM LEYLAND WON 3 TIMES IN NL AND ONCE IN AL
RESULTS AS FOLLOWS:

"Davey Johnson"	1997	"AL"	"Baltimore Orioles"
"Davey Johnson"	2012	"NL"	"Washington Nationals"
"Jim Leyland"	1988	"NL"	"Pittsburgh Pirates"
"Jim Leyland"	1990	"NL"	"Pittsburgh Pirates"
"Jim Leyland"	1992	"NL"	"Pittsburgh Pirates"
"Jim Leyland"	2006	"AL"	"Detroit Tigers"
*/

WITH cte AS (
	SELECT 
		aw.playerid,
		aw.awardid,
		aw.yearid,
		aw.lgid
	FROM awardsmanagers AS aw
	INNER JOIN (
		SELECT
			am.playerid
		FROM awardsmanagers AS am
		WHERE am.awardid = 'TSN Manager of the Year' AND am.lgid != 'ML'
		GROUP BY am.playerid
		HAVING SUM(CASE WHEN am.lgid = 'AL' THEN 1 ELSE 0 END) >= 1 
		AND SUM(CASE WHEN am.lgid = 'NL' THEN 1 ELSE 0 END) >= 1
		ORDER BY am.playerid
	) USING (playerid)
	WHERE awardid = 'TSN Manager of the Year' AND lgid != 'ML'
)
SELECT 
	p.namefirst || ' ' || p.namelast AS manager_name,
	cte.yearid,
	cte.lgid,
	teams.name
FROM cte
INNER JOIN people AS p USING (playerid)
INNER JOIN (
	SELECT 
		m.playerid,
		m.yearid,
		t.teamid,
		t.name
	FROM managers AS m
	LEFT JOIN teams AS t USING (teamid, yearid)
) AS teams USING (playerid, yearid)
ORDER BY manager_name;

10.-- Find all players who hit their career highest number of home runs in 2016. 
--Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. 
--Report the players' first and last names and the number of home runs they hit in 2016.

WITH max_list AS (
	SELECT 
		b.playerid,
		b.yearid,
		MAX(b.hr) AS max_hr
	FROM batting AS b
	WHERE yearid = '2016'
	GROUP BY b.playerid, b.yearid
	HAVING MAX(b.hr) > 0
)
SELECT 
	p.namefirst ||' '|| p.namelast AS player_name,
	ml.playerid,
	ml.max_hr
FROM max_list AS ml
INNER JOIN people AS p
ON ml.playerid = p.playerid
WHERE EXTRACT(YEARS FROM AGE(p.finalgame::DATE, p.debut::DATE)) >= 10
AND ml.max_hr = (SELECT MAX(hr) FROM batting WHERE playerid = ml.playerid);


WITH max_list AS (
	SELECT 
		b.playerid,
		b.yearid,
		MAX(b.hr) AS max_hr
	FROM batting AS b
	WHERE yearid = '2016'
	GROUP BY b.playerid, b.yearid
	HAVING MAX(b.hr) > 0
)
SELECT 
	p.namefirst || ' ' || p.namelast AS player_name,
	ml.playerid,
	ml.max_hr
FROM max_list AS ml
INNER JOIN people AS p
ON ml.playerid = p.playerid
WHERE ml.max_hr = (SELECT MAX(hr) FROM batting WHERE playerid = ml.playerid)
AND (SELECT COUNT(DISTINCT yearid) FROM batting WHERE playerid = ml.playerid) > 9;

-- Open-ended questions

11.-- Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.
SELECT
	year,
	team,
	perc_change,
	CORR(total_salary::int, wins)OVER(PARTITION BY team ORDER BY year) AS correlation
FROM(
	SELECT
		s.teamid AS team,
		s.yearid AS year,
		SUM(s.salary) AS total_salary,
		t.w AS wins,
		LAG(t.w) OVER(PARTITION BY t.teamid ORDER BY s.yearid) AS prev_year_wins,
		t.w - LAG(t.w) OVER(PARTITION BY t.teamid ORDER BY s.yearid) AS yoy_win_diff,
		SUM(s.salary) - LAG(SUM(s.salary)) OVER(PARTITION BY t.teamid ORDER BY s.yearid) yoy_salary_diff,
		LAG(SUM(s.salary)) OVER(PARTITION BY t.teamid ORDER BY s.yearid) AS previous_year_salary,
		SUM(s.salary) / LAG(SUM(s.salary)) OVER (PARTITION BY t.teamid ORDER BY s.yearid)-1 AS perc_change
	FROM salaries AS s
	INNER JOIN teams AS t
	ON s.teamid = t.teamid AND s.yearid = t.yearid
	WHERE s.yearid >= 2000 
	GROUP BY s.yearid, s.teamid, t.w, t.teamid
	ORDER BY t.teamid, s.yearid
) sub
GROUP BY year, team, total_salary, wins, perc_change
ORDER BY team, year;

--ANSWER: 

12.-- In this question, you will explore the connection between number of wins and attendance.
-- Does there appear to be any correlation between attendance at home games and number of wins?
-- Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.

SELECT
	year,
	team,
	attendance,
	attendance_prev,
	attendance - attendance_prev AS difference,
	CASE WHEN attendance > attendance - attendance_prev THEN 'INCREASE' ELSE 'BLAH' END AS YURP
FROM (
SELECT 
	hg.year AS year,
	hg.team AS team,
	t.w AS wins,
	SUM(hg.attendance) AS attendance,
	(SELECT SUM(hg2.attendance)
		FROM homegames AS hg2
		WHERE hg2.team = hg.team AND hg2.year = hg.year - 1) AS attendance_prev
FROM homegames AS hg
INNER JOIN teams AS t
ON t.teamid = hg.team AND t.yearid = hg.year
GROUP BY hg.year, hg.team, t.w
ORDER BY team)



13.-- It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?

