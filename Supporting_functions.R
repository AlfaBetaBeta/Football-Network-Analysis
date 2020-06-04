split_by_country <- function (df) {
    x = list()
    for (country in unique(df$national_league)) {
        x[[country]] <- subset(df, national_league == country)
    }
    return(x)
}

split_by_season <- function (df) {
    x = list()
    for (s in unique(df$season)) {
        x[[s]] <- subset(df, season == s)
    }
    return(x)
}

add_goalDiff_col <- function(df) {
    df$goalDiff <- df$home_team_goal - df$away_team_goal
    return(df)
}

team_names_to_factors <- function (df) {
    cols_to_factor <- c("team_long_name.home", "team_long_name.visit",
                        "team_short_name.home", "team_short_name.visit")
    
    for (col in cols_to_factor) {
        df[[col]] <- factor(df[[col]])
    }
    return(df)
}

get_season_from_country <- function (mbs, season) {
    df <- mbs[[season]]
    df <- add_goalDiff_col(df)
    df <- team_names_to_factors(df)
    return(df)
}

g_from_country_season <- function(df) {
    edges <- df[ , c("team_long_name.visit", "team_long_name.home")]
    colnames(edges) <- c("from", "to")
    g <- graph_from_data_frame(edges, directed = TRUE)
    return(g)
}

set_Eg_attributes <- function (g, df, w = T) {
    g <- set_edge_attr(g, "away_team_goal", value = df$away_team_goal)
    g <- set_edge_attr(g, "home_team_goal", value = df$home_team_goal)
    if (w) {
        g <- set_edge_attr(g, "weight", value = df$goalDiff)
    } else {
        g <- set_edge_attr(g, "weight", value = 1)
    }
    return(g)
}

set_Vg_attributes <- function (g) {
    IN_strength <- strength(g, vids = V(g), mode = c("in"))
    OUT_strength <- strength(g, vids = V(g), mode = c("out"))
    
    g <- set_vertex_attr(g, "home_goalDiff", value = IN_strength)
    g <- set_vertex_attr(g, "away_goalDiff", value = OUT_strength)
    g <- set_vertex_attr(g, "total_goalDiff", value = IN_strength - OUT_strength)
    
    return(g)
}

infer_Vg_ranking_points <- function (g, victory = 3, tie = 1) {
    for (team_name in V(g)$name) {
        V(g)[team_name]$points.home <- length(which(E(g)[to(team_name)]$weight > 0)) * victory +
            length(which(E(g)[to(team_name)]$weight == 0)) * tie
        
        V(g)[team_name]$points.away <- length(which(E(g)[from(team_name)]$weight < 0)) * victory +
            length(which(E(g)[from(team_name)]$weight == 0)) * tie
        
        V(g)[team_name]$end.points <- V(g)[team_name]$points.home + V(g)[team_name]$points.away
    }
    V(g)$ranking <- rank(-V(g)$end.points, ties.method = "min")
    
    return(g)
}

set_g_attributes <- function(g, df, w = T) {
    g <- set_Eg_attributes(g, df, w)
    g <- set_Vg_attributes(g)
    g <- infer_Vg_ranking_points(g)
    
    pseudo_strength <- ifelse(strength(g, vids = V(g), mode = c("in")) -
                                  strength(g, vids = V(g), mode = c("out")) > 0,
                              "blue", ifelse(strength(g, vids = V(g), mode = c("in")) -
                                                 strength(g, vids = V(g), mode = c("out")) < 0,
                                             "red", "white"))
    pseudo_weight <- ifelse(E(g)$weight > 0,
                            "blue",
                            ifelse(E(g)$weight < 0,
                                   "red", "light grey"))
    V(g)$color <- pseudo_strength
    E(g)$color <- pseudo_weight
    E(g)$label <- NA
    return(g)
}

show_matches_as_local <- function (g, final_ranking) {
    local.vertex <- V(g)$name[V(g)$ranking == final_ranking][1]
    E(g)[[to(local.vertex)]]
}

show_matches_as_visitor <- function (g, final_ranking) {
    visiting.vertex <- V(g)$name[V(g)$ranking == final_ranking][1]
    E(g)[[from(visiting.vertex)]]
}

count_scoreTags_as_local <- function (g, final_ranking) {
    local.vertex <- V(g)$name[V(g)$ranking == final_ranking][1]
    x <- c(sum(E(g)[to(local.vertex)]$weight > 0),
           sum(E(g)[to(local.vertex)]$weight == 0),
           sum(E(g)[to(local.vertex)]$weight < 0))
    names(x) <- c("victories", "ties", "defeats")
    
    return(x)
}

