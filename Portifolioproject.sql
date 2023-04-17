Use [PortifolioProject];

Select * from [dbo].[CovidDeaths$]
where continent is not null;

select * from [dbo].[CovidVaccination$];

--select Data that we are going to be using

select Location, date, total_cases, new_cases, total_deaths, population
from [dbo].[CovidDeaths$]
where continent is not null
order by 1,2;

--Total Cases vs Total Deaths
--Percentage of Deaths who had Covid19

select Location, date, total_cases, total_deaths, 
       round (cast(total_deaths as float)/cast(total_cases as float)* 100, 2) as Death_Percentage
from [dbo].[CovidDeaths$]
--where location like '%africa%'
where continent is not null
order by 1,2;

--Total cases vs Population
--Percentage of people who got Covid19

select Location, date, total_cases, population, 
       round (cast(total_cases as float)/cast(population as float)* 100, 2) as Population_Percentage
from [dbo].[CovidDeaths$]
--where location like '%africa%'
where continent is not null
order by 1,2;

--Countries with the Highest Infection Rate per Population

select Location, Population, max(total_cases) as Highest_InfectionCounts,
       round(max (cast(total_cases as float)/cast(population as float)* 100), 2) as Population_PercentageInfected
from [dbo].[CovidDeaths$]
--where location like '%africa%'
where continent is not null
group by Location, Population
order by Population_PercentageInfected desc;

--Countries with the Highest Death Counts

select Location, max(cast(total_deaths as int)) as Highest_DeathCounts
from [dbo].[CovidDeaths$]
--where location like '%africa%'
where continent is not null
group by Location
order by Highest_DeathCounts desc;


--BREAKING DOWN BY CONTINENT

--Continents with the Highest Death Counts

select continent, max(cast(total_deaths as int)) as Highest_DeathCounts
from [dbo].[CovidDeaths$]
--where location like '%africa%'
where continent is not null
group by continent
order by Highest_DeathCounts desc;


--GLOBAL NUMBERS

SELECT Date, 
       sum(new_cases) as Total_newcases, 
       sum(cast(new_deaths as int)) as Total_newdeaths, 
       CASE WHEN sum(new_cases) = 0 
            THEN NULL 
            ELSE sum(cast(new_deaths as int))/sum(new_cases)* 100 
       END as NewDeath_Percentage
FROM [dbo].[CovidDeaths$]
WHERE continent IS NULL
GROUP BY Date
ORDER BY 1,2;

SELECT 
       sum(new_cases) as Total_newcases, 
       sum(cast(new_deaths as int)) as Total_newdeaths, 
       CASE WHEN sum(new_cases) = 0 
            THEN NULL 
            ELSE sum(cast(new_deaths as int))/sum(new_cases)* 100 
       END as NewDeath_Percentage
FROM [dbo].[CovidDeaths$]
WHERE continent IS NULL
--GROUP BY Date
ORDER BY 1,2;


