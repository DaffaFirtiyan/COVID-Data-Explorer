/*
Covid Data Exploration

Queries used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate FUnctions, Creating Views, Converting Data Types
*/

select *
from CovidDeaths
where continent is not null
order by 3,4

-- select data that we're starting with
select location, date, total_cases, new_cases, total_deaths, population
from CovidDeaths
where continent is not null
order by 1,2

-- total cases vs. total deaths
-- shows the likelihood of dying if you get covid in your country
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
from CovidDeaths
where continent is not null
order by 1,2

-- total cases vs. population
-- shows percentage of population has covid
select location, date, total_cases, (total_cases/population)*100 as percent_population_infected
from CovidDeaths
where location like '%zealand%'
order by 1,2

-- countries with highest infection rate compared to population
select location, population, max(total_cases) as highest_infection_count, max(total_cases/population)*100 as percent_population_infected
from CovidDeaths
group by location, population
order by percent_population_infected desc

-- coutnries with highest death couth per population
select location, max(cast(total_deaths as int)) as total_death_count
from CovidDeaths
where continent is not null
group by location
order by total_death_count desc

/*
Dividing things by continents
*/

-- showing continents with the highest death count per population
select continent, max(cast(total_deaths as int)) as total_death_count
from CovidDeaths
where continent is not null
group by continent
order by total_death_count desc

-- GLOBAL NUMBERS
select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as death_percentage
from CovidDeaths
where continent is not null
order by 1,2

-- total population vs. vaccinations
-- shows the percentage of population that has received at least one vaccine shot
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as rolling_people_vaccinated
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3


-- using CTE (commont teable expression) to perform calculation on Partition By in previous query
with PopvsVac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as rolling_people_vaccinated
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
select *, (rolling_people_vaccinated/population)*100
from PopvsVac

-- using temp table to do calculation on Partition By in previous query
drop table if exists PercentPopulationVaccinated
create table PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
)

insert into PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as rolling_people_vaccinated
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date

-- Create View to store data for later visualisations
create view PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as rolling_people_vaccinated
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null