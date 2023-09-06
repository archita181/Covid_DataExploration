---->NOTE:when continent is null, location is an entire continent, eg: continent = null, location = Asia
select * from dbo.CovidDeaths
where continent is not null
order by 3,4;

select location,Date,total_cases,new_cases,total_deaths,population
from dbo.CovidDeaths
order by 1,2;

--Looking at Total Cases vs Total Deaths (Percent of people died)
select location,Date,total_cases,total_deaths,(total_deaths/total_cases)*100 as DeathPercentage
from dbo.CovidDeaths
where location in ('India')
order by 1,2;

--Total Cases vs Population (what percent of population got covid)
select location,Date,total_cases,population,(total_cases/population)*100 as PercentPopulationInfected
from dbo.CovidDeaths
where location in ('India')
order by 1,2;

--Countries with highest infection rate compared to population
select location,population, MAX(total_cases) as HighestInfectionCount,
MAX((total_cases/population))*100 as PercentPopulationInfected
from dbo.CovidDeaths
--where location in ('India')
group by location,population
order by PercentPopulationInfected desc;

--Countries with highest death rate per population
select location, MAX(total_deaths) as HighestDeathcount
from dbo.CovidDeaths
--where location in ('India')
where continent is not null
group by location
order by HighestDeathcount desc;

select location, MAX(total_deaths) as HighestDeathcount
from dbo.CovidDeaths
--where location in ('India')
where continent is null
group by location
order by HighestDeathcount desc; --gives accurate numbers

--BREAKING THINGS BY CONTINENT

--Continents with highest death count per population
select continent, MAX(total_deaths) as HighestDeathcount
from dbo.CovidDeaths
--where location in ('India')
where continent is not null
group by continent
order by HighestDeathcount desc; --gives inacccurate data


--GLOBAL NUMBERS (numbers across the world per each day)
select Date, SUM(new_cases) as TotalCases, SUM(new_deaths) as TotalDeaths,
(SUM(new_deaths)/SUM(new_cases))*100 as DeathPercentage
from dbo.CovidDeaths
--where location in ('India')
where continent is not null
group by date
order by 1,2;

select SUM(new_cases) as TotalCases, SUM(new_deaths) as TotalDeaths,
(SUM(new_deaths)/SUM(new_cases))*100 as DeathPercentage
from dbo.CovidDeaths
where continent is not null
order by 1,2; --total number across the world

-------------------------------------------------------------------------

select * 
from dbo.CovidDeaths death
join dbo.CovidVaccinations vax
on death.location = vax.location
and death.date = vax.date

--Total Population vs Vaccination (total amount of people that have been vaccinated)
select death.continent, death.location, death.date, death.population, vax.new_vaccinations,
sum(convert(int,vax.new_vaccinations)) over (partition by death.location order by death.location, death.date) as RollingCount
from dbo.CovidDeaths death
join dbo.CovidVaccinations vax
on death.location = vax.location
and death.date = vax.date
where death.continent is not null
order by 2,3;

--USE CTE

with PopVSVax (continent, location, date, population, new_vaccinations, RollingCount)
as
(
    select 
    death.continent, death.location, death.date, death.population, vax.new_vaccinations,
    sum(convert(int,vax.new_vaccinations)) 
        over (partition by death.location order by death.location, death.date) as RollingCount
    from dbo.CovidDeaths death
    join dbo.CovidVaccinations vax
    on death.location = vax.location
    and death.date = vax.date
    where death.continent is not null
    --order by 2,3   
)
select *, (RollingCount/population)*100 
from PopVSVax

--USE TEMP TABLE

DROP table if exists #PercentPopulationVaccinated

CREATE table #PercentPopulationVaccinated
(
    continent NVARCHAR(255),
    location NVARCHAR(255),
    date DATETIME,
    population NUMERIC,
    new_vaccinations NUMERIC,
    RollingCount numeric
)

INSERT into #PercentPopulationVaccinated
select 
    death.continent, death.location, death.date, death.population, vax.new_vaccinations,
    sum(convert(int,vax.new_vaccinations)) 
        over (partition by death.location order by death.location, death.date) as RollingCount
    from dbo.CovidDeaths death
    join dbo.CovidVaccinations vax
    on death.location = vax.location
    and death.date = vax.date
    where death.continent is not null
    --order by 2,3 

select *, (RollingCount/population)*100 
from #PercentPopulationVaccinated

--VIEW

CREATE VIEW PercentPopulationVaccinated as 
select 
    death.continent, death.location, death.date, death.population, vax.new_vaccinations,
    sum(convert(int,vax.new_vaccinations)) 
        over (partition by death.location order by death.location, death.date) as RollingCount
    from dbo.CovidDeaths death
    join dbo.CovidVaccinations vax
    on death.location = vax.location
    and death.date = vax.date
    where death.continent is not null

select * from PercentPopulationVaccinated;