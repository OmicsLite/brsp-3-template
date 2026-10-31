#!/usr/bin/env bash
# =============================================================================
#  BRSP Week 3: prepare the example data  (FOR THE TEACHING TEAM, run once)
# =============================================================================
#  Annotates the four relatives of E. coli K-12 with Prokka and saves their
#  gene sequences (.ffn) into week3/data/, so learners can start Week 3
#  straight at 16S extraction.
#
#  Run it in a codespace of the TEMPLATE repo, then commit and push week3/data.
#  Learners who create their repo from the template afterwards get the files.
#
#      bash week3/prepare_example_data.sh
#
#  Time: about 40-60 minutes on the default 2-core codespace (Prokka runs four
#  times). A 4-core codespace roughly halves that.
# =============================================================================
set -euo pipefail

cd "$(git rev-parse --show-toplevel)/week3"
mkdir -p data prep
cd prep

CPUS=$(nproc)

# accession          file name                 genus        species     strain       locus tag
GENOMES="
GCF_000006925.2  shigella_flexneri_301      Shigella     flexneri    2a_str._301  SFLEX
GCF_000006945.2  salmonella_enterica_LT2    Salmonella   enterica    LT2          SENT
GCF_000240185.1  klebsiella_pneumoniae_HS11286 Klebsiella pneumoniae  HS11286      KPNE
GCF_000006765.1  pseudomonas_aeruginosa_PAO1 Pseudomonas aeruginosa  PAO1         PAER
"

echo "$GENOMES" | while read -r ACC NAME GENUS SPECIES STRAIN TAG; do
  [ -z "${ACC:-}" ] && continue
  echo "=== $NAME ($ACC) ==="

  # 1. Download the genome sequence only
  datasets download genome accession "$ACC" --include genome --filename "$NAME.zip"
  rm -rf "${NAME}_download"
  unzip -o -q "$NAME.zip" -d "${NAME}_download"
  cp "${NAME}_download"/ncbi_dataset/data/"$ACC"/*_genomic.fna "$NAME.fna"

  # 2. Annotate (same settings as Week 2)
  prokka --outdir "$NAME" --prefix "$NAME" \
    --kingdom Bacteria --genus "$GENUS" --species "$SPECIES" --strain "$STRAIN" \
    --locustag "$TAG" --cpus "$CPUS" --force \
    "$NAME.fna" > "$NAME.prokka.log" 2>&1
  tail -n 1 "$NAME.prokka.log"

  # 3. Keep the gene sequences (compressed) and the summary
  gzip -c "$NAME/$NAME.ffn" > "../data/$NAME.ffn.gz"
  cp "$NAME/$NAME.txt" "../data/$NAME.summary.txt"

  # 4. Report the 16S copies found
  echo -n "16S copies: "
  grep -c "16S ribosomal RNA" "$NAME/$NAME.ffn" || true
done

cd ..
echo
echo "Done. Files ready to commit:"
ls -lh data/
echo
echo "Next:  git add week3/data && git commit -m 'Week 3 example data' && git push"
echo "The week3/prep folder holds the full Prokka runs; it isn't committed."
