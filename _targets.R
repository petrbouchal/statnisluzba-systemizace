library(targets)
library(tarchetypes)
library(future)

# future::plan(multisession)

# Config ------------------------------------------------------------------

options(conflicts.policy = list(warn = FALSE))
conflicted::conflict_prefer("get", "base", quiet = TRUE)
conflicted::conflict_prefer("merge", "base", quiet = TRUE)
conflicted::conflict_prefer("filter", "dplyr", quiet = TRUE)
conflicted::conflict_prefer("lag", "dplyr", quiet = TRUE)
options(clustermq.scheduler = "LOCAL")

cnf <- config::get()
nms_orig <- names(cnf)
names(cnf) <- paste0("c_", names(cnf))
list2env(cnf, envir = .GlobalEnv)
names(cnf) <- names(nms_orig)
rm(nms_orig)

# Set target-specific options such as packages.
tar_option_set(packages = c("dplyr", "tidygraph", "statnipokladna", "here", "readxl", "xml2",
                            "janitor", "curl", "stringr", "config", "conflicted",
                            "future", "tidyr","ragg", "magrittr", "tibble",
                            "furrr", "ggraph", "purrr", "jsonlite", "glue",
                            "lubridate", "writexl", "readr", "ptrr",
                            "pointblank", "tarchetypes", "forcats", "ggplot2"),
               # debug = "compiled_macro_sum_quarterly",
               # imports = c("purrrow"),
)

options(crayon.enabled = TRUE,
        scipen = 100,
        statnipokladna.dest_dir = "sp_data",
        czso.dest_dir = "~/czso_data",
        yaml.eval.expr = TRUE)


for (file in list.files("R", full.names = TRUE)) source(file)

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


## Metadata ----------------------------------------------------------------

t_meta <- list(
  tar_download(ovm_json,
               "https://rpp-opendata.egon.gov.cz/odrpp/datovasada/ovm.json",
               "data-input/ovm.json"),
  tar_target(ovm, load_ovm(ovm_json))
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


## Tarify ------------------------------------------------------------------

  tar_file_read(tarify_2021,
                # https://www.mfcr.cz/cs/o-ministerstvu/informacni-systemy/is-o-platech/
                # https://www.mfcr.cz/assets/cs/media/Is-o-platech_2021-05-21_Tarifni-tabulky-platne-v-r-2021.xls

                "data-input/tarify/Is-o-platech_2021-05-21_Tarifni-tabulky-platne-v-r-2021.xls",
                load_tarify(!!.x, 2021)),
  tar_file_read(tarify_2022,
                # https://www.mfcr.cz/cs/o-ministerstvu/informacni-systemy/is-o-platech/
                # https://www.mfcr.cz/assets/cs/media/2022-11-24_Tarifni-tabulky-platne-v-roce-2022.xls

                "data-input/tarify/Is-o-platech_2021-05-21_Tarifni-tabulky-platne-v-r-2021.xls",
                load_tarify(!!.x, 2022)),
  tar_file_read(tarify_2023,
                # doplněno ručně z https://www.zakonyprolidi.cz/cs/2014-304#prilohy
                # editován pouze relevantní list

                "data-input/tarify/Manual_Tarifni-tabulky-platne-v-r-2023.xls",
                load_tarify(!!.x, 2023)),
  tar_target(tarify_2024, tarify_2023 |> mutate(rok = 2024)),
  tar_target(tarify, compile_tarify(tarify_2021, tarify_2022, tarify_2023,
                                    tarify_2024))
)


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


## Číselníky ISoSS ---------------------------------------------------------

t_ciselniky <- list(
  tar_download(cis_sluz_urady_csv,
               "https://portal.isoss.cz/ciselniky/ISoSS_TOC_SLURA.csv",
               file.path("data-input", "cis_sluz_urady.csv")),
  tar_target(cis_sluz_urady, read_csv(cis_sluz_urady_csv,
                                      col_types = "cDDccD",
                                      col_names = c("urad_id", "od", "do",
                                                    "urad_nazev", "zkr", "updated"))),
  tar_download(cis_predstaveni_csv,
               "https://portal.isoss.cz/ciselniky/ISoSS_TOC_SLOPR.csv",
               file.path("data-input", "cis_predst.csv")),
  tar_target(cis_predstaveni, read_csv(cis_predstaveni_csv,
                                      col_types = "cDDccD",
                                      col_names = c("predstaveny", "od", "do",
                                                    "predstaveny_nazev", "zkr", "updated"))),
  tar_download(cis_obory_csv,
               "https://portal.isoss.cz/ciselniky/ISoSS_TOC_OBSLU.csv",
               file.path("data-input", "cis_obory.csv")),
  tar_target(cis_obory, read_csv(cis_obory_csv,
                                      col_types = "cDDccD",
                                      col_names = c("obor_sluzby", "od", "do",
                                                    "obor_nazev", "zkr", "updated")))
)


