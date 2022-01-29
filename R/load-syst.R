load_syst <- function(path, yr, skip, sheet = 1) {

  nms <- c("kapitola_kod", "organizace_nazev",
           "pocet_predst",
           paste0("pocet_predst_", str_pad(c(5:16), 2, side = "left", pad = "0")),
           "pocet_ostat",
           paste0("pocet_ostat_", str_pad(c(5:16), 2, side = "left", pad = "0")),
           "platy_celkem", "pozad_obcanstvi", "pozad_zakazkonkurence"
  )
  nms_prac <- c("kapitola_kod", "organizace_nazev",
                "pocet_predst",
                "pocet_predst_M",
                paste0("pocet_predst_", str_pad(c(1:16), 2, side = "left", pad = "0")),
                "pocet_ostat",
                "pocet_ostat_M",
                paste0("pocet_ostat_", str_pad(c(1:16), 2, side = "left", pad = "0")),
                "platy_celkem", "pozad_obcanstvi", "pozad_zakazkonkurence"
  )
  x <- readxl::read_excel(path, sheet = sheet,
                          skip = skip)
  if(yr == 2018) x <- x[,-1] # drop hidden stray first column
  x <- janitor::remove_empty(x[-1,], which = "cols")

  nms <- if(sheet == 1) nms else nms_prac

  names(x) <- nms
  x$rok <- yr

  x <- mutate(x, across(3:ncol(x), as.numeric),
              pocet_celkem = pocet_predst + pocet_ostat,
              rok = as.integer(rok),
              kapitola_kod = if_else(kapitola_kod == "307*", "307", kapitola_kod))

  return(x)

}
