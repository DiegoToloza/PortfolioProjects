SELECT * 
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

--SELECT * 
--FROM PortfolioProject..CovidVaccination
--ORDER BY 3,4

--Seleccionamos la informacion que utilizaremos

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

--Compararemos los casos totales vs las muertes totales
--Muestra la posibildad de morir si contraiste covid en tu pais

SELECT location, date, total_cases, total_deaths, (total_deaths / NULLIF(total_cases, 0)) * 100 AS death_percentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%Chile%'
AND continent IS NOT NULL
ORDER BY 1,2


--Compararemos los casos totales con la poblacion
--Muestra el porcentaje de la poblacion que contrajo el covid

SELECT location, date, total_cases, population, (total_cases / NULLIF(population, 0)) * 100 AS percentage_population_infected
FROM PortfolioProject..CovidDeaths
WHERE location like '%Chile%'
AND continent IS NOT NULL
ORDER BY 1,2


--Buscaremos los paises con mayor tasa de infeccion comparada con su poblacion

SELECT location, population, MAX(total_cases) as highiest_infection_count, MAX((total_cases / NULLIF(population, 0))) * 100 AS percentage_population_infected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
--WHERE location like '%Chile%'
GROUP BY location, population
ORDER BY percentage_population_infected desc

--Ahora veremos los paises con mayor cantidad de fallecidos en comparacion a su poblacion

SELECT location, MAX(cast(total_deaths as BIGINT)) as total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count desc


--Ahora lo veremos por continentes, también agrupandolo por los ingresos en algunos casos

--SELECT location, MAX(cast(total_deaths as BIGINT)) as total_death_count
--FROM PortfolioProject..CovidDeaths
--WHERE continent IS NULL
--GROUP BY location
--ORDER BY total_death_count desc


--Ahora veremos los continentes con mayor tasa de muertes en su poblacion
SELECT continent, MAX(cast(total_deaths as BIGINT)) as total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count desc

-- Número globales
SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as BIGINT)) as total_deaths, (SUM(cast(new_deaths as BIGINT))/NULLIF(SUM(new_cases), 0) * 100) as death_percentage_global
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
order by 1,2


----------------------------------------------------
--Ahora veremos nuestro dataset de las vacunaciones
----------------------------------------------------



--Uniremos los datasets para ver la población total vs las vacunaciones

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as sum_people_vaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccination vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--USAREMOS UN CTE

WITH PopvsVac(continent, location, date, population, new_vaccinations, sum_people_vaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as sum_people_vaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccination vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (sum_people_vaccinated/population)*100 AS percentage_population_vaccinated	
FROM PopvsVac

-- También podemos usar una TEMP TABLE

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population bigint,
new_vaccinations numeric,
sum_people_vaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as sum_people_vaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccination vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (sum_people_vaccinated/population)*100 AS percentage_population_vaccinated	
FROM #PercentPopulationVaccinated



-- Crearemos una vista para guardar datos para luego
USE [PortfolioProject];

CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as sum_people_vaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccination vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *
FROM PercentPopulationVaccinated 