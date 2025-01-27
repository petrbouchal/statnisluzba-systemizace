library(targets)
library(tarchetypes)
library(crew)

tar_option_set(
  controller = crew_controller_local(workers = 1)
)

# Config ------------------------------------------------------------------

source("_targets_packages.R")

options(conflicts.policy = list(warn = FALSE))
conflicted::conflict_prefer("get", "base", quiet = TRUE)
conflicted::conflict_prefer("merge", "base", quiet = TRUE)
conflicted::conflict_prefer("filter", "dplyr", quiet = TRUE)
conflicted::conflict_prefer("lag", "dplyr", quiet = TRUE)

cnf <- config::get()
nms_orig <- names(cnf)
names(cnf) <- paste0("c_", names(cnf))
list2env(cnf, envir = .GlobalEnv)
names(cnf) <- names(nms_orig)
rm(nms_orig)

# Set target-specific options such as packages.
tar_option_set(packages = c("dplyr", "statnipokladna", "here", "readxl", "xml2",
                            "janitor", "curl", "stringr", "config", "conflicted",
                            "tidyr","ragg", "magrittr", "tibble",
                            "purrr", "jsonlite", "glue",
                            "lubridate", "writexl", "readr", "ptrr",
                            "pointblank", "tarchetypes", "forcats"),
               # debug = "compiled_macro_sum_quarterly",
               # imports = c("purrrow"),
)

options(crayon.enabled = TRUE,
        scipen = 100,
        statnipokladna.dest_dir = "sp_data",
        czso.dest_dir = "~/czso_data",
        yaml.eval.expr = TRUE)


tar_source()


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

## Annual systemizace ------------------------------------------------------

t_read_annual <- list(
  tar_target(syst_rows_skip, c_syst_skip),
  tar_target(syst_years, as.integer(c_syst_years)),
  tar_target(syst_periods, make_date(syst_years, 1, 1)),
  tar_target(syst_sluz, load_syst(syst_xlsx, syst_years, syst_periods, syst_rows_skip, sheet = 1),
             pattern = map(syst_xlsx, syst_years, syst_rows_skip, syst_periods)),
  tar_target(syst_prac, load_syst(syst_xlsx, syst_years, syst_periods, syst_rows_skip, sheet = 2),
             pattern = map(syst_xlsx, syst_years, syst_periods, syst_rows_skip)),
  tar_file_read(kapitoly, "data-input/kapitoly.csv", read_csv(!!.x, col_types = "cccl")),


## Systemizace eklep -------------------------------------------------------

t_read_eklep <- list(
  tar_target(syst_rows_skip_eklep_sluz, c_syst_eklep_skip_prac),
  tar_target(syst_rows_skip_eklep_prac, c_syst_eklep_skip_sluz),
  tar_target(syst_rows_nmax_eklep_sluz, c_syst_eklep_nmax_prac),
  tar_target(syst_rows_nmax_eklep_prac, c_syst_eklep_nmax_sluz),
  tar_target(syst_eklep_periods, c_syst_eklep_periods),
  tar_target(syst_eklep_files, file.path(c_syst_eklep_dir, c_syst_eklep_files)),
  tar_target(syst_eklep_years, c_syst_eklep_years),
  tar_target(syst_prac_eklep,
             load_syst(syst_eklep_files, syst_eklep_years, syst_eklep_periods,
                       syst_rows_skip_eklep_prac,
                       syst_rows_nmax_eklep_prac,
                       sheet = 2),
             pattern = map(syst_eklep_files, syst_eklep_years,
                           syst_eklep_periods, syst_rows_skip_eklep_prac,
                           syst_rows_nmax_eklep_prac)),
  tar_target(syst_sluz_eklep,
             load_syst(syst_eklep_files, syst_eklep_years, syst_eklep_periods,
                       syst_rows_skip_eklep_sluz,
                       syst_rows_nmax_eklep_sluz,
                       sheet = 1),
             pattern = map(syst_eklep_files, syst_eklep_years,
                           syst_eklep_periods, syst_rows_skip_eklep_sluz,
                           syst_rows_nmax_eklep_sluz))
  )
)

# Systemizace compilation -------------------------------------------------

t_compile_syst <- list(
  tar_target(syst_annual, compile_data(syst_sluz, syst_prac, kapitoly)),
  tar_target(syst_eklep, compile_data(syst_sluz_eklep, syst_prac_eklep, kapitoly)),
  tar_target(syst_all, bind_rows(syst_annual |> mutate(src = "annual"),
                                 syst_eklep  |> mutate(src = "eklep"))),
  tar_target(syst_pocty_long, lengthen_data(syst_all))
)

# Export ------------------------------------------------------------------

t_export <- list(
  tar_file(export_all, write_data(syst_all, file.path(c_export_dir, "systemizace_all.csv"))),
  tar_file(export_all_parquet, write_data(syst_all, file.path(c_export_dir, "systemizace_all.parquet"),
                                          arrow::write_parquet)),
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


list(t_files, t_read_annual,
     # t_read_eklep,
     t_compile_syst, t_export)
