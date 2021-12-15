SELECT * 
FROM [Covid project]..CovidDeaths$
WHERE continent is not null
Order by 3,4

SELECT * 
FROM [Covid project].dbo.CovidVaccinations$

--select data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [Covid project]..CovidDeaths$
WHERE continent is not null
Order by 3,4

--looking total cases vs total deaths
--shows likelihood to catch a covid in your country
SELECT location, date, total_cases, total_deaths, 100*(total_deaths/total_cases) AS DeadthPercentage
FROM [Covid project]..CovidDeaths$
Where location='Israel'
Order by 5  DESC

-- Looking at Total Cases vs populations
--Shows what percentage of the population got sicked
SELECT location, date, population, total_cases, 100*(total_cases/population) AS CovidSickPercentage
FROM [Covid project]..CovidDeaths$
--Where location='Israel'
Order by 1,2  DESC

--Looking at countries with a highest infection rate
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX(100*(total_cases/population)) AS CovidSickPercentage
FROM [Covid project]..CovidDeaths$
--Where location='Israel'
WHERE continent is not null
Group by location, population
Order by CovidSickPercentage desc

--Showing countries with the highest death count per population
SELECT location, MAX(cast (total_deaths as bigint)) AS TotalDeathCount
FROM [Covid project]..CovidDeaths$
WHERE continent is not null
Group by location
Order by TotalDeathCount desc

--Breaking by continents
--Showing continents with the highest death count

SELECT continent, MAX(cast (total_deaths as bigint)) AS TotalDeathCount
FROM [Covid project]..CovidDeaths$
WHERE continent is null
Group by continent
Order by TotalDeathCount desc

--Global
SELECT MAX(new_cases) as total_cases, SUM(cast (new_deaths as int)) as total_deaths, (SUM(cast (new_deaths as int))/sum(new_cases))*100 AS CovidSickPercentage
FROM [Covid project]..CovidDeaths$
Where continent is not null
--Group by date
Order by 1,2 

--Looking at total population vs total vaccination

With Pops_vs_Vac (Continent, Location, date, population, new_vaccinations, RollingPeopleVaccinated)
as (
SELECT dea.continent, dea.location , dea.date, dea.population, vac.new_vaccinations, 
sum(cast(vac.new_vaccinations as bigint)) OVER (partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--(PeopleVaccinationDayCounting/population)*100
FROM [Covid project].dbo.CovidDeaths$ dea
JOIN [Covid project].dbo.covidVaccinations$ vac
ON dea.location=vac.location
and dea.date=vac.date
WHERE dea.continent is not null
--Order by 2,3
)

Select *, (RollingPeopleVaccinated/population)*100 AS PercentPopulationVaccinated
FROM  Pops_vs_Vac

-- Using Temp Table to perform Calculation on Partition By in previous query
Select *
FROM #PercentPopulationVaccinated

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population bigint,
New_vaccinations bigint,
RollingPeopleVaccinated bigint)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
(SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date)) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From [Covid project].dbo.CovidDeaths$ dea
Join [Covid project].dbo.CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

--Create view for future data visualizations

Create View PercentPopulationVaccinated as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
(SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date)) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From [Covid project]..CovidDeaths dea
Join [Covid project]..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

SELECT * 
PercentPopulationVaccinated