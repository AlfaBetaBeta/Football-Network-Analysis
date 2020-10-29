# Network analysis on European football leagues

In this repository, eight European football leagues over the timespan 2008-2016 (`team_data.csv`) are modelled as graphs and insights are extracted from their properties to try to identify relevant metrics associated to successful teams. The main guidelines regarding execution as well as graph encodings and inferred metrics can be found below:

* [Execution](https://github.com/AlfaBetaBeta/Football-Network-Analysis#execution)
* [Main graph encodings](https://github.com/AlfaBetaBeta/Football-Network-Analysis#main-graph-encodings)
* [Sample conclusions](https://github.com/AlfaBetaBeta/Football-Network-Analysis#sample-conclusions):
	* [Properties of the Spanish champion](https://github.com/AlfaBetaBeta/Football-Network-Analysis#is-it-possible-to-infer-the-properties-of-the-champion-each-season)
	* [Patterns of champions on each league](https://github.com/AlfaBetaBeta/Football-Network-Analysis#are-there-any-salient-patterns-for-the-top-performing-team-of-each-league)
	* [Anomalous cases](https://github.com/AlfaBetaBeta/Football-Network-Analysis#are-there-salient-anomalous-features-arising-from-inspection-of-the-graphs)

## Execution

The football network analysis is performed by means of the R library `igraph`, whereby the main R script `footballNetwork.R` is the one meant to be interacted with by the user. For `footballNetwork.R` to execute properly, it must be saved in a directory alongside the source data file `team_data.csv` and the additional R script `Supporting_functions.R` where all user defined functions are sourced from. This supporting R script may be opened for function inspection but should not be edited. The `footballNetwork.R` script is divided in foldable sections `[I]` to `[XII]` for user convenience. Navigating through them can be done manually, via the `Code/Jump To...` command or the menu at the bottom of the editor window:

* Sections `[I]` and `[II]` **MUST** be executed successively in all cases, as they deal with the preprocessing of the imported data and the sourcing of supporting functions, and their output is required in subsequent sections.

* Section `[III]` is optional but recommended, as it may be illustrative for the use of many graph-querying supporting functions. The user may use it as a guide for their own queries of interest in any league and season.

* Sections `[IV]` to `[XI]` are compact as they programmatically create lists of graphs and store them as `png` files in the working directory. They can be executed independently and in arbitrary order, so the user can focus on their league(s) of interest.

* Section `[XII]` contains some further study regarding all European champions. It requires previous execution of ALL Sections `[IV]` to `[XI]` (in whatever order).


## Main graph encodings

The following encoding descriptions should facilitate the interpretation of the graphs generated during execution of the main script `footballNetwork.R`:

* Nodes represent teams and edges represent matches, whereby each circular graph conveys information about a given league in a given season.

* Edge direction - each match has a visiting team and a home team, hence the edge follows this motion intuitively, pointing from the visitor to the host. Since in any season all teams play against each other twice (home and away), the graph for any league on any season is fully connected and bidirectional.

<p align="middle">
  <img src="https://github.com/AlfaBetaBeta/Football-Network-Analysis/blob/master/img/encodings/edge_direction.png" width=40% height=40%>
</p>

* Edge properties - the goal difference (home - visitor) for a match is encoded as the edge thickness, and the edge colour signifies:
    * blue: home win
    * red: visitor win
    * grey: tie

<p align="middle">
  <img src="https://github.com/AlfaBetaBeta/Football-Network-Analysis/blob/master/img/encodings/edge_colour_thickness.png" width=40% height=40%>
</p>

* Node properties - the node size can represent either the goal difference or the total number of points at the end of the season for a given team (the distinction is specified wherever appropriate), whereas the node colour relates to the goal difference as follows:
    * blue: positive difference
    * red: negative difference
    * grey: null difference

<p align="middle">
  <img src="https://github.com/AlfaBetaBeta/Football-Network-Analysis/blob/master/img/encodings/node_colour_size.png" width=40% height=40%>
</p>

As an illustrative example, the graph below shows season 2013-2014 of the Spanish League (node size encoding total points), with all teams/nodes ordered as per end-of-season ranking starting at 3 o'clock and arranged counter clockwise, whereby the following sample observations can be corroborated by inspection with ease:
* the champion (Atlético) did not lose a single match at home.
* the champion won every home game except on four tie occasions, against Real Madrid (2<sup>nd</sup>), Barcelona (3<sup>rd</sup>), Sevilla (5<sup>th</sup>) and Málaga (11<sup>th</sup>).
* Real Madrid did not manage to win (home or away) a single match against its two main competitors (Atlético and Barcelona), actually losing throughout except the tie when visiting Atlético.
* one of the most one sided scores corresponds to the match between Levante (10<sup>th</sup>, visitor) and Barcelona (3<sup>rd</sup>, host).
* Rayo Vallecano (12<sup>th</sup>) barely tied throughout the season, and that happened only as visitor.

![example](/img/encodings/example.png)


## Sample conclusions

### Is it possible to infer the properties of the champion each season?

In many of the analysed seasons of the Spanish league the champion has been overwhelmingly dominant, typically one of the historical Big Two (Real Madrid & Barcelona). It is hence of interest to inspect the season 2013/2014, the only one with a different champion (Atlético) in the timespan under consideration. Though obviously Atlético earned more points than any other team, it did not lead with regard to other metrics compared to the Big Two. As can be seen in the circular graph above, most head-to-heads Atlético vs Big Two ended in a draw, with the exception of the victory over Real Madrid as a visitor. The overall goal difference of Atlético is smaller than that of its pursuivants, and the same can be corroborated when inspecting the in- and out-strength of the network.

<p align="middle">
  <img src="https://github.com/AlfaBetaBeta/Football-Network-Analysis/blob/master/img/Spanish_League/Spanish-season-2013-2014-IN-strength.png" width="45%" />
  <img src="https://github.com/AlfaBetaBeta/Football-Network-Analysis/blob/master/img/Spanish_League/Spanish-season-2013-2014-OUT-strength.png" width="45%" /> 
</p>

With all the network attributes at hand, it is convenient to derive a metric from them that can quantify a team's performance. To this end, the following assumptions are made:

* The total goal difference at victories is the main favourable feature , i.e. the excess of goals scored over those received in victories (deemed as harmless) is what provides value in terms of points.

* The total goal difference at defeats is the main unfavourable feature, i.e. the excess of goals received over those scored at defeats (deemed as worthless) is what penalises a team in terms of points.

* Ties are disregarded as the goal difference is zero by definition.

Under these assumptions, two indices can be calculated as follows:

<img src="https://render.githubusercontent.com/render/math?math=\left(\frac{\text{goal.difference}}{N}\right)_{\text{victory}}-1">
<br/>
<img src="https://render.githubusercontent.com/render/math?math=\left(\frac{\text{goal.difference}}{N}\right)_{\text{defeat}}%2B1">

These goal difference indices express the average goal difference excess in victories and defeats, respectively, i.e. the average favourable excess over the minimum victory (1-0) and the average unfavourable excess over the minimum defeat (0-1), whereby the defeat index is set to zero if a team did not lose over an entire season.

In terms of optimisation of 'football resources', it is desirable for a team to have both indices tending to zero, as that represents a champion obtaining the maximum value from its goals and no leeway whatsoever (any one scored goal less would in average lead to a different final amount of points). Whilst this is optimal from the perspective of resource management, it does not necessarily align with other criteria such as showmanship and fan experience. Dominant teams, those that persist in the fanbase memory and are the most profitable in merchandising, are rather teams that minimise the defeat index and maximise the victory one.

As can be seen in the barplot below, representing the goal difference indices for the Spanish league over all seasons, Atlético was indeed the most optimal champion from the victory index side, though the worst from the defeat perspective. This confirms the intuition that they obtained a greater benefit from less 'assets' than the Big Two, becoming a champion arguably less compelling to the wider fanbase worldwide.

<p align="middle">
  <img src="https://github.com/AlfaBetaBeta/Football-Network-Analysis/blob/master/img/Spanish_League/Spanish league goalDiff indices.png" width=50% height=50%>
</p>

### Are there any salient patterns for the top performing team of each league?

Following the disquisitions of the Spanish league champions and the goal difference indices as a derived metric to evaluate their performance, it is of interest to compare all European champions based on this common framework.

<img src="https://github.com/AlfaBetaBeta/Football-Network-Analysis/blob/master/img/all_leagues/Goal difference indices European champions.png" width=100% height=100%>

The set of barplots representing these indices for all leagues showcases some relevant features. The Italian league consistently has champions with a narrow index range , which goes in line with the generalised fan perception that it is a league that prioritises defence. From a certain perspective, however, it can be regarded as the league that produces the most optimal champions.

The Dutch and the Swiss leagues have champions with both non-zero indices throughout. Regardless of their dominance in victories, this means that these teams are to some extent (and compared to other leagues) vulnerable to defeats and hence more approachable by potential pursuivants. Despite this, the Swiss league is effectively a monopoly of Basel, which suggests that the goal difference indices need adjustments for smaller and more volatile leagues.

The Spanish, English, French and German leagues (in turn considered amongst the most compelling ones from the offence perspective) indeed have had a considerably dominant team at least in one of the seasons (e.g. Barcelona 2014/2015, Chelsea 2009/2010, Paris Saint-Germain 2015/2016 and Bayern Munich 2014/2015, respectively). It is interesting to note the parallelism between these dominances and the budget prevalence of these same teams in their respective leagues, which raises the question as to what is the real return of these huge investments, particularly when considering that these leagues have had more 'optimal' champions (e.g. Atlético 2013/2014, Leicester City 2015/2016, Montpellier 2011/2012 and Borussia 2010/2011).

### Are there salient anomalous features arising from inspection of the graphs?

The Dutch season 2009/2010 and the English season 2014/2015 showcase a similar phenomenon when inspecting their respective graphs (node size scaled by goal difference):

<img src="https://github.com/AlfaBetaBeta/Football-Network-Analysis/blob/master/img/Dutch_league/matches Netherlands 2009-2010 by goalDiff.png" width=100% height=100%>
<img src="https://github.com/AlfaBetaBeta/Football-Network-Analysis/blob/master/img/English_league/matches England 2014-2015 by goalDiff.png" width=100% height=100%>

Southampton (7<sup>th</sup>) and particularly Ajax (2<sup>nd</sup>) display a significantly favourable goal difference that did not fully translate into an intuitive ranking. Ajax goal difference is 40 goals greater than that of the Dutch champion that year (Twente), though many goals seem to be in excess of the minimum victory as local, whereas they practically lost all matches when playing against teams of the second half of the ranking as visitor. Similarly, Southampton pulled off the most one sided score of the entire season when beating Sunderland (16<sup>th</sup>) as local, as can be checked by inspection, but otherwise had a poor head-to-head with the two teams immediately ahead (Liverpool and Tottenham), which points to these capitalising better on their goals (Tottenham for instance had a poorer balance as local than Shouthampton but was a very effective visitor, with many tight scores).