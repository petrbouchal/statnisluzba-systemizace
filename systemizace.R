source("_targets_packages.R")

targets::tar_load(syst_all)

syst_all |>
  filter(kap != "Celkem") |>
  select(year, predst, ostat, typ, obcanstvi, konkurence) |>
  group_by(year, typ) |>
  summarise(across(c(predst, ostat, obcanstvi, konkurence), sum, na.rm = TRUE)) |>
  gather("var", "pocet", -typ, -year) |>
  filter(var %in% c("predst", "ostat")) |>
  ggplot(aes(x = year)) +
  geom_col(aes(y = pocet/1e3, fill = var)) +
  facet_wrap(~typ)

syst_all |>
  filter(year == 2021,
         typ == "sluz",
         # kap == "Celkem",
         uo,
         str_detect(nazev, "^Mini|^Úřad")) |>
  count(wt = ostat)

syst_all |>
  filter(kap == "Celkem") |>
  select(year, typ, predst, ostat, kap) |>
  drop_na(ostat) |>
  mutate(celkem = predst + ostat)

syst_all |>
  filter(year == 2021,
         typ == "sluz",
         # kap == "Celkem",
         uo,
         str_detect(nazev, "^Mini|^Úřad vl")) |>
  pivot_longer(cols = matches("predst_|ostat_"), names_to = "trida", values_to = "pocet") |>
  separate(trida, into = c("level", "trida")) |>
  ggplot(aes(trida, pocet, fill = level)) +
    geom_col() +
    facet_wrap(~ nazev)

syst_pocty_long <- syst_all |>
  pivot_longer(cols = matches("predst_|ostat_"), names_to = "trida", values_to = "pocet") |>
  separate(trida, into = c("level", "trida")) |>
  select(-predst, -ostat, -platy, -obcanstvi, -konkurence)

syst_perorg <- syst_all |>
  select(year, kap, uo, nazev, platy, obcanstvi, konkurence)

