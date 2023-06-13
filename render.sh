# Rscript -e "tar_invalidate(starts_with("doc_org_"))"
# Rscript -e "targets::tar_make()"
quarto render
rm -rf docs/orgs/docs
# netlify deploy --prod
