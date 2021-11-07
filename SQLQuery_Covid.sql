
-- Wyswietlenie tabel CovidDeaths oraz CovidVaccinations


-- continent ma wartosc NULL gdy w location znajduja sie nazwy kontynentów wraz z danymi dotyczacymi wirusa covid w kolejnych dniach

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent is not null				-- Wyswietl bez danych NULL w continent
ORDER BY 3,4;							-- Segregowanie po kolumnach lokacja i data



SELECT * 
FROM PortfolioProject..CovidVaccinations
WHERE continent is not null
ORDER BY 3,4;



-- Wybor kolumn i segregowanie po lokacji i dacie

SELECT location, 
	date, 
	total_cases, 
	new_cases, 
	total_deaths, 
	population
FROM PortfolioProject..CovidDeaths
ORDER BY location, date;



-- Procent zgonow z powodu wirusa do ilosci zakazonych w danym dniu

SELECT location, 
	date, 
	total_cases, 
	total_deaths, 
	(total_deaths / total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
-- WHERE location like '%Poland%' - Opcjonalna klauzura, która wska¿e dane gdzie w kolumnie lokacja jest s³owo zawieraj¹ce ci¹g znaków "Poland"
ORDER BY location, date;



-- Procent zgonow do populacji danego kraju w danym dniu

SELECT location, 
	date, 
	population, 
	total_deaths, 
	(total_deaths / population)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
ORDER BY location, date;



-- Procent liczby zakazonych osób do calej populacji danego kraju 

SELECT location, 
	date, 
	population, 
	total_cases, 
	(total_cases / population)*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
ORDER BY location, date;



-- Kraje z najwyzszym procentem osób zakazonych do liczby ludnosci 

SELECT location, 
	population, 
	MAX(total_cases) AS HighestInfectionCount, 
	MAX((total_cases / population)*100) AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY PercentPopulationInfected desc;



-- Kraje z najwyzsza liczba zgonów spowodowanych wirusem

SELECT location, 
	MAX(cast(total_deaths AS int)) AS TotalDeathsCount					-- zmiana nvarchar na int
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathsCount desc;



-- Kontynenty z liczba zgonów spowodowanych wirusem

SELECT continent, 
	MAX(cast(total_deaths AS int)) AS TotalDeathsCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathsCount desc;



-- Globalne wartosci z podzialem na dni 
-- Liczba zakazen, zgonow z kazdego dnia na swiecie oraz procent zgonów na liczbe zakazonych

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



-- Populacja danego kraju wraz z liczba osób zaszczepionych z podzialem na dni

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
	dea.location = vac.location and dea.date = vac.date				-- laczenie tabel po kolumnach lokacja oraz data
WHERE
	dea.continent is not null
ORDER BY 
	dea.continent, dea.location;



-- Wzrastajaca z kolejnymi dniami liczba zaszczepionych z podzialem na kraje, kontynenty 

SELECT dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, CONVERT(datetime, dea.date)) AS RollingPeopleVaccinated
-- sumowanie liczby zaszczepionych osob kazdego dnia z sortowaniem na kraje oraz date
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



-- uzycie CTE (common table expression - wspolne wyrazenie tablicowe) aby obliczyc procent z stworzonej nowej zmiennej
-- klauzura WITH dziala podobnie jak prefix SELECT
-- Sumowanie liczby zaszczepionych oraz procent osob zaszczepionych (do danego dnia) w porownaniu do calkowitej populacji kraju

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
-- Klauzura WITH nie obsluguje ORDER BY
)
SELECT *, 
	(RollingPeopleVaccinated/population)*100 AS PercentageVaccinatedPeople
FROM PopVsVac
ORDER BY 
	PopVsVac.location, PopVsVac.date;



-- Tworzenie tabeli tymczasowej - Temporary Table

DROP TABLE IF exists #PercentPopulationVaccinated				-- Zabezpieczenie przed bledem 
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



-- Tworzenie widoku danych do pozniejszych dzialan

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


-- Wyswietlenie danych z stworzonego widoku
SELECT *
FROM PercentPopulationVaccinated
ORDER BY 
	location, date;
	
	
-- Kolejne agregacje wkrótce