count_scoreTags_as_visitor <- function (g, final_ranking) {
    visiting.vertex <- V(g)$name[V(g)$ranking == final_ranking][1]
    x <- c(sum(E(g)[from(visiting.vertex)]$weight < 0),
           sum(E(g)[from(visiting.vertex)]$weight == 0),
           sum(E(g)[from(visiting.vertex)]$weight > 0))
    names(x) <- c("victories", "ties", "defeats")
    
    return(x)
}

show_local_victories <- function (g, final_ranking) {
    local.vertex <- V(g)$name[V(g)$ranking == final_ranking][1]
    victory_indices <- which(E(g)[to(local.vertex)]$weight > 0)
    E(g)[to(local.vertex)][victory_indices]
}

show_visitor_victories <- function (g, final_ranking) {
    visiting.vertex <- V(g)$name[V(g)$ranking == final_ranking][1]
    victory_indices <- which(E(g)[from(visiting.vertex)]$weight < 0)
    E(g)[from(visiting.vertex)][victory_indices]
}

show_local_ties <- function (g, final_ranking) {
    local.vertex <- V(g)$name[V(g)$ranking == final_ranking][1]
    tie_indices <- which(E(g)[to(local.vertex)]$weight == 0)
    E(g)[to(local.vertex)][tie_indices]
}

show_visitor_ties <- function (g, final_ranking) {
    visiting.vertex <- V(g)$name[V(g)$ranking == final_ranking][1]
    tie_indices <- which(E(g)[from(visiting.vertex)]$weight == 0)
    E(g)[from(visiting.vertex)][tie_indices]
}

show_local_defeats <- function (g, final_ranking) {
    local.vertex <- V(g)$name[V(g)$ranking == final_ranking][1]
    defeat_indices <- which(E(g)[to(local.vertex)]$weight < 0)
    E(g)[to(local.vertex)][defeat_indices]
}

show_visitor_defeats <- function (g, final_ranking) {
    visiting.vertex <- V(g)$name[V(g)$ranking == final_ranking][1]
    defeat_indices <- which(E(g)[from(visiting.vertex)]$weight > 0)
    E(g)[from(visiting.vertex)][defeat_indices]
}

save_g_as_circle <- function (g, filename, order, size_by, width = 1500, height = 1500, marg = 3, line = 0) {
    png(paste0(as.character(filename)," by ", size_by,".png"),
        width = width, height = height)
    
    par(mar = c(3, 3, marg, 3))
    my_circle_layout <- layout.circle(g, order = order)
    if (size_by == "goalDiff") {
        v.size <- abs(V(g)$total_goalDiff)
    } else if (size_by == "endpoints") {
        v.size <- (V(g)$end.points)/(max(V(g)$end.points)) * 10
    } else if (size_by == "ranking") {
        v.size <- 1 + gorder(g) - V(g)$ranking
    } else {
        v.size <- 0
    }
    lab.locs <- radian.rescale(1:length(V(g)), start = 0, direction = -1)[order(as.numeric(V(g)[order(V(g)$ranking)]))]
    
    plot(g,
         layout = my_circle_layout,
         vertex.size = v.size,
         vertex.label.cex = 1.5,
         vertex.label.color = "black",
         vertex.color = adjustcolor(V(g)$color, alpha.f = .5),
         vertex.label.dist = 1.9,
         vertex.label.degree = lab.locs,
         edge.width = abs(E(g)$weight))
    title(gsub("matches", "", filename), cex.main = 3, line = line)
    dev.off()
}

save_N_seasons_as_circles <- function (seasons, country, size_by, rows, cols, width = 3000, height = 3000, marg = 0) {
    png(paste0("matches ", country, " ", length(seasons), " seasons by ", size_by,".png"),
        width = width, height = height)
    par(mfrow = c(rows, cols), oma = c(0, 0, marg, 0))
    
    for (j in 1:length(seasons)) {
        season_layout <- layout.circle(seasons[[j]], order = order(V(seasons[[j]])$ranking))
        
        if (size_by == "goalDiff") {
            v.size <- abs(V(seasons[[j]])$total_goalDiff)
        } else if (size_by == "endpoints") {
            v.size <- (V(seasons[[j]])$end.points)/(max(V(seasons[[j]])$end.points)) * 10
        } else if (size_by == "ranking") {
            v.size <- 1 + gorder(seasons[[j]]) - V(seasons[[j]])$ranking
        } else {
            v.size <- 0
        }
        plot(seasons[[j]],
             layout = season_layout,
             vertex.size = v.size,
             vertex.label = NA,
             vertex.color = adjustcolor(V(seasons[[j]])$color, alpha.f = .5),
             edge.width = abs(E(seasons[[j]])$weight))
        title(names(seasons)[j], cex.main = 6, line = -8)
        title(country, cex.main = 6, line = -3)
    }
    dev.off()
}

