SELECT 
    Location 
    ,date
    ,total_cases
    ,new_cases
    ,total_deaths 
    ,population
FROM CovidDeaths
ORDER BY 1,2

-- Pourcentage de décès
-- Observations : À partir du 7 novembre 2020, le pourcentage de décès par rapport au nombre de cas se stabilise autour de 2 %. Il reste proche de la moyenne mondiale qui est également de 2,2 %.

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


-- Pourcentage de la population infectée par le Covid
-- Observations : Le pourcentage de personnes infectées en France dépasse le seuil des 5 % le 9 février 2021. À partir de cette date, cette proportion augmente presque deux fois plus rapidement.

SELECT 
    Location 
    ,date 
    ,population
    ,total_cases
    ,ROUND((CAST(total_cases AS FLOAT) / CAST(population AS FLOAT)) * 100, 3) AS infected_population_percentage
FROM CovidDeaths
WHERE Location like '%france'
ORDER BY 1,2

-- Pays avec le taux d'infection le plus élevé par rapport à la population
-- Observations : Au 30 avril 2021, Andorre est le pays présentant le taux le plus élevé de population infectée avec 17 %. La France se situe en 17e position avec 8,3 %.

SELECT 
    Location
    ,population
    ,MAX(total_cases) as total_infection_count
    ,MAX((ROUND(CAST(total_cases AS FLOAT) / CAST(population AS FLOAT) * 100, 2))) AS infected_population_percentage
FROM CovidDeaths
GROUP BY Location, population
ORDER BY infected_population_percentage desc 


-- Pays avec le plus grand nombre de décès en Europe
-- Observations : Au 30 avril 2021, le Royaume-Uni est le pays ayant enregistré le plus grand nombre de décès avec 127 775 décès. La France se classe en 4e position avec 104 675 décès.

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


-- Continents avec le plus grand nombre de décès
-- Observations : L’Europe est le continent ayant enregistré le plus grand nombre de décès liés au Covid au 30 avril 2021 avec 1 016 750 décès. Ce chiffre est environ deux fois supérieur à celui de l’Asie qui compte 520 286 décès.

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


-- Indicateurs globaux (KPIs)
-- Observations : Au 30 avril 2021, pour 150 574 977 cas de Covid identifiés, on compte 3 180 206 décès dans le monde, soit un taux de décès de 2,11 % par rapport au nombre de personnes infectées, alors que moins de 1 % de la population mondiale est infectée à cette date.

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


-- Pourcentage de la population ayant reçu au moins une dose de vaccin contre le Covid en France
-- Les premières vaccinations en France ont eu lieu le 28 décembre 2020. Au début, seulement une centaine de personnes étaient vaccinées, mais à partir du 6 janvier 2021, le nombre de vaccinations a fortement augmenté, dépassant les 10 000 injections par jour.

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


-- Évolution du pourcentage de personnes vaccinées en France jour après jour
-- Au 30 avril 2021, 30 % de la population française était vaccinée, alors qu’au tout début de l’année, moins de 0,01 % de la population avait reçu une dose.

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


-- Stockage des résultats dans une table intermédiaire

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
