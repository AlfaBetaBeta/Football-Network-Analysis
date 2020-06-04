# [I]    PREPROCESSING ####

# Remove all existing objects from the current environment
rm(list = ls())

# Install (if necessary) and load required packages
install_packages_if_not_present <- function(x) {
    if (sum(!x %in% installed.packages())) {
        install.packages(x[!x %in% installed.packages()])
    }
}

packages <- c("igraph","visNetwork","dplyr","igraphdata","scales")
install_packages_if_not_present(packages)

sapply(packages, require, character.only = TRUE)

# Load source csv file into a data.frame representing network edges
matches <- read.csv("./team_data.csv", stringsAsFactors = FALSE, encoding = "latin1")

# Filter columns of interest
cols_to_remove <- c("away_team_api_id",
                   "team_fifa_api_id.x",
                   "home_team_api_id",
                   "team_fifa_api_id.y",
                   "country_id",
                   "id.x.1",
                   "league_id",
                   "match_api_id",
                   "id.y.1",
                   "name.y")
matches[,cols_to_remove] <- list(NULL)

# Rename columns conveniently
names(matches)[names(matches) == 'id.x'] <- 'id.visit_team'
names(matches)[names(matches) == 'id.y'] <- 'id.home_team'

names(matches)[names(matches) == 'team_long_name.x'] <- 'team_long_name.visit'
names(matches)[names(matches) == 'team_long_name.y'] <- 'team_long_name.home'

names(matches)[names(matches) == 'team_short_name.x'] <- 'team_short_name.visit'
names(matches)[names(matches) == 'team_short_name.y'] <- 'team_short_name.home'

names(matches)[names(matches) == 'X'] <- 'match.id'
names(matches)[names(matches) == 'name.x'] <- 'national_league'

# Cast date column from character to date
matches$date <- as.Date(matches$date)

# [II]   IMPORT FUNCTIONS and SPLIT PER COUNTRY ####

# Import user defined supporting functions
source("./Supporting_functions.R")

# Split the overall dataframe into a list of dataframes per country
matches_by_country <- split_by_country(matches)


# [III]  EXAMPLE with QUERIES ####

# Illustratively, let us focus on the Spanish league in season 2012/2013

# Subset the list of dataframes by selecting Spain
matches_Spain_by_season <- split_by_season(matches_by_country[["Spain"]])

# Subset the resulting list of dataframes by selecting season 2012/2013
matches_Spain_2012.13 <- matches_Spain_by_season[["2012/2013"]]
# Add the goal difference column and cast the team names column to factor
matches_Spain_2012.13 <- add_goalDiff_col(matches_Spain_2012.13)
matches_Spain_2012.13 <- team_names_to_factors(matches_Spain_2012.13)

# Create igraph <g> from this dataframe, considering the visiting team and the home team as edge delimiters
edges <- matches_Spain_2012.13[ , c("team_long_name.visit", "team_long_name.home")]
colnames(edges) <- c("from", "to")
g <- graph_from_data_frame(edges, directed = TRUE)
# The graph is directed, always from the visiting team vertex to the home team vertex!

# Inspect vertices and edges
V(g)
E(g)

# Count edges and vertices (must coincide with 380 matches in a league of 20 teams)
gsize(g)
gorder(g)

# Add edge attributes
# (home team goals/visiting team goals/by default the goal difference is assigned as weight)
g <- set_Eg_attributes(g, matches_Spain_2012.13)
edge_attr_names(g)
edge_attr(g)

# Add and display vertex attributes
# (goal difference as local team/goal difference as visiting team/total goal difference)
g <- set_Vg_attributes(g)
# (ranking and points at the end of the season)
g <- infer_Vg_ranking_points(g)
vertex_attr(g)

# Inspect some of the vertices
V(g)[[1:5]]
V(g)[["FC Barcelona"]]


# SUBSETTING EXAMPLES

