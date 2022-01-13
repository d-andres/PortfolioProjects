/* COVID Death and Vaccination Tables*/
SELECT *
FROM PortfolioProject..CovidDeaths$
ORDER BY location, date;

SELECT *
FROM PortfolioProject..CovidVaccinations$
ORDER BY location, date;

/* Procedures */
-- To check stored procedures
SELECT name AS procedure_name, SCHEMA_NAME(schema_id) AS schema_name, create_date
FROM sys.procedures;

-- Select specific location
GO
CREATE PROCEDURE SelectLocation @loc nvarchar(30) AS 
	SELECT * FROM PortfolioProject..CovidDeaths$ 
	WHERE location = @loc;
--EXEC SelectLocation @loc = 'United States'
--DROP PROCEDURE SelectLocation;

-- Select CovidDeath with preferred columns
GO
CREATE PROCEDURE SelectCovidDeaths AS
	SELECT location, date, total_cases, new_cases, total_deaths, population
	From PortfolioProject..CovidDeaths$
	ORDER BY 1, 2;
--DROP PROCEDURE SelectCovidDeaths;


/* Data Comparison */

-- Total Cases vs Total Deaths
-- likelihood of dying if contract covid in U.S.
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE location LIKE '%United States%'
ORDER BY date DESC;

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid
SELECT location, date, total_cases, population, (total_cases/population)*100 AS PopulationInfectedPercentage
FROM PortfolioProject..CovidDeaths$
--WHERE location LIKE '%United States%'
ORDER BY location, date DESC;

-- Countries with Highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) as HighestInfectionCount, Max((total_cases/population))*100 AS PopulationInfectedPercentage
FROM PortfolioProject..CovidDeaths$
GROUP BY location, population
ORDER BY PopulationInfectedPercentage DESC

-- Countries with Highest Death Count per Population
SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- Continents with the highest death count per population
SELECT continent, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- World death count statistics
SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- Global Numbers
SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths AS int))/SUM(new_cases)*100 AS DeathPercentage--,date
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1 DESC;


-- Total Population vs Vaccinations
-- Shows percentage of population that has received at least one Covid Vaccine
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS TotalVaccinatedToDate
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 1,2,3 DESC

-- Using Common Table Expression(CTE) to get VaccinatedToDatePercentage
WITH PopVsVac(continent, location, date, population, new_vaccinations, TotalVaccinatedToDate) AS
(
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
		SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS TotalVaccinatedToDate
	FROM PortfolioProject..CovidDeaths$ dea
	JOIN PortfolioProject..CovidVaccinations$ vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
)
SELECT *, (TotalVaccinatedToDate/population)*100 AS VacToPopByDatePercent
FROM PopVsVac
WHERE TotalVaccinatedToDate IS NOT NULL;
GO



-- Creating View to store data for later visualizations
CREATE VIEW PopulationVaccinatedPercent AS
(
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
		SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS TotalVaccinatedToDate
	FROM PortfolioProject..CovidDeaths$ dea
	JOIN PortfolioProject..CovidVaccinations$ vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent is not null 
)
GO