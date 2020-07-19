# Network analysis on European football leagues

Network analysis is performed on several European football leagues via `igraph`.

The `footballNetwork.R` script is divided in foldable sections `[I]` to `[XII]` for user convenience.
Navigating through them can be done manually, via the `Code/Jump To...` command or the menu at the
bottom of the editor window.

For this R script to execute properly, it must be saved in a directory alongside the source data file
`team_data.csv` and the additional R script `Supporting_functions.R` where all user defined functions
are sourced from. This supporting R script may be opened for function inspection but should not be edited.

Sections `[I]` and `[II]` MUST be executed successively in all cases, as they deal with the preprocessing
of the imported data and the sourcing of supporting functions, and their output is required in subsequent
sections.

Section `[III]` is optional but recommended, as it may be illustrative for the use of many graph-querying
supporting functions. The reader may use it as a guide for their own queries of interest in any league
and season.

Sections `[IV]` to `[XI]` are compact as they programmatically create lists of graphs and store them as
`png` files in the working directory. All graph plots included in the pdf report can be reproduced in
these sections. They can be executed independently and in arbitrary order, so the reader can focus on
their league(s) of interest.

Section `[XII]` contains some further study regarding all European champions. It requires previous
execution of ALL Sections `[IV]` to `[XI]` (in whatever order).

# Main graph encodings

The following encoding descriptions should facilitate the interpretation of the graphs generated during execution of the main script:

* Nodes represent teams and edges represent matches, whereby each circular graph conveys information about a given league in a given season.
* Edge direction: each match has a visiting team and a home team, hence the edge follows this motion intuitively, pointing from the visitor to the host. Since in any season all teams play against each other twice (home and away), the graph for any league on any season is fully connected and bidirectional.

![edge_direction](/img/encodings/edge_direction.png)
* Edge properties: 