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


# Load data ---------------------------------------------------------------

t_files <- list(
  tar_target(t_syst_urls, syst_urls),
  tar_target(t_syst_files, syst_files),
  tar_target(syst_xlsx, curl::curl_download(t_syst_urls, t_syst_files),
             pattern = map(t_syst_urls, t_syst_files), format = "file")
  )

t_read <- list(
  tar_target(syst_rows_skip, c(2, 3, 3, 3, 3)),
  tar_target(syst_years, as.integer(c_syst_years)),
  tar_target(syst_sluz, load_syst(syst_xlsx, syst_years, syst_rows_skip, sheet = 1),
             pattern = map(syst_xlsx, syst_years, syst_rows_skip)),
  tar_target(syst_prac, load_syst(syst_xlsx, syst_years, syst_rows_skip, sheet = 2),
             pattern = map(syst_xlsx, syst_years, syst_rows_skip)),
  tar_file_read(kapitoly, "data-input/kapitoly.csv", read_csv(!!.x, col_types = "cccl")),
  tar_file_read(tarify_2021,
                # https://www.mfcr.cz/cs/o-ministerstvu/informacni-systemy/is-o-platech/
                # https://www.mfcr.cz/assets/cs/media/Is-o-platech_2021-05-21_Tarifni-tabulky-platne-v-r-2021.xls

                "data-input/tarify/Is-o-platech_2021-05-21_Tarifni-tabulky-platne-v-r-2021.xls",
                read_xls(!!.x, sheet = 5, range = "B6:T17", col_names = FALSE) |>
                  set_names(c("stupen", paste0("trida", "_", str_pad(1:16, 2, pad = "0")),
                              "praxe_do_nad", "praxe_let")))
)

t_compile <- list(
  tar_target(syst_all, compile_data(syst_sluz, syst_prac, kapitoly)),
  tar_target(syst_pocty_long, lengthen_data(syst_all))
)

t_export <- list(
  tar_file(export_all, write_data(syst_all, file.path(c_export_dir, "systemizace_all.csv"))),
  tar_file(export_long_parquet, write_data(syst_pocty_long,
                                   file.path(c_export_dir, "systemizace_pocty_long.parquet"),
                                   arrow::write_parquet)),
  tar_file(export_long_excel, write_data(syst_pocty_long,
                                   file.path(c_export_dir, "systemizace_pocty_long.xlsx"),
                                   writexl::write_xlsx)),
  tar_file(export_long_csv, write_data(syst_pocty_long |> select(-kapitola_nazev, -kapitola_typ,
                                                                   -organizace_typ, -kapitola_zkr,
                                                                   -kapitola_vladni, -level_nazev),
                                   file.path(c_export_dir, "systemizace_pocty_long.csv"),
                                   write_excel_csv2))
)
list(t_files, t_read, t_compile, t_export)
