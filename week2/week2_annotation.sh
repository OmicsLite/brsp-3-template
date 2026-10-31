#!/usr/bin/env bash
# =============================================================================
#  BRSP Week 2: Annotating a Bacterial Genome with Prokka
#  OmicsLite · Bioinformatics Research Starter Program · Codespaces version
# =============================================================================
#
#  HOW TO USE THIS FILE
#  - Open a terminal in your codespace: menu ☰ → Terminal → New Terminal.
#  - Copy ONE block at a time (between the dashed lines), paste it into the
#    terminal, press Enter, and wait for it to finish before the next block.
#    Shortcut: select the lines, then Ctrl+Shift+P →
#    "Terminal: Run Selected Text in Active Terminal".
#  - Lines starting with # are comments for you to read. Pasting them is harmless.
#  - Compare your output with the "WHAT YOU SHOULD SEE" notes.
#
#  Time needed: about 30 minutes, mostly waiting for Prokka.
# =============================================================================


# -----------------------------------------------------------------------------
# STEP 1  Go to your Week 2 folder and check the tools
# -----------------------------------------------------------------------------
# Run this block at the start of every session.

mkdir -p "$(git rev-parse --show-toplevel)/week2"
cd "$(git rev-parse --show-toplevel)/week2"
pwd
prokka --version
datasets --version

# WHAT YOU SHOULD SEE
#   /workspaces/<your-repo-name>/week2
#   prokka 1.15.6
#   datasets version: 18.x.x
#
# "command not found"? Open a new terminal and try again. Still missing?
# Check the setup log:  tail -n 20 ~/brsp-setup.log


# -----------------------------------------------------------------------------
# STEP 2  Download the example genome
# -----------------------------------------------------------------------------
# E. coli K-12 MG1655, accession GCF_000005845.2. We ask for the genomic FASTA
# only (--include genome), not NCBI's own annotation: annotating it is our job.

datasets download genome accession GCF_000005845.2 --include genome \
  --filename ecoli_k12.zip