# Systemizace compilation -------------------------------------------------

t_compile_syst <- list(
  tar_target(syst_annual, compile_data(syst_sluz, syst_prac, kapitoly)),
  tar_target(syst_eklep, compile_data(syst_sluz_eklep, syst_prac_eklep, kapitoly)),
  tar_target(syst_all, bind_rows(syst_annual |> mutate(src = "annual"),
                                 syst_eklep  |> mutate(src = "eklep"))),
  tar_target(syst_pocty_long, lengthen_data(syst_all))
)


# Orgchart ----------------------------------------------------------------

# t_orgchart <- list(
#   tar_download(orgdata_xml_fresh, c_orgchart_url, c_orgchart_xml_target),
#   tar_target(orgdata_xml, if(c_orgchart_use_local) c_orgchart_xml_local else orgdata_xml_fresh),
#   tar_target(urady_tbl, extract_urady(orgdata_xml)),
#   tar_target(orgdata_raw, extract_orgdata_raw(orgdata_xml, urady_tbl)),
#
#   tar_target(orgdata_nodes_basic, extract_orgdata_nodes_from_raw(orgdata_raw)),
#   tar_target(orgdata_edges, extract_orgdata_edges_from_raw(orgdata_raw)),
#   tar_target(orgdata_nodes, annotate_orgdata_nodes(orgdata_nodes_basic)),
#   tar_target(orgdata_graph, build_orgdata_graph(orgdata_nodes, orgdata_edges), format = "qs"),
#
#   tar_target(orgdata_nodes_processed, extract_orgdata_nodes_from_graph(orgdata_graph)),
#   tar_target(orgdata_edges_processed, extract_orgdata_edges_from_graph(orgdata_graph)),
#   tar_target(orgdata_rect, rectangularise_orgdata(orgdata_raw)),
#   tar_target(orgdata_date, get_orgdata_date(orgdata_xml))
# )

job_files_xml <- list.files("~/cpers/statnisluzba-downloader/soubory-mista/", full.names = TRUE)


# Jobs --------------------------------------------------------------------


## Načíst ------------------------------------------------------------------

t_jobs <- list(
  tar_files_input(job_files, job_files_xml),
  tar_target(jobs_raw, parse_job_list(job_files), pattern = map(job_files),
             packages = c("dplyr", "xml2", "janitor", "stringr",
                            "future", "tidyr", "purrr",
                            "lubridate", "forcats")),
  tar_file_read(ustredni_nemini, "data-input/urady-ustredni-nemini.csv",
                read_csv(!!.x)),
  tar_file_read(priplatky_vedeni, "data-input/priplatky-vedeni.csv",
                read_csv(!!.x, col_types = "cddddddddd")),
  tar_target(urady_roztridene, label_urady(cis_sluz_urady, ustredni_nemini)),
  tar_target(jobs, process_jobs(jobs_raw, urady_roztridene, cis_predstaveni)),
  tar_target(jobs_uniq, dedupe_jobs(jobs)),


## Simulace ----------------------------------------------------------------

  # tar_target(name)
  tar_target(jobs_salary_sims, simulate_salaries(jobs_uniq, tarify, priplatky_vedeni)),
  tar_target(jobs_uniq_subbed, sub_jobs_for_app(jobs_uniq)),
  tar_target(jobs_salary_sims_subbed, sub_sims_for_app(jobs_salary_sims))

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
                                       write_excel_csv2)),
  # tar_file(export_org_rect, write_data(orgdata_rect, file.path(c_export_dir, "struktura-hierarchie.csv"),
  #                                      write_excel_csv2)),
  # tar_file(export_org_nodes, write_data(orgdata_nodes_processed,
  #                                       file.path(c_export_dir, "struktura-nodes.csv"),
  #                                       write_excel_csv2)),
  # tar_file(export_org_edges, write_data(orgdata_edges_processed,
  #                                       file.path(c_export_dir, "struktura-edges.csv"),
  #                                       write_excel_csv2)),
  # tar_file(app_jobs, export_jobs_for_app(jobs_uniq_subbed)),
  tar_file(app_sims, export_sims_for_app(jobs_salary_sims_subbed))

)


list(t_files, t_read_annual, t_read_eklep, t_compile_syst, t_export,
     t_jobs, t_meta, t_ciselniky)
