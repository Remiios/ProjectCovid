
-- Wy�wietlenie tabel CovidDeaths oraz CovidVaccinations


-- continent ma warto�� NULL gdy w location znajduj� si� nazwy kontynent�w wraz z danymi dotycz�cymi wirusa covid w kolejnych dniach

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent is not null				-- Wy�wietl bez danych NULL w continent
ORDER BY 3,4;							-- Segregowanie po kolumnach lokacja i data



SELECT * 
FROM PortfolioProject..CovidVaccinations
WHERE continent is not null
ORDER BY 3,4;



-- Wyb�r kolumn i segregowanie po lokacji i dacie

SELECT location, 
	date, 
	total_cases, 
	new_cases, 
	total_deaths, 
	population
FROM PortfolioProject..CovidDeaths
ORDER BY location, date;



-- Procent zgon�w z powodu wirusa do ilo�ci zaka�onych w danym dniu

SELECT location, 
	date, 
	total_cases, 
	total_deaths, 
	(total_deaths / total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
-- WHERE location like '%Poland%' - Opcjonalna klauzura, kt�ra wska�e dane gdzie w kolumnie lokacja jest s�owo zawieraj�ce ci�g znak�w "Poland"
ORDER BY location, date;



-- Procent zgon�w do populacji danego kraju w danym dniu

SELECT location, 
	date, 
	population, 
	total_deaths, 
	(total_deaths / population)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
ORDER BY location, date;



-- Procent liczby zaka�onych os�b do ca�ej populacji danego kraju 

SELECT location, 
	date, 
	population, 
	total_cases, 
	(total_cases / population)*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
ORDER BY location, date;



-- Kraje z najwy�szym procentem os�b zaka�onych do liczby ludno�ci 

SELECT location, 
	population, 
	MAX(total_cases) AS HighestInfectionCount, 
	MAX((total_cases / population)*100) AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY PercentPopulationInfected desc;



-- Kraje z najwy�sz� liczb� zgon�w spowodowanych wirusem

SELECT location, 
	MAX(cast(total_deaths AS int)) AS TotalDeathsCount					-- zmiana nvarchar na int
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathsCount desc;



-- Kontynenty z liczb� zgon�w spowodowanych wirusem

SELECT continent, 
	MAX(cast(total_deaths AS int)) AS TotalDeathsCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathsCount desc;



-- Globalne warto�ci z podzia�em na dni 
-- Liczba zaka�e�, zgon�w z ka�dego dnia na �wiecie oraz procent zgon�w na liczb� zaka�onych

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



-- Populacja danego kraju wraz z liczb� os�b zaszczepionych z podzia�em na dni

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
	dea.location = vac.location and dea.date = vac.date				-- ��czenie tabel po kolumnach lokacja oraz data
WHERE
	dea.continent is not null
ORDER BY 
	dea.continent, dea.location;



-- Wzrastaj�ca z kolejnymi dniami liczba zaszczepionych z podzia�em na kraje, kontynenty 

SELECT dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, CONVERT(datetime, dea.date)) AS RollingPeopleVaccinated
-- sumowanie liczby zaszczepionych os�b ka�dego dnia z sortowaniem na kraje oraz dat�
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



-- u�ycie CTE (common table expression - wsp�lne wyra�enie tablicowe) aby obliczy� procent z stworzonej nowej zmiennej
-- klauzura WITH dzia�a podobnie jak prefix SELECT
-- Sumowanie liczby zaszczepionych oraz procent os�b zaszczepionych (do danego dnia) w por�wnaniu do ca�kowitej populacji kraju

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
-- Klauzura WITH nie obs�uguje ORDER BY
)
SELECT *, 
	(RollingPeopleVaccinated/population)*100 AS PercentageVaccinatedPeople
FROM PopVsVac
ORDER BY 
	PopVsVac.location, PopVsVac.date;



-- Tworzenie tabeli tymczasowej - Temporary Table

DROP TABLE IF exists #PercentPopulationVaccinated			-- Zabezpieczenie przed b��dem 
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



-- Tworzenie widoku danych do p�niejszych dzia�a� 

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



-- Wy�wietlenie danych z stworzonego widoku

SELECT *
FROM PercentPopulationVaccinated
ORDER BY 
	location, date;
