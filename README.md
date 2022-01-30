
<!-- README.md is generated from README.Rmd. Please edit that file -->

# systemizace

<!-- badges: start -->
<!-- badges: end -->

This repository contains R code to download and process official data on
the organisation of public servants in the Czech central public
administration - “systemizace služebních míst”.

The code downloads, loads and processes the published excel files such
that

-   the data is in tidy format
-   civil servants and employees are in one data frame
-   pay grades (platové třídy) and management levels (představení) are
    correctly identified

See
<https://www.mvcr.cz/sluzba/clanek/systemizace-sluzebnich-a-pracovnich-mist.aspx>

Data currently available from 2018 to 2022.

For more info on data on public servants see [recent
report](https://idea.cerge-ei.cz/zpravy/statni-zamestnanci-a-urednici-kde-pracuji-a-za-kolik)
and [related repo](https://github.com/dan-bart/urednici_2021), plus an
[older overview of available
sources](https://petrbouchal.xyz/urednici/).

Code organised as a {targets} pipeline, with packages tracked by {renv},
so can be reproduced like so:

``` r
renv::restore()
targets::tar_make()
```

Tidy data ready for analysis are in `data-export`. Codebook is TBA.

Rendered 2022-01-30 02:36:28