# Find matches with teams that scored more than 4 goals as visitor
E(g)[[away_team_goal > 4]]

# Find matches where the score was a tie
E(g)[[home_team_goal == away_team_goal]]

# Show all the matches where the champion (Barcelona) played as local
show_matches_as_local(g, 1)
# How many matches did the champion (Barcelona) tie as local?
count_scoreTags_as_local(g, 1)
count_scoreTags_as_local(g, 1)["ties"]
# Against who?
show_local_ties(g, 1)

# Show all the matches that the champion (Barcelona) played as visitor
show_matches_as_visitor(g, 1)
# How many matches did the the champion (Barcelona) lose as visitor?
count_scoreTags_as_visitor(g, 1)
count_scoreTags_as_visitor(g, 1)["defeats"]
# Against who?
show_visitor_defeats(g, 1)

# Show all the matches that the 3rd ranked team (Atlético) played as visitor
show_matches_as_visitor(g, 3)
# How many matches did the 3rd ranked (Atlético) lose as visitor?
count_scoreTags_as_visitor(g, 3)
count_scoreTags_as_visitor(g, 3)["defeats"]
# Against who?
show_visitor_defeats(g, 3)

# PLOT iGRAPH
pseudo_IN_strength <- ifelse(strength(g, vids = V(g), mode = c("in")) > 0, 1, 0)
pseudo_OUT_strength <- ifelse(strength(g, vids = V(g), mode = c("out")) < 0, 1, 0)
# Note that the IN-strength minus the OUT-strength of a vertex corresponds to its total goal difference!
# The goal difference is encoded as vertex colour blue if positive, red if negative and white otherwise
pseudo_strength <- ifelse(strength(g, vids = V(g), mode = c("in")) - strength(g, vids = V(g), mode = c("out")) > 0, "blue",
                          ifelse(strength(g, vids = V(g), mode = c("in")) - strength(g, vids = V(g), mode = c("out")) < 0,
                                 "red", "white"))

# The edge weight (home goals minus visitor goals in a match) is encoded as blue if positive, red if negative and
# light grey otherwise
pseudo_weight <- ifelse(E(g)$weight > 0, "blue", ifelse(E(g)$weight < 0, "red", "light grey"))

V(g)$color <- pseudo_strength
E(g)$color <- pseudo_weight
E(g)$label <- NA

# Save the graph plot locally (in the working directory) as a png file, with circular layout and ordered by ranking
save_g_as_circle(g, "matches Spain example 2012-13", order(V(g)$ranking), "goalDiff", width = 1500, height = 1500)


# [IV]   MODELLING OF SPANISH LEAGUE ALL SEASONS ####

# In the Spanish league, model with graphs the entire set of seasons programmatically
# The time span under consideration:
seasons = c("2008/2009", "2009/2010", "2010/2011", "2011/2012", "2012/2013", "2013/2014", "2014/2015", "2015/2016")

# Subset the list of dataframes by selecting Spain
matches_Spain_by_season <- split_by_season(matches_by_country[["Spain"]])

# Generate a fully attributed graph per season and store them into a list
g_listES <- get_g_N_seasons(matches_Spain_by_season, seasons)

# Save all season graph plots as a single png file in the working directory
save_N_seasons_as_circles(seasons = g_listES, country = "Spain", size_by = "goalDiff",
                          rows = 2, cols = 4, width = 6000, height = 3000, marg = 4)


# As a further analysis, let us consider all 8 seasons agglomeratively (3040 matches in a single dataframe)
matches_Spain <- matches[matches$national_league == "Spain",]
matches_Spain <- add_goalDiff_col(matches_Spain)
matches_Spain <- team_names_to_factors(matches_Spain)

# Create a single graph from the agglomerative dataframe
g_agg <- g_from_country_season(matches_Spain)

# Assign all attributes to the graph (including weights)
g_agg <- set_g_attributes(g_agg, matches_Spain, w = T)

# Save the graph plot as a png file in the working directory
png("Spain 2008-2016.png", width = 2000, height = 1500)
lab.locs <- radian.rescale(1:length(V(g_agg)), start = 0, direction = -1)[order(as.numeric(V(g_agg)[order(V(g_agg)$ranking)]))]
par(mar = c(3, 5, 3, 5))
plot(g_agg,
     layout =layout.circle(g_agg, order = order(V(g_agg)$ranking)),
     vertex.size = (V(g_agg)$end.points)/(max(V(g_agg)$end.points)) * 10,
     vertex.label.cex = 1.5,
     vertex.label.font = 2,
     vertex.label.color = "black",
     vertex.color = adjustcolor(V(g_agg)$color, alpha.f = .7),
     vertex.label.dist = 1.9,
     vertex.label.degree = lab.locs,
     edge.width = abs(E(g_agg)$weight),
     edge.arrow.size = 0.5,
     edge.curved = 0.1,
     edge.color = adjustcolor(E(g_agg)$color, alpha.f = .3))
dev.off()

# To assess the metrics of the agglomerative graph, it is convenient to create an unweighted graph from the
# agglomerative dataframe
g_agg_uw <- g_from_country_season(matches_Spain)
g_agg_uw <- set_g_attributes(g_agg_uw, matches_Spain, w = F)

# Show the number of teams that have played the Spanish league throughout the 8 seasons (it is greater than 20
# because of the teams that lose category or promote at the end of each season)
gorder(g_agg_uw)

# Calculate degree and display degree distribution
out.degree <- degree(g_agg_uw, mode = c("out"))
# The IN-degree is identical by symmetry

table(degree(g_agg_uw, mode = c("all")))
# 38x8 = 304, only 9 teams have played over the entire 8 season timespan
# Show the same distribution by the number of seasons each team was in 1st division
table(degree(g_agg_uw, mode = c("all")) / 38)
# Barplot of the degree distribution
barplot(table(degree(g_agg_uw, mode = c("all"))), main = "Degree distribution over 8 years",
        xlab = "degree", ylab = "number of teams")

# Store the names of the teams that have been in the Spanish 1st division throughout
teams.allseasons <- names(out.degree)[out.degree == max(out.degree)]
# Store the names of the teams that have been in the Spanish 1st division for only one season
teams.oneseason <- names(out.degree)[out.degree == min(out.degree)]

# Calculate betweenness centrality
betweenness(g_agg_uw)

# Calculate largest path
farthest_vertices(g_agg_uw)
get_diameter(g_agg_uw)
# Average path length
mean_distance(g_agg_uw, directed = T)

# Eigenvector centrality
g_agg_uw.ec <- eigen_centrality(g_agg_uw)$vector
g_agg_uw.ec[teams.allseasons]
g_agg_uw.ec[teams.oneseason]

# Transitivity (global clustering)
transitivity(g_agg_uw, typ = "global")

# Assortativity (high degree not preferably conected with low degree)
assortativity.degree(g_agg_uw, directed = T)

# edge.betweenness.community
ed.m <- cluster_edge_betweenness(g_agg_uw)
ed.m
membership(ed.m)[order(membership(ed.m))]
table(membership(ed.m))


# [V]    MODELLING OF ENGLISH PREMIER LEAGUE ALL SEASONS ####

# In the English league, model with graphs the entire set of seasons programmatically
# The time span under consideration:
seasons = c("2008/2009", "2009/2010", "2010/2011", "2011/2012", "2012/2013", "2013/2014", "2014/2015", "2015/2016")

# Subset the list of dataframes by selecting England
matches_England_by_season <- split_by_season(matches_by_country[["England"]])

# Generate a fully attributed graph per season and store them into a list
g_listEN <- get_g_N_seasons(matches_England_by_season, seasons, country = "England")

