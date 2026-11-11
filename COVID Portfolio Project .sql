CREATE DATABASE PortffolioProject;
USE PortffolioProject;



USE portffolioproject;

-- Шаг 1. Создаем таблицу со всеми колонками из вашего файла
CREATE TABLE IF NOT EXISTS CovidDeath_s (
    iso_code VARCHAR(20),
    continent VARCHAR(50),
    location VARCHAR(100),
    date VARCHAR(30),
    population FLOAT,
    total_cases FLOAT,
    new_cases FLOAT,
    new_cases_smoothed FLOAT,
    total_deaths FLOAT,
    new_deaths FLOAT,
    new_deaths_smoothed FLOAT,
    total_cases_per_million FLOAT,
    new_cases_per_million FLOAT,
    new_cases_smoothed_per_million FLOAT,
    total_deaths_per_million FLOAT,
    new_deaths_per_million FLOAT,
    new_deaths_smoothed_per_million FLOAT,
    reproduction_rate FLOAT,
    icu_patients FLOAT,
    icu_patients_per_million FLOAT,
    hosp_patients FLOAT,
    hosp_patients_per_million FLOAT,
    weekly_icu_admissions FLOAT,
    weekly_icu_admissions_per_million FLOAT,
    weekly_hosp_admissions FLOAT,
    weekly_hosp_admissions_per_million FLOAT
);

-- Шаг 2. Разрешаем локальную загрузку
SET GLOBAL local_infile = 1;

-- Шаг 3. Загружаем данные из CSV
LOAD DATA LOCAL INFILE '/Users/apple/Desktop/project sql/CovidDeath_s.csv' 
INTO TABLE CovidDeath_s 
CHARACTER SET utf8mb4 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS;

USE portffolioproject;

-- Шаг 1. Создаем таблицу для данных о вакцинации и тестах
CREATE TABLE IF NOT EXISTS CovidVaccination_s (
    iso_code VARCHAR(20),
    continent VARCHAR(50),
    location VARCHAR(100),
    date VARCHAR(30),
    new_tests FLOAT,
    total_tests FLOAT,
    total_tests_per_thousand FLOAT,
    new_tests_per_thousand FLOAT,
    new_tests_smoothed FLOAT,
    new_tests_smoothed_per_thousand FLOAT,
    positive_rate FLOAT,
    tests_per_case FLOAT,
    tests_units VARCHAR(50),
    total_vaccinations FLOAT,
    people_vaccinated FLOAT,
    people_fully_vaccinated FLOAT,
    new_vaccinations FLOAT,
    new_vaccinations_smoothed FLOAT,
    total_vaccinations_per_hundred FLOAT,
    people_vaccinated_per_hundred FLOAT,
    people_fully_vaccinated_per_hundred FLOAT,
    new_vaccinations_smoothed_per_million FLOAT,
    stringency_index FLOAT,
    population_density FLOAT,
    median_age FLOAT,
    aged_65_older FLOAT,
    aged_70_older FLOAT,
    gdp_per_capita FLOAT,
    extreme_poverty FLOAT,
    cardiovasc_death_rate FLOAT,
    diabetes_prevalence FLOAT,
    female_smokers FLOAT,
    male_smokers FLOAT,
    handwashing_facilities FLOAT,
    hospital_beds_per_thousand FLOAT,
    life_expectancy FLOAT,
    human_development_index FLOAT
);

-- Шаг 2. Разрешаем локальную загрузку (если еще не включена)
SET GLOBAL local_infile = 1;

-- Шаг 3. Загружаем данные из CSV-файла
LOAD DATA LOCAL INFILE '/Users/apple/Desktop/project sql/CovidVaccinations_.csv' 
INTO TABLE CovidVaccination_s 
CHARACTER SET utf8mb4 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS;

SELECT *
  FROM CovidDeath_s
 ORDER BY 3, 4;
 
 SELECT *
 FROM CovidVaccination_s
 ORDER BY 3, 4;
 