get_g_N_seasons <- function (matches_Xcountry_by_season, seasons, country = "Spain", w = T) {
    g_list <- list()
    for (season in seasons) {
        matches_Xcountry_season <- get_season_from_country(matches_Xcountry_by_season, season)
        g_list[[season]] <- g_from_country_season(matches_Xcountry_season)
        g_list[[season]] <- set_g_attributes(g_list[[season]], matches_Xcountry_season, w)
        
        save_g_as_circle(g_list[[season]], paste("matches", country, gsub("/","-", season), sep = " "),
                         order(V(g_list[[season]])$ranking), "goalDiff", marg = 1, line = -3)
        save_g_as_circle(g_list[[season]], paste("matches", country, gsub("/","-", season), sep = " "),
                         order(V(g_list[[season]])$ranking), "endpoints", marg = 9, line = 2)
    }
    return(g_list)
}

summary_team <- function (g, season, rkg) {
    cat(paste0("Team ranked ", rkg, " in season ", season, ":"), "\n")
    cat(V(g)$name[order(V(g)$ranking)][1], "\n")
    
    cat("\nSummary of games as local:\n")
    print(count_scoreTags_as_local(g, rkg))
    cat("Summary of games as visitor:\n")
    print(count_scoreTags_as_visitor(g, rkg))
    
    cat("\nSummary of points:\n")
    pnts <- c(V(g)$end.points[V(g)$ranking == rkg][1],
              V(g)$points.home[V(g)$ranking == rkg][1],
              V(g)$points.away[V(g)$ranking == rkg][1])
    names(pnts) <- c("total", "home", "away")
    print(pnts)
    
    vertex <- V(g)[V(g)$ranking == rkg][1]
    cat("\nSummary of goals scored:\n")
    home.scored <- strength(g, vids = vertex, mode = c("in"), weights = E(g)$home_team_goal)
    away.scored <- strength(g, vids = vertex, mode = c("out"), weights = E(g)$away_team_goal)
    total.scored <- home.scored + away.scored
    victory.scored <- strength(g, vids = vertex, mode = c("in"),
                               weights = ifelse(E(g)$weight > 0, E(g)$home_team_goal, 0)) +
                      strength(g, vids = vertex, mode = c("out"),
                               weights = ifelse(E(g)$weight < 0, E(g)$away_team_goal, 0))
    tie.scored <- strength(g, vids = vertex, mode = c("in"),
                           weights = ifelse(E(g)$weight == 0, E(g)$home_team_goal, 0)) +
                  strength(g, vids = vertex, mode = c("out"),
                           weights = ifelse(E(g)$weight == 0, E(g)$away_team_goal, 0))
    defeat.scored <- strength(g, vids = vertex, mode = c("in"),
                              weights = ifelse(E(g)$weight < 0, E(g)$home_team_goal, 0)) +
                     strength(g, vids = vertex, mode = c("out"),
                              weights = ifelse(E(g)$weight > 0, E(g)$away_team_goal, 0))
    goals.scored <- c(total.scored,
                      home.scored,
                      away.scored,
                      victory.scored,
                      tie.scored,
                      defeat.scored)
    names(goals.scored) <- c("total", "home", "away", "victory", "tie", "defeat")
    print(goals.scored)
    
    cat("\nSummary of goals received:\n")
    home.received <- strength(g, vids = vertex, mode = c("in"), weights = E(g)$away_team_goal)
    away.received <- strength(g, vids = vertex, mode = c("out"), weights = E(g)$home_team_goal)
    total.received <- home.received + away.received
    victory.received <- strength(g, vids = vertex, mode = c("in"),
                                 weights = ifelse(E(g)$weight > 0, E(g)$away_team_goal, 0)) +
                        strength(g, vids = vertex, mode = c("out"),
                                 weights = ifelse(E(g)$weight < 0, E(g)$home_team_goal, 0))
    tie.received <- strength(g, vids = vertex, mode = c("in"),
                             weights = ifelse(E(g)$weight == 0, E(g)$away_team_goal, 0)) +
                    strength(g, vids = vertex, mode = c("out"),
                             weights = ifelse(E(g)$weight == 0, E(g)$home_team_goal, 0))
    defeat.received <- strength(g, vids = vertex, mode = c("in"),
                                weights = ifelse(E(g)$weight < 0, E(g)$away_team_goal, 0)) +
                       strength(g, vids = vertex, mode = c("out"),
                                weights = ifelse(E(g)$weight > 0, E(g)$home_team_goal, 0))
    goals.received <- c(total.received,
                        home.received,
                        away.received,
                        victory.received,
                        tie.received,
                        defeat.received)
    names(goals.received) <- c("total", "home", "away", "victory", "tie", "defeat")
    print(goals.received)
    
    cat("\nAverage goal difference excess in victories:\n")
    n.victories <- (count_scoreTags_as_local(g, rkg) + count_scoreTags_as_visitor(g, rkg))[[1]]
    print((victory.scored - victory.received)/n.victories - 1)
    
    cat("\nAverage goal difference excess in defeats:\n")
    n.defeats <- (count_scoreTags_as_local(g, rkg) + count_scoreTags_as_visitor(g, rkg))[[3]]
    print((defeat.scored - defeat.received)/n.defeats + 1)
}

