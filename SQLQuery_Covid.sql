
-- Wyœwietlenie danych i pogrupowanie ich po kolumnach 3,4 (Kraj, Data)

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 3,4;

--SELECT * 
--FROM dbo.CovidVaccinations
--ORDER BY 3,4;



-- Wybór danych i pogrupowanie po kolumnach 1,2 (Kraj, Data)
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2;



-- Procent œmierci do iloœci zaka¿onych 
-- (wyszukanie dla danego kraju)

SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
-- WHERE location like '%Poland%'
ORDER BY 1,2;



-- Procent œmierci do populacji

SELECT location, date, population, total_deaths, (total_deaths / population)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2;


-- Procent zaka¿eñ do populacji

SELECT location, date, population, total_cases, (total_cases / population)*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2;



-- Kraje z najwy¿sz¹ œredni¹ zaka¿eñ na iloœæ mieszkañców

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases / population)*100) AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected desc;


-- Kraje z najwy¿sz¹ liczb¹ œmierci

SELECT location, MAX(cast(total_deaths AS int)) AS TotalDeathsCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathsCount desc;


SELECT continent, MAX(cast(total_deaths AS int)) AS TotalDeathsCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathsCount desc;


-- Kontynenty z najwy¿sz¹ œredni¹ œmierci na populacjê
SELECT continent, MAX(cast(total_deaths AS INT)) AS TotalDeathsCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathsCount desc;


-- GLOBALNE LICZBY

SELECT 
	date, 
	SUM(new_cases) AS CountCases, 
	SUM(cast(new_deaths as INT)) AS CountDeaths,
	SUM(cast(new_deaths as INT))/SUM(new_cases)*100 AS DeathPercentage
FROM 
	PortfolioProject..CovidDeaths
WHERE 
	continent is not null
GROUP BY 
	date
ORDER BY 
	1;



-- Liczba populacji na œwiecie vs liczba zaszczepionych

SELECT 
	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM 
	PortfolioProject..CovidDeaths dea
JOIN
	PortfolioProject..CovidVaccinations vac
ON
	dea.location = vac.location and dea.date = vac.date
WHERE
	dea.continent is not null
ORDER BY 
	2,3;


-- Liczba populacji na œwiecie vs liczba zaszczepionych2

SELECT 
	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, CONVERT(datetime, dea.date)) AS RollingPeopleVaccinated
	--, (RollingPeopleVaccinated/population)*100
FROM 
	PortfolioProject..CovidDeaths dea
JOIN
	PortfolioProject..CovidVaccinations vac
ON
	dea.location = vac.location and dea.date = vac.date
WHERE
	dea.continent is not null
ORDER BY 
	2,3;



-- USE CTE

WITH PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT 
	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, CONVERT(datetime, dea.date)) AS RollingPeopleVaccinated
	--, (RollingPeopleVaccinated/population)*100
FROM 
	PortfolioProject..CovidDeaths dea
JOIN
	PortfolioProject..CovidVaccinations vac
ON
	dea.location = vac.location and dea.date = vac.date
WHERE
	dea.continent is not null
--ORDER BY 
--	2,3;
)
SELECT *, (RollingPeopleVaccinated/population)*100 AS PercentageVaccinatedPeople
FROM PopVsVac;


--TEMP TABLE

DROP TABLE IF exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric, 
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated

SELECT 
	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, CONVERT(datetime, dea.date)) AS RollingPeopleVaccinated
	--, (RollingPeopleVaccinated/population)*100
FROM 
	PortfolioProject..CovidDeaths dea
JOIN
	PortfolioProject..CovidVaccinations vac
ON
	dea.location = vac.location and dea.date = vac.date
WHERE
	dea.continent is not null
--ORDER BY 
--	2,3;

SELECT *, (RollingPeopleVaccinated/population)*100 AS PercentageVaccinatedPeople
FROM #PercentPopulationVaccinated;




-- TWORZENIE danych do póŸniejszych wizualizacji 


CREATE VIEW PercentPopulationVaccinated as
SELECT 
	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, CONVERT(datetime, dea.date)) AS RollingPeopleVaccinated
	--, (RollingPeopleVaccinated/population)*100
FROM 
	PortfolioProject..CovidDeaths dea
JOIN
	PortfolioProject..CovidVaccinations vac
ON
	dea.location = vac.location and dea.date = vac.date
WHERE
	dea.continent is not null;
-- ORDER BY 2,3;


SELECT *
FROM PercentPopulationVaccinated
