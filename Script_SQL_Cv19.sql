-- Select Data that we are going to be starting with

SELECT 
    Location 
    ,date
    ,total_cases
    ,new_cases
    ,total_deaths 
    ,population
FROM CovidDeaths
ORDER BY 1,2

-- Percentage of deaths compared to the number of cases
-- Observations : From November 7, 2020 the percentage of deaths compared to the number of cases stabilizes at around 2%. It remains within the world average which is also 2.2%.

SELECT 
    Location
    ,date 
    ,total_cases
    ,new_cases
    ,total_deaths
    ,round((total_deaths/total_cases)*100,1) as deaths_percentage
FROM CovidDeaths
WHERE Location like 'France'
ORDER BY 1,2


-- Percentage of population infected with Covid
-- Observations : The percentage of covid infected in France exceeds the 5% mark on February 9, 2021. From this date this percentage increases almost twice as fast.

SELECT 
    Location 
    ,date 
    ,population
    ,total_cases
    ,ROUND((CAST(total_cases AS FLOAT) / CAST(population AS FLOAT)) * 100, 3) AS infected_population_percentage
FROM CovidDeaths
WHERE Location like '%france'
ORDER BY 1,2

-- Countries with Highest Infection Rate compared to Population
-- Observations : As of April 30, 2021, Andorra is the country with the highest rate of infected people compared to the number of population of the country with 17% of people infected. France is positioned in 17th place (8.3%)

SELECT 
    Location
    ,population
    ,MAX(total_cases) as total_infection_count
    ,MAX((ROUND(CAST(total_cases AS FLOAT) / CAST(population AS FLOAT) * 100, 2))) AS infected_population_percentage
FROM CovidDeaths
GROUP BY Location, population
ORDER BY infected_population_percentage desc 


-- Countries with highest death count in Europe
-- Observations : As of April 30, 2021, the United Kingdom is the country with the highest number of deaths with 127,775 deaths. France is 4th (104,675)

SELECT 
    Location
    ,population
    ,MAX(total_deaths) as total_deaths_count
FROM CovidDeaths
WHERE 
    continent is not null
    AND continent = 'Europe'
GROUP BY Location, population
ORDER BY total_deaths_count desc 


-- Contintents with the highest death count
-- Observations : Europe has the most deaths from covid as of April 30, 2021 with 1,016,750 deaths. This is 2 times more than Asia which has 520,286 deaths

SELECT 
    continent
    ,SUM(total_deaths_count) as total_deaths_count
FROM (
    SELECT 
        location
        ,continent
        ,MAX(total_deaths) as total_deaths_count
    FROM CovidDeaths
    WHERE continent is not null 
    GROUP BY location, continent
) as continent_deaths
GROUP BY continent
ORDER BY total_deaths_count desc


-- Global KPIs
-- Observations : As of April 30, 2021, for 150,574,977 cases of covid identified there are 3,180,206 deaths in the world which gives us a rate of 2.11% of deaths compared to the number of people infected knowing that less than 1% of the world population is infected with covid at this time.

SELECT 
    SUM(population) as total_population
    ,SUM(new_cases) as total_cases
    ,SUM(cast(new_deaths as int)) as total_deaths
    ,ROUND(SUM(CAST(total_cases AS FLOAT)) / SUM(CAST(population AS FLOAT)) * 100, 2) AS infected_population_percentage
    ,ROUND(SUM(new_deaths)/SUM(New_Cases)*100, 2) as death_percentage
From CovidDeaths
where continent is not null 
--Group By date
order by 1,2


-- Percentage of population that has recieved at least one covid vaccine in France
-- The first people vaccinated in France is on December 28, 2020. At the beginning only a hundred people were vaccinated but from January 6, 2021, the number of vaccines exploded, exceeding 10,000 vaccines per day

SELECT 
    dea.continent 
    ,dea.location 
    ,dea.date
    ,dea.population 
    ,vac.new_vaccinations
    ,SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as rolling_people_vaccinated
FROM PortfolioProject..CovidDeaths dea
    LEFT JOIN PortfolioProject..CovidVaccinations vac on dea.location = vac.location and dea.date = vac.date
WHERE 
    dea.continent is not null 
    AND dea.location = 'France'
ORDER BY 2,3


-- Percentage of people vaccinated in France day after day
-- On April 30, 2021, 30% of french population was vaccinated knowing that not even 0.01% of French people were vaccinated at the very beginning of the year

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) as (
    SELECT 
        dea.continent 
        ,dea.location 
        ,dea.date
        ,dea.population 
        ,vac.new_vaccinations
        ,SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as rolling_people_vaccinated
    FROM PortfolioProject..CovidDeaths dea
        LEFT JOIN PortfolioProject..CovidVaccinations vac on dea.location = vac.location and dea.date = vac.date
    WHERE 
        dea.continent is not null 
        AND dea.location = 'France'
)

SELECT * , ROUND((CAST(RollingPeopleVaccinated as FLOAT)/Population)*100, 2) vaccinated_population_percentage
FROM PopvsVac


-- Storing results in an intermediate table

DROP TABLE IF EXISTS PercentPopulationVaccinated
CREATE TABLE PercentPopulationVaccinated (
    Continent nvarchar(255),
    Location nvarchar(255),
    Date datetime,
    Population numeric,
    New_vaccinations numeric,
    RollingPeopleVaccinated numeric
)

INSERT INTO PercentPopulationVaccinated 
    SELECT 
        dea.continent 
        ,dea.location 
        ,dea.date
        ,dea.population 
        ,vac.new_vaccinations
        ,SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as rolling_people_vaccinated
    FROM PortfolioProject..CovidDeaths dea
        LEFT JOIN PortfolioProject..CovidVaccinations vac on dea.location = vac.location and dea.date = vac.date
    WHERE 
        dea.continent is not null 
        AND dea.location = 'France'
ORDER BY 2,3



SELECT * , ROUND((CAST(RollingPeopleVaccinated as FLOAT)/Population)*100, 2) vaccinated_population_percentage
From PercentPopulationVaccinated






