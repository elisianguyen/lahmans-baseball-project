-- What range of years for baseball games played does the provided database cover?

SELECT
	yearid
FROM teams
GROUP BY yearid
ORDER BY yearid ASC;

-- ANSWER: 1871 THROUGH 2016

-- Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?

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

-- Find all players in the database who played at Vanderbilt University. PEOPLE TABLE
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


-- Using the fielding table, group players into three groups based on their position: label players with position 
--OF as "Outfield", those with position 
--"SS", "1B", "2B", and "3B" as "Infield", and those with position 
--"P" or "C" as "Battery". 
--Determine the number of putouts made by each of these three groups in 2016.

WITH X AS (
SELECT 
	playerid
	,CASE 
		WHEN pos = 'OF' THEN 'Outfield'
		WHEN pos = 'SS' THEN 'Infield'
		WHEN pos = '1B' THEN 'Infield'
		WHEN pos = '2B' THEN 'Infield'
		WHEN pos = '3B' THEN 'Infield'
		WHEN pos = 'P' THEN 'battery'
		WHEN pos = 'C' THEN 'battery'
		ELSE 'BLAH' END AS position_groups
	,SUM(po)
FROM fielding
)
SELECT
	position_groups
	,po
FROM X
GROUP BY position_groups

-- Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?

-- Find the player who had the most success stealing bases in 2016, where success is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted at least 20 stolen bases.

-- From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

-- Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.

-- Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

-- Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.

-- Open-ended questions

-- Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

-- In this question, you will explore the connection between number of wins and attendance.

-- Does there appear to be any correlation between attendance at home games and number of wins?
-- Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.
-- It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?