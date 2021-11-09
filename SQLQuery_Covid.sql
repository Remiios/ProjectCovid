
-- Wyświetlenie tabel CovidDeaths oraz CovidVaccinations


-- continent ma wartość NULL gdy w location znajdują się nazwy kontynentów wraz z danymi dotyczącymi wirusa covid w kolejnych dniach

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent is not null				-- Wyświetl bez danych NULL w continent
ORDER BY 3,4;							-- Segregowanie po kolumnach lokacja i data



SELECT * 
FROM PortfolioProject..CovidVaccinations
WHERE continent is not null
ORDER BY 3,4;



-- Wybór kolumn i segregowanie po lokacji i dacie

SELECT location, 
	date, 
	total_cases, 
	new_cases, 
	total_deaths, 
	population
FROM PortfolioProject..CovidDeaths
ORDER BY location, date;



-- Procent zgonów z powodu wirusa do ilości zakażonych w danym dniu

SELECT location, 
	date, 
	total_cases, 
	total_deaths, 
	(total_deaths / total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
--WHERE location like '%Poland%' -- Opcjonalna klauzura, która wskaże dane gdzie w kolumnie lokacja jest słowo zawierające ciąg znaków "Poland"
ORDER BY location, date;



-- Procent zgonów do populacji danego kraju w danym dniu

SELECT location, 
	date, 
	population,
--	total_cases,
	total_deaths, 
	(total_deaths / population)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
--WHERE date = '2021-10-01'
ORDER BY location, date;



-- Procent liczby zakażonych osób do całej populacji danego kraju 

SELECT location, 
	date, 
	population, 
	total_cases, 
	(total_cases / population)*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
ORDER BY location, date;



-- Kraje z najwyższym procentem osób zakażonych do liczby ludności 

SELECT location, 
	population, 
	MAX(total_cases) AS HighestInfectionCount, 
	MAX((total_cases / population)*100) AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY PercentPopulationInfected desc;



-- Kraje z najwyższą liczbą zgonów spowodowanych wirusem

SELECT location, 
	MAX(cast(total_deaths AS int)) AS TotalDeathsCount					-- zmiana nvarchar na int
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathsCount desc;



-- Kontynenty z liczbą zgonów spowodowanych wirusem

SELECT continent, 
	MAX(cast(total_deaths AS int)) AS TotalDeathsCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathsCount desc;



-- Globalne wartości z podziałem na dni 
-- Liczba zakażeń, zgonów z każdego dnia na świecie oraz procent zgonów na liczbę zakażonych

SELECT date, 
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
	date;



-- Populacja danego kraju wraz z liczbą osób zaszczepionych z podziałem na dni

SELECT dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations
FROM 
	PortfolioProject..CovidDeaths dea
JOIN
	PortfolioProject..CovidVaccinations vac
ON
	dea.location = vac.location and dea.date = vac.date				-- łączenie tabel po kolumnach lokacja oraz data
WHERE
	dea.continent is not null
ORDER BY 
	dea.continent, dea.location;



-- Wzrastająca z kolejnymi dniami liczba zaszczepionych z podziałem na kraje, kontynenty 

SELECT dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, CONVERT(datetime, dea.date)) AS RollingPeopleVaccinated
-- sumowanie liczby zaszczepionych osób każdego dnia z sortowaniem na kraje oraz datę
FROM 
	PortfolioProject..CovidDeaths dea
JOIN
	PortfolioProject..CovidVaccinations vac
ON
	dea.location = vac.location and dea.date = vac.date
WHERE
	dea.continent is not null
ORDER BY 
	dea.location, dea.date;



-- użycie CTE (common table expression - wspólne wyrażenie tablicowe) aby obliczyć procent z stworzonej nowej zmiennej
-- klauzura WITH działa podobnie jak prefix SELECT
-- Sumowanie liczby zaszczepionych oraz procent osób zaszczepionych (do danego dnia) w porównaniu do całkowitej populacji kraju

WITH PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)		-- kolumny takie same jak w klauzuli SELECT
AS
(
SELECT dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, CONVERT(datetime, dea.date)) AS RollingPeopleVaccinated
FROM 
	PortfolioProject..CovidDeaths dea
JOIN
	PortfolioProject..CovidVaccinations vac
ON
	dea.location = vac.location and dea.date = vac.date
WHERE
	dea.continent is not null
-- ORDER BY 
-- dea.location, dea.date;
-- Klauzura WITH nie obsługuje ORDER BY
)
SELECT *, 
	(RollingPeopleVaccinated/population)*100 AS PercentageVaccinatedPeople
FROM PopVsVac
ORDER BY 
	PopVsVac.location, PopVsVac.date;



-- Tworzenie tabeli tymczasowej - Temporary Table

DROP TABLE IF exists #PercentPopulationVaccinated			-- Zabezpieczenie przed błędem 
Create Table #PercentPopulationVaccinated					-- Tworzenie tabeli tymczasowej z podanymi kolumnami i typami danych
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric, 
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated					-- Wstaw dane do tabeli tymczasowej
SELECT dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, CONVERT(datetime, dea.date)) AS RollingPeopleVaccinated
FROM 
	PortfolioProject..CovidDeaths dea
JOIN
	PortfolioProject..CovidVaccinations vac
ON
	dea.location = vac.location and dea.date = vac.date
WHERE
	dea.continent is not null

SELECT *, (RollingPeopleVaccinated/population)*100 AS PercentageVaccinatedPeople
FROM #PercentPopulationVaccinated;



-- Tworzenie widoku danych do późniejszych działań 

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, CONVERT(datetime, dea.date)) AS RollingPeopleVaccinated
FROM 
	PortfolioProject..CovidDeaths dea
JOIN
	PortfolioProject..CovidVaccinations vac
ON
	dea.location = vac.location and dea.date = vac.date
WHERE
	dea.continent is not null;



-- Usuwanie widoku 
-- DROP VIEW PercentPopulationVaccinated



-- Wyświetlenie danych z stworzonego widoku

SELECT *
FROM PercentPopulationVaccinated
ORDER BY 
	location, date;



-- średnia wieku populacji krajów oraz średnia długości życia od największej

SELECT vac.continent,
	vac.location,
	median_age,
	life_expectancy
FROM
	PortfolioProject..CovidDeaths dea
JOIN
	PortfolioProject..CovidVaccinations vac
ON
	dea.location = vac.location and dea.date = vac.date
WHERE
	dea.continent is not null
GROUP BY 
	vac.continent, vac.location, median_age, life_expectancy
ORDER BY 
	life_expectancy DESC;




-- Kraje w Europie z zagęszczeniem ludności oraz całkowitą liczbą przypadków na dzień 1 czerwca 2021

SELECT dea.continent,
	vac.location,
	vac.date,
	population_density,
	dea.total_cases
FROM
	PortfolioProject..CovidDeaths dea
JOIN
	PortfolioProject..CovidVaccinations vac
ON
	dea.location = vac.location and dea.date = vac.date
WHERE
	dea.continent is not null AND dea.continent = 'Europe' AND vac.date = '2021-06-01'
ORDER BY 
	vac.location ASC;

	
-- Kolejne agregacje wkrótce