# Save all season graph plots as a single png file in the working directory
save_N_seasons_as_circles(seasons = g_listEN, country = "England", size_by = "goalDiff",
                          rows = 2, cols = 4, width = 6000, height = 3000, marg = 4)


# [VI]   MODELLING OF FRENCH LEAGUE ALL SEASONS ####

# In the French league, model with graphs the entire set of seasons programmatically
# The time span under consideration:
seasons = c("2008/2009", "2009/2010", "2010/2011", "2011/2012", "2012/2013", "2013/2014", "2014/2015", "2015/2016")

# Subset the list of dataframes by selecting France
matches_France_by_season <- split_by_season(matches_by_country[["France"]])

# Generate a fully attributed graph per season and store them into a list
g_listFR <- get_g_N_seasons(matches_France_by_season, seasons, country = "France")

# Save all season graph plots as a single png file in the working directory
save_N_seasons_as_circles(seasons = g_listFR, country = "France", size_by = "goalDiff",
                          rows = 2, cols = 4, width = 6000, height = 3000, marg = 4)


# [VII]  MODELLING OF GERMAN LEAGUE ALL SEASONS ####

# In the German league, model with graphs the entire set of seasons programmatically
# The time span under consideration:
seasons = c("2008/2009", "2009/2010", "2010/2011", "2011/2012", "2012/2013", "2013/2014", "2014/2015", "2015/2016")

# Subset the list of dataframes by selecting Germany
matches_Germany_by_season <- split_by_season(matches_by_country[["Germany"]])

# Generate a fully attributed graph per season and store them into a list
g_listDE <- get_g_N_seasons(matches_Germany_by_season, seasons, country = "Germany")

# Save all season graph plots as a single png file in the working directory
save_N_seasons_as_circles(seasons = g_listDE, country = "Germany", size_by = "goalDiff",
                          rows = 2, cols = 4, width = 6000, height = 3000, marg = 4)


# [VIII] MODELLING OF ITALIAN LEAGUE ALL SEASONS ####

# In the Italian league, model with graphs the entire set of seasons programmatically
# The time span under consideration:
seasons = c("2008/2009", "2009/2010", "2010/2011", "2011/2012", "2012/2013", "2013/2014", "2014/2015", "2015/2016")

# Subset the list of dataframes by selecting Italy
matches_Italy_by_season <- split_by_season(matches_by_country[["Italy"]])

# Generate a fully attributed graph per season and store them into a list
g_listIT <- get_g_N_seasons(matches_Italy_by_season, seasons, country = "Italy")

# Save all season graph plots as a single png file in the working directory
save_N_seasons_as_circles(seasons = g_listIT, country = "Italy", size_by = "goalDiff",
                          rows = 2, cols = 4, width = 6000, height = 3000, marg = 4)


# [IX]   MODELLING OF DUTCH LEAGUE ALL SEASONS ####

# In the Dutch league, model with graphs the entire set of seasons programmatically
# The time span under consideration:
seasons = c("2008/2009", "2009/2010", "2010/2011", "2011/2012", "2012/2013", "2013/2014", "2014/2015", "2015/2016")

# Subset the list of dataframes by selecting Netherlands
matches_Netherlands_by_season <- split_by_season(matches_by_country[["Netherlands"]])

# Generate a fully attributed graph per season and store them into a list
g_listNE <- get_g_N_seasons(matches_Netherlands_by_season, seasons, country = "Netherlands")

# Save all season graph plots as a single png file in the working directory
save_N_seasons_as_circles(seasons = g_listNE, country = "Netherlands", size_by = "goalDiff",
                          rows = 2, cols = 4, width = 6000, height = 3000, marg = 4)


# [X]    MODELLING OF PORTUGUESE LEAGUE ALL SEASONS ####

# In the Portuguese league, model with graphs the entire set of seasons programmatically
# The time span under consideration:
seasons = c("2008/2009", "2009/2010", "2010/2011", "2011/2012", "2012/2013", "2013/2014", "2014/2015", "2015/2016")

