library(targets)
library(tarchetypes)
library(future)

# Config ------------------------------------------------------------------

options(conflicts.policy = list(warn = FALSE))
conflicted::conflict_prefer("get", "base", quiet = TRUE)
conflicted::conflict_prefer("merge", "base", quiet = TRUE)
options(clustermq.scheduler = "LOCAL")

cnf <- config::get()
nms_orig <- names(cnf)
names(cnf) <- paste0("c_", names(cnf))
list2env(cnf, envir = .GlobalEnv)
names(cnf) <- names(nms_orig)
rm(nms_orig)

# Set target-specific options such as packages.
tar_option_set(packages = c("dplyr", "statnipokladna", "here", "readxl",
                            "janitor", "curl", "stringr", "config", "conflicted",
                            "dplyr", "future", "tidyr","ragg", "magrittr",
                            "lubridate", "writexl", "readr", "purrr", "ptrr",
                            "pointblank", "tarchetypes", "forcats", "ggplot2"),
               # debug = "compiled_macro_sum_quarterly",
               # imports = c("purrrow"),
)

options(crayon.enabled = TRUE,
        scipen = 100,
        statnipokladna.dest_dir = "sp_data",
        czso.dest_dir = "~/czso_data",
        yaml.eval.expr = TRUE)

future::plan(multisession)

source("R/utils.R")
source("R/functions.R")
source("_targets_packages.R")

syst_urls <- paste0(c_syst_base_url, "/",
                    stringr::str_replace(c_syst_files_online, "\\.", "-"),
                    ".aspx")
syst_files <- file.path(c_syst_dir, paste0("syst_", c_syst_years, ".xlsx"))

t_files <- list(
  tar_target(t_syst_urls, syst_urls),
  tar_target(syst_rows_skip, c(4, 4, 3, 3)),
  tar_target(syst_years, c_syst_years),
  tar_target(t_syst_files, syst_files),
  tar_target(syst_xlsx, curl::curl_download(t_syst_urls, t_syst_files),
             pattern = map(t_syst_urls, t_syst_files), format = "file"),
  tar_target(syst_sluz, load_syst(syst_xlsx, syst_years, syst_rows_skip, sheet = 1),
             pattern = map(syst_xlsx, syst_years, syst_rows_skip)),
  tar_target(syst_prac, load_syst(syst_xlsx, syst_years, syst_rows_skip, sheet = 2),
             pattern = map(syst_xlsx, syst_years, syst_rows_skip)),
  tar_target(syst_all,
             bind_rows(syst_sluz |> mutate(typ = "sluz"),
                       syst_prac |> mutate(typ = "prac")) |>
               mutate(uo = !is.na(kap)) |>
               fill(kap, .direction = "down") |>
               relocate(year, typ, kap, nazev, uo, celkem))
  )

list(t_files)