radian.rescale <- function(x, start = 0, direction = 1) {
    c.rotate <- function(x) (x + start) %% (2 * pi) * direction
    c.rotate(scales::rescale(x, c(0, 2 * pi), range(x)))
}

get_strength_distribution <- function (g, mod) {
    par(mar = c(4, 8, 4, 4))
    barplot(strength(g, vids = V(g), mode = mod)[order(-V(g)$ranking)],
            horiz = T, main = paste0(toupper(mod), "-strength distribution"), cex.names = 0.5, las = 1)
}

get_champion_indices <- function (g) {
    n.victories <- (count_scoreTags_as_local(g, 1) + count_scoreTags_as_visitor(g, 1))[[1]]
    n.defeats <- (count_scoreTags_as_local(g, 1) + count_scoreTags_as_visitor(g, 1))[[3]]
    
    champion <- V(g)[V(g)$ranking == 1][1]
    
    victory.scored <- strength(g, vids = champion, mode = c("in"),
                               weights = ifelse(E(g)$weight > 0, E(g)$home_team_goal, 0)) +
                      strength(g, vids = champion, mode = c("out"),
                               weights = ifelse(E(g)$weight < 0, E(g)$away_team_goal, 0))
    victory.received <- strength(g, vids = champion, mode = c("in"),
                                 weights = ifelse(E(g)$weight > 0, E(g)$away_team_goal, 0)) +
                        strength(g, vids = champion, mode = c("out"),
                                 weights = ifelse(E(g)$weight < 0, E(g)$home_team_goal, 0))
    
    defeat.scored <- strength(g, vids = champion, mode = c("in"),
                              weights = ifelse(E(g)$weight < 0, E(g)$home_team_goal, 0)) +
                     strength(g, vids = champion, mode = c("out"),
                              weights = ifelse(E(g)$weight > 0, E(g)$away_team_goal, 0))
    defeat.received <- strength(g, vids = champion, mode = c("in"),
                                weights = ifelse(E(g)$weight < 0, E(g)$away_team_goal, 0)) +
                       strength(g, vids = champion, mode = c("out"),
                                weights = ifelse(E(g)$weight > 0, E(g)$home_team_goal, 0))
    
    index.victory <- (victory.scored - victory.received)/n.victories - 1
    index.defeat <- ifelse(n.defeats != 0, (defeat.scored - defeat.received)/n.defeats + 1, 0)
    return(c(index.victory, index.defeat))
}

get_all_champion_indices <- function (g_list) {
    indices <- numeric(2 * length(g_list))
    champion <- character(length(g_list))
    
    for (j in 1:length(g_list)) {
        indices[(2*j - 1) : (2*j)] <- get_champion_indices(g_list[[j]])
        champion[j] <- V(g_list[[j]])$name[V(g_list[[j]])$ranking == 1][1]
    }
    return(list("indices" = indices, "champion" = champion))
}

plot_champion_indices <- function (indices.champion, title) {
    par(mar = c(5, 8, 3, 2))
    
    barplot(indices.champion$indices[seq(1, length(indices.champion$indices), 2)], main = title,
            space = 0.4, cex.names = 0.8, las = 1, names.arg = indices.champion$champion, horiz = TRUE,
            plot = TRUE, xlim = c(-1.0, 2.0), xlab = "Goal difference indices")
    barplot(indices.champion$indices[seq(2, length(indices.champion$indices), 2)],
            space = 0.4, cex.names = 0.8, las = 1, horiz = TRUE, col = "darkgrey",
            add = TRUE)
}