-- Выбираем данные, с которых мы начнем
SELECT location, date, total_cases, new_cases, total_deaths, population
  FROM CovidDeath_s
 ORDER BY 1, 2;

-- Общее число случаев заболевания против общего числа смертей
-- Показывает вероятность смерти в случае заражения COVID - 19 в вашей стране
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS DeathPercentage
  FROM CovidDeath_s
 WHERE location LIKE '%kaz%'
 ORDER BY 1, 2;
 
-- Всего случаев против численности населения
-- Показывает, какой процент населения заразился COVID-19
SELECT location, date, population, total_cases, (total_cases/population) * 100 AS PercentPopulationInfected
  FROM CovidDeath_s
 WHERE location LIKE '%kaz%'
 ORDER BY 1, 2;
 
-- Страны с наивысшим уровнем инфицирования по отношению к населению
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)) 		* 100 AS PercentPopulationInfected
  FROM CovidDeath_s
 -- WHERE location LIKE '%kaz%'
 GROUP BY location, population
 ORDER BY PercentPopulationInfected DESC;
 
 
-- Страны с наибольшим количеством смертей на душу населения
SELECT location, MAX(CAST(Total_deaths AS SIGNED)) AS TotalDeathCount
  FROM CovidDeath_s
 -- WHERE location LIKE '%kaz%'
 WHERE continent IS NOT NULL
 GROUP BY location
 ORDER BY TotalDeathCount DESC;
 
 -- Разбивка данных по континентам
SELECT continent, MAX(CAST(Total_deaths AS SIGNED)) AS TotalDeathCount
  FROM CovidDeath_s
 WHERE continent IS NOT NULL 
 GROUP BY continent
 ORDER BY TotalDeathCount DESC;
 
-- ГЛОБАЛЬНЫЕ ПОКАЗАТЕЛИ
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths as SIGNED)) as total_deaths,
       SUM(cast(new_deaths as SIGNED))/SUM(New_Cases)*100 AS DeathPercentage
  FROM CovidDeath_s
-- WHERE location like '%states%'
  WHERE continent IS NOT NULL 
-- GROUP BY date
  ORDER BY 1,2;
  
  
-- Общая численность населения против вакцинаций
-- Показывает процент населения, получившего хотя бы одну дозу вакцины от COVID-19
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (PARTITION BY dea.location 
	   ORDER BY dea.location, dea.date) AS RollingPeopleVaccinations
  FROM CovidDeath_s AS dea
 INNER JOIN CovidVaccination_s AS vac
    ON dea.location = vac.location
   AND dea.date = vac.date
 WHERE dea.continent IS NOT NULL
   -- AND dea.location LIKE '%KAZ%'
 ORDER BY 1, 2, 3;

-- Использование CTE для выполнения вычислений с помощью PARTITION BY в предыдущем запросе
WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinations) 
AS
 (
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (PARTITION BY dea.location 
	   ORDER BY dea.location, dea.date) AS RollingPeopleVaccinations
  FROM CovidDeath_s AS dea
 INNER JOIN CovidVaccination_s AS vac
    ON dea.location = vac.location
   AND dea.date = vac.date
 WHERE dea.continent IS NOT NULL
   -- AND dea.location LIKE '%KAZ%'
--  ORDER BY 1, 2, 3
 )
SELECT *, (RollingPeopleVaccinations/population) * 100
  FROM PopvsVac;
  
-- Использование временной таблицы для выполнения вычислений с помощью PARTITION BY
DROP TEMPORARY TABLE IF EXISTS PercentPopulationVaccinated;

CREATE TEMPORARY TABLE PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeath_s dea
JOIN CovidVaccination_s vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT *, (RollingPeopleVaccinated / Population) * 100 AS PercentPopulationVaccinated
FROM PercentPopulationVaccinated;

-- Создание представления для хранения данных для последующих визуализаций
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/population)*100
FROM CovidDeath_s dea
JOIN CovidVaccination_s vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;






