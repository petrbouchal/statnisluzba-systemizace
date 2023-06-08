make_org_visnetwork <- function(graph, urad_zkr, igraph_layout) {
  orgdata_mini_edges <- extract_orgdata_edges_from_graph(graph, urad_zkratka == urad_zkr)
  orgdata_mini_nodes <- extract_orgdata_nodes_from_graph(graph, urad_zkratka == urad_zkr)

  color_palette <- c("black", "#1A1A1A", "#4D4D4D", "#7F7F7F", "#B3B3B3", "#CCCCCC") |> rev()

  vn_jednomini_base <- visNetwork(
    orgdata_mini_nodes |>
      mutate(value = child_ftes,
             dpth = dpth - 1,
             color0 = dpth,
             title = nazev,
             label = nazev,
             analyticky = str_detect(tolower(nazev), "anal|koncep|evalu|progn|expert|výzk|hodnoc|monit"),
             color0 = color_palette[dpth],
             nazev_lower = tolower(nazev),
             color = case_when(str_detect(nazev_lower, "anal|eval") ~ "#8B008B",
                               str_detect(nazev_lower, "hodnocen") ~ "#006400",
                               str_detect(nazev_lower, "monitor") ~ "#EE7600",
                               str_detect(nazev_lower, "výzkum") ~ "#00008B",
                               str_detect(nazev_lower, "strateg|polit|koncep") ~ "#CD0000",
                               str_detect(nazev_lower, "statist") ~ "#4876FF",
                               .default = color0),
             value = if_else(dpth == 1, 0, value)),
    orgdata_mini_edges) |>
    visOptions(collapse = TRUE, highlightNearest = TRUE) |>
    visNodes() |>
    # visEdges(arrows = "to", smooth = TRUE) %>%
    visEdges(arrows = "none", smooth = list(enabled = TRUE, type = "cubicBezier")) |>
    visInteraction(zoomView = TRUE)

  if (!missing(igraph_layout)) {
    vn_jednomini <- vn_jednomini_base |>
      visIgraphLayout(layout = igraph_layout)
  }  else {
    vn_jednomini <- vn_jednomini_base |>
      visHierarchicalLayout(sortMethod = "directed",
                            direction = "LR",
                            nodeSpacing = 100,
                            shakeTowards = "roots",
                            parentCentralization = T,
                            levelSeparation = 1500)
  }
  vn_jednomini
}
