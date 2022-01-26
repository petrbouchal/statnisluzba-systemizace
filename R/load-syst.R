load_syst <- function(path, yr, skip, sheet = 1) {

  nms <- c("kap", "nazev",
           "predst",
           paste0("predst_", str_pad(c(5:16), 2, side = "left", pad = "0")),
           "ostat",
           paste0("ostat_", str_pad(c(5:16), 2, side = "left", pad = "0")),
           "platy", "obcanstvi", "konkurence"
  )
  nms_prac <- c("kap", "nazev",
                "predst",
                "predst_M",
                paste0("predst_", str_pad(c(1:16), 2, side = "left", pad = "0")),
                "ostat",
                "ostat_M",
                paste0("ostat_", str_pad(c(1:16), 2, side = "left", pad = "0")),
                "platy", "obcanstvi", "konkurence"
  )
  x <- readxl::read_excel(path, sheet = sheet,
                          skip = skip)
  x <- janitor::remove_empty(x[-1,], which = "cols")

  nms <- if(sheet == 1) nms else nms_prac

  names(x) <- nms
  x$year <- yr

  x <- mutate(x, across(3:ncol(x), as.numeric),
              celkem = predst + ostat)

  return(x)

}