# Subset the list of dataframes by selecting Portugal
matches_Portugal_by_season <- split_by_season(matches_by_country[["Portugal"]])

# Generate a fully attributed graph per season and store them into a list
g_listPT <- get_g_N_seasons(matches_Portugal_by_season, seasons, country = "Portugal")

# Save all season graph plots as a single png file in the working directory
save_N_seasons_as_circles(seasons = g_listPT, country = "Portugal", size_by = "goalDiff",
                          rows = 2, cols = 4, width = 6000, height = 3000, marg = 4)


# [XI]   MODELLING OF SWISS LEAGUE ALL SEASONS ####

# In the Swiss league, model with graphs the entire set of seasons programmatically
# The time span under consideration:
seasons = c("2008/2009", "2009/2010", "2010/2011", "2011/2012", "2012/2013", "2013/2014", "2014/2015", "2015/2016")

# Subset the list of dataframes by selecting Switzerland
matches_Switzerland_by_season <- split_by_season(matches_by_country[["Switzerland"]])

# Generate a fully attributed graph per season and store them into a list
g_listSW <- get_g_N_seasons(matches_Switzerland_by_season, seasons, country = "Switzerland")

# Save all season graph plots as a single png file in the working directory
save_N_seasons_as_circles(seasons = g_listSW, country = "Switzerland", size_by = "goalDiff",
                          rows = 2, cols = 4, width = 6000, height = 3000, marg = 4)


# [XII]  STUDY OF NATIONAL CHAMPIONS ####

# Let us inspect the Spanish champion of season 2013/2014, the only time within <seasons> with a winning team
# other than the usual tuple (Barcelona, Real Madrid)
summary_team(g = g_listES[[6]], season = "2013/2014", rkg = 1)

# As reference for that season, visually display the strength distribution for all teams (IN and OUT separately)
get_strength_distribution(g_listES[[6]], "in")
get_strength_distribution(g_listES[[6]], "out")

# As comparison with the Spanish champions of other seasons, calculate and plot the goal difference indices
# for all season champions
ind.championES <- get_all_champion_indices(g_listES)
plot_champion_indices(ind.championES, "Spanish league champions")


# Compare the goal difference indices with other European champions
ind.championEN <- get_all_champion_indices(g_listEN)
plot_champion_indices(ind.championEN, "English league champions")

ind.championFR <- get_all_champion_indices(g_listFR)
plot_champion_indices(ind.championFR, "French league champions")

ind.championDE <- get_all_champion_indices(g_listDE)
plot_champion_indices(ind.championDE, "German league champions")

ind.championIT <- get_all_champion_indices(g_listIT)
plot_champion_indices(ind.championIT, "Italian league champions")

ind.championNE <- get_all_champion_indices(g_listNE)
plot_champion_indices(ind.championNE, "Dutch league champions")

ind.championPT <- get_all_champion_indices(g_listPT)
plot_champion_indices(ind.championPT, "Portuguese league champions")

ind.championSW <- get_all_champion_indices(g_listSW)
plot_champion_indices(ind.championSW, "Swiss league champions")

# Save all goal difference indices' barplots as a single png file in the working directory
png("Goal difference indices European champions.png", width = 6000, height = 3000)
par(mfrow = c(2, 4), cex = 5)
plot_champion_indices(ind.championES, "Spanish league champions")
plot_champion_indices(ind.championEN, "English league champions")
plot_champion_indices(ind.championFR, "French league champions")
plot_champion_indices(ind.championDE, "German league champions")
plot_champion_indices(ind.championIT, "Italian league champions")
plot_champion_indices(ind.championNE, "Dutch league champions")
plot_champion_indices(ind.championPT, "Portuguese league champions")
plot_champion_indices(ind.championSW, "Swiss league champions")
dev.off()