unzip -o -q ecoli_k12.zip -d ecoli_download
cp ecoli_download/ncbi_dataset/data/GCF_000005845.2/*_genomic.fna ecoli_k12.fna
ls -lh ecoli_k12.fna

# WHAT YOU SHOULD SEE
#   A file called ecoli_k12.fna, about 4.5 MB.
#   It also appears in the file list on the left, inside the week2 folder.
#
# CHECKPOINT: why do we download the genome WITHOUT NCBI's annotation?


# -----------------------------------------------------------------------------
# STEP 3  Inspect the input
# -----------------------------------------------------------------------------

# How many sequences? (each starts with a '>' header line)
grep -c ">" ecoli_k12.fna

# The header line
grep ">" ecoli_k12.fna

# The first few lines of DNA
head -n 4 ecoli_k12.fna

# Genome length: drop header lines and line breaks, then count the letters
grep -v ">" ecoli_k12.fna | tr -d '\n' | wc -c

# WHAT YOU SHOULD SEE
#   1
#   >NC_000913.3 Escherichia coli str. K-12 substr. MG1655, complete genome
#   ...
#   4641652
#
# One sequence, about 4.6 million letters, and no labels at all.
#
# CHECKPOINT: if this were a draft genome, how would the first number differ?


# -----------------------------------------------------------------------------
# STEP 4  Run Prokka  (about 10–15 minutes)
# -----------------------------------------------------------------------------
#   --outdir / --prefix   where results go and what the files are called
#   --kingdom Bacteria    use settings for bacterial genes
#   --genus/--species/--strain   label results with the organism's name
#   --locustag ECOLI      readable gene IDs, like ECOLI_00001
#   --cpus 2              use the 2 processor cores your codespace has
#   --force               overwrite the folder if you run this again
#
# Prokka runs several tools for you: Prodigal finds protein-coding genes,
# barrnap finds rRNA genes (including 16S), Aragorn finds tRNA genes, and BLAST
# and HMMER compare genes against databases to guess what they do.

prokka --outdir ecoli_k12 --prefix ecoli_k12 \
  --kingdom Bacteria --genus Escherichia --species coli --strain K-12 \
  --locustag ECOLI --cpus 2 --force \
  ecoli_k12.fna > prokka_run.log 2>&1
tail -n 3 prokka_run.log

# WHAT YOU SHOULD SEE
#   The last lines include a goodbye message, such as "Share and enjoy!"
#   or "Thank you, come again." If you see ERROR, check Troubleshooting below.
#
# Want to watch progress? Open a second terminal (the + button in the terminal
# panel) and run:   tail -f prokka_run.log      (Ctrl+C to stop watching)
#
# Keep the browser tab open while Prokka runs. A codespace stops after
# 30 minutes without activity, and a running command doesn't always count.


# -----------------------------------------------------------------------------
# STEP 5  Explore the outputs  (lesson 2.4)
# -----------------------------------------------------------------------------
#   .txt  summary counts               .gff  every feature with its position
#   .tsv  one row per feature          .gbk  features + sequence (GenBank)
#   .ffn  DNA of every gene (Week 3!)  .faa  protein of every gene
#   .log  everything Prokka did

ls -lh ecoli_k12/
cat ecoli_k12/ecoli_k12.txt
head -n 10 ecoli_k12/ecoli_k12.tsv

# WHAT YOU SHOULD SEE (in the summary; numbers may differ slightly)
#   contigs: 1
#   bases: 4641652
#   CDS: about 4,300–4,500
#   rRNA: about 22
#   tRNA: about 85–90
#
# Tip: click ecoli_k12/ecoli_k12.tsv in the file list on the left to open it
# as a colour-coded table.
#
# CHECKPOINT: which column would you use to count the rRNA genes?


# -----------------------------------------------------------------------------
# STEP 6  Find a specific gene  (lesson 2.4)
# -----------------------------------------------------------------------------

# lacZ: beta-galactosidase, from the lac operon
grep -w "lacZ" ecoli_k12/ecoli_k12.tsv

# Where is it? Columns: sequence, type, start, end, strand
grep "gene=lacZ;" ecoli_k12/ecoli_k12.gff | cut -f1,3,4,5,7

# If lacZ isn't found by name, search by what it makes:
#   grep -i "beta-galactosidase" ecoli_k12/ecoli_k12.tsv

# 16S rRNA: the gene we'll use to build trees in Week 3
grep "16S ribosomal RNA" ecoli_k12/ecoli_k12.tsv
grep -c "16S ribosomal RNA" ecoli_k12/ecoli_k12.tsv

# WHAT YOU SHOULD SEE
#   lacZ, about 3,000 bp, product Beta-galactosidase
#   7 copies of 16S rRNA, each about 1,500 bp
#
# CHECKPOINT: in Week 3 we keep only one 16S copy per genome. Why the longest?


# -----------------------------------------------------------------------------
# STEP 7  Sanity-check the annotation  (lesson 2.5)
# -----------------------------------------------------------------------------
# Three tests: gene density (~1 gene per kb), share of hypothetical proteins,
# and rRNA/tRNA counts compared with what's known for this organism.

P=ecoli_k12/ecoli_k12
LEN=$(awk -F': ' '$1=="bases"{print $2}' $P.txt)
CDS=$(awk -F': ' '$1=="CDS"{print $2}' $P.txt)
RRNA=$(awk -F': ' '$1=="rRNA"{print $2+0}' $P.txt)
TRNA=$(awk -F': ' '$1=="tRNA"{print $2+0}' $P.txt)
HYPO=$(awk -F'\t' '$2=="CDS" && $7=="hypothetical protein"{n++} END{print n+0}' $P.tsv)
S16=$(awk -F'\t' '$7=="16S ribosomal RNA"{n++} END{print n+0}' $P.tsv)
awk -v len="$LEN" -v cds="$CDS" -v hypo="$HYPO" -v rrna="${RRNA:-0}" \
    -v trna="${TRNA:-0}" -v s16="$S16" 'BEGIN{
  printf "Genome length:        %d bp\n", len
  printf "Protein-coding genes: %d\n", cds
  printf "Genes per kb:         %.2f   (expect about 0.9-1.0)\n", cds/(len/1000)
  printf "Hypothetical:         %d (%.0f%% of CDS)\n", hypo, 100*hypo/cds
  printf "rRNA genes:           %d\n", rrna
  printf "16S copies:           %d   (expect 7 for E. coli)\n", s16
  printf "tRNA genes:           %d\n", trna
}'

# COMPARE WITH NCBI
# Open https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_000005845.2/
# and find "Annotation details". Write down NCBI's counts of protein-coding
# genes, rRNAs and tRNAs next to yours. Within a few percent is a good sign.
#
# CHECKPOINT: your project genomes won't come with a "right answer".
# Which of these three tests could you still run on them?


# -----------------------------------------------------------------------------
# STEP 8  Save your work to GitHub
# -----------------------------------------------------------------------------
# Your files stay in your codespace, but your portfolio is your GitHub repo.
# Large files (the downloaded genome, .gbk and others) are skipped
# automatically by the .gitignore file.

cd "$(git rev-parse --show-toplevel)"
git add week2
git commit -m "Week 2: annotate E. coli K-12 with Prokka"
git push
git status

# WHAT YOU SHOULD SEE
#   "Your branch is up to date with 'origin/main'"
#   Refresh your repo's page on GitHub: the week2 folder now has your results.
#
# Done for today? Stop your codespace to save free hours:
#   github.com/codespaces → ⋯ next to your codespace → Stop codespace


# =============================================================================
#  TROUBLESHOOTING
# =============================================================================
#  "command not found: prokka"
#      Open a new terminal. Still missing? tail -n 20 ~/brsp-setup.log
#      and send the output to your TA.
#
#  "fatal: not a git repository"
#      You're outside your repo folder. Run Step 1 again.
#
#  datasets download fails or hangs
#      NCBI is busy or the connection dropped. Wait a minute, retry Step 2.
#
#  "cp: ... _genomic.fna: No such file or directory"
#      The download or unzip didn't finish. Re-run Step 2.
#
#  Prokka log ends with ERROR
#      Read the reason:  tail -n 20 prokka_run.log
#      Check the input exists (ls -lh ecoli_k12.fna), then re-run Step 4.
#
#  "Could not parse version" in the Prokka log
#      Run this, then re-run Step 4:
#      export JAVA_TOOL_OPTIONS="-Xlog:disable -Xlog:all=warning:stderr"
#
#  The codespace stopped while Prokka was running
#      Reopen it from github.com/codespaces, run Step 1, then Step 4 again.
#
#  Step 7 shows "division by zero"
#      Prokka didn't finish, so the summary is empty. Check Step 4 first.
#
#  git push asks for a password or is rejected
#      Ask your TA. Codespaces normally handles this for you.
#
#  Still stuck? Post in the WhatsApp group with: which step, the exact error
#  (copy and paste), and what you already tried.
# =============================================================================
