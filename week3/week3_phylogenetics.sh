#!/usr/bin/env bash
# =============================================================================
#  BRSP Week 3: Building a Phylogenetic Tree from 16S rRNA
#  OmicsLite · Bioinformatics Research Starter Program · Codespaces version
# =============================================================================
#
#  WHERE WE ARE IN THE PIPELINE
#    Genome → Annotation (Week 2) → 16S extraction → Alignment → Tree → iTOL
#                                   ▲ this week covers all of these
#
#  THE QUESTION
#    Do these five bacteria cluster the way their taxonomy says they should?
#
#    Escherichia coli K-12          your Week 2 genome
#    Shigella flexneri 301          a famous "surprise" relative
#    Salmonella enterica LT2        a close relative
#    Klebsiella pneumoniae HS11286  a more distant relative
#    Pseudomonas aeruginosa PAO1    the OUTGROUP (a different order entirely)
#
#  The four relatives were already annotated with Prokka for you, using the
#  same settings as Week 2. Their gene sequences (.ffn) are in week3/data/.
#
#  HOW TO USE THIS FILE
#  - Copy ONE block at a time into the terminal, press Enter, and wait.
#    Shortcut: select lines → Ctrl+Shift+P → "Terminal: Run Selected Text
#    in Active Terminal".
#  - Compare your output with the "WHAT YOU SHOULD SEE" notes.
#
#  Time needed: about 45 minutes. Every step runs in seconds.
# =============================================================================


# -----------------------------------------------------------------------------
# STEP 1  Go to your Week 3 folder and check the tools
# -----------------------------------------------------------------------------

mkdir -p "$(git rev-parse --show-toplevel)/week3"
cd "$(git rev-parse --show-toplevel)/week3"
pwd
seqkit version
mafft --version
FastTree -expert 2>&1 | head -n 1

# WHAT YOU SHOULD SEE
#   /workspaces/<your-repo-name>/week3
#   seqkit v2.x, v7.5xx for MAFFT, and "FastTree Version 2.x"
#
# "command not found"? Your codespace was created before the Week 3 tools
# were added. Press Ctrl+Shift+P → "Codespaces: Rebuild Container", wait for
# it to finish, then start again from Step 1.


# -----------------------------------------------------------------------------
# STEP 2  Look at the example data
# -----------------------------------------------------------------------------
# .ffn files hold the DNA sequence of every gene Prokka found (Week 2, Step 5).
# The four relatives are compressed (.gz); seqkit reads them as they are.

ls -lh data/

# Your own E. coli genes from Week 2:
ls -lh ../week2/ecoli_k12/ecoli_k12.ffn

# How many 16S rRNA genes does each genome have?
for f in ../week2/ecoli_k12/ecoli_k12.ffn data/*.ffn.gz; do
  printf "%-45s %s\n" "$f" "$(seqkit grep -n -r -p '16S ribosomal RNA' "$f" | grep -c '>')"
done

# WHAT YOU SHOULD SEE
#   Four .ffn.gz files in data/, plus your Week 2 ecoli_k12.ffn.
#   Several 16S copies per genome (E. coli has 7). Bacteria often carry
#   multiple copies of their rRNA genes.
#
# "No such file" for ecoli_k12.ffn? Your Week 2 results aren't in this
# codespace. Re-run Week 2 Steps 2 and 4, then come back.


# -----------------------------------------------------------------------------
# STEP 3  Keep one 16S per genome  (lesson 3.3)
# -----------------------------------------------------------------------------
# A tree needs ONE comparable sequence per organism. We pick the LONGEST 16S
# copy (most likely to be full length) and rename it to the species name,
# so the tree shows "Escherichia_coli_K12" instead of "ECOLI_04012".
#
# First E. coli, one command at a time, so you can see what each part does:

# 3a. Find all 16S genes (-n: search the full header, -r: allow partial match)
seqkit grep -n -r -p "16S ribosomal RNA" ../week2/ecoli_k12/ecoli_k12.ffn > ecoli_16S_all.fasta
seqkit stats ecoli_16S_all.fasta

# 3b. Sort them longest first, keep the first one, rename it
seqkit sort --quiet --by-length --reverse ecoli_16S_all.fasta \
  | seqkit head -n 1 \
  | seqkit replace -p '.+' -r 'Escherichia_coli_K12' > Escherichia_coli_K12_16S.fasta
seqkit stats Escherichia_coli_K12_16S.fasta
head -n 2 Escherichia_coli_K12_16S.fasta

# WHAT YOU SHOULD SEE
#   3a: 7 sequences, each about 1,500 bp
#   3b: 1 sequence, about 1,540 bp, with the header >Escherichia_coli_K12

# Now the same three steps for the four relatives, in one loop:
for pair in \
  "shigella_flexneri_301:Shigella_flexneri_301" \
  "salmonella_enterica_LT2:Salmonella_enterica_LT2" \
  "klebsiella_pneumoniae_HS11286:Klebsiella_pneumoniae_HS11286" \
  "pseudomonas_aeruginosa_PAO1:Pseudomonas_aeruginosa_PAO1"; do
  file="${pair%%:*}"; label="${pair##*:}"
  seqkit grep -n -r -p "16S ribosomal RNA" "data/$file.ffn.gz" \
    | seqkit sort --quiet --by-length --reverse \
    | seqkit head -n 1 \
    | seqkit replace -p '.+' -r "$label" > "${label}_16S.fasta"
done
ls *_16S.fasta

# CHECKPOINT: why do we need exactly one sequence per organism?


# -----------------------------------------------------------------------------
# STEP 4  Combine the five 16S sequences
# -----------------------------------------------------------------------------

cat Escherichia_coli_K12_16S.fasta Shigella_flexneri_301_16S.fasta \
    Salmonella_enterica_LT2_16S.fasta Klebsiella_pneumoniae_HS11286_16S.fasta \
    Pseudomonas_aeruginosa_PAO1_16S.fasta > all_16S.fasta
seqkit fx2tab -n -l all_16S.fasta

# WHAT YOU SHOULD SEE
#   Five names, each with a length of about 1,500 bp.
#   If a line is missing or shows 0, that genome's 16S wasn't found:
#   check Step 3.


# -----------------------------------------------------------------------------
# STEP 5  Align with MAFFT  (lesson 3.4)
# -----------------------------------------------------------------------------
# Alignment lines up the five sequences so that each column holds the
# "same" position in every organism, inserting gaps (-) where one sequence
# has extra or missing bases. Only then can we compare them position by
# position.

mafft --auto all_16S.fasta > aligned_16S.fasta 2> mafft.log
seqkit fx2tab -n -l aligned_16S.fasta

# WHAT YOU SHOULD SEE
#   The same five names, now ALL with the SAME length (a bit longer than
#   before, because of the gaps). Equal lengths = a valid alignment.
#   MAFFT writes the letters in lowercase (a, c, g, t). That's normal.
#
# Look at a stretch of the alignment, 60 columns from position 1000:
seqkit subseq --quiet -r 1000:1060 aligned_16S.fasta | seqkit seq -w 0

# CHECKPOINT: in the stretch above, which organism differs most from the
# others? Does that fit its role as the outgroup?


# -----------------------------------------------------------------------------
# STEP 6  Build the tree with FastTree  (lesson 3.5)
# -----------------------------------------------------------------------------
#   -nt    the sequences are nucleotides (DNA), not protein
#   -gtr   use the GTR model of how DNA changes over time
#
# FastTree writes the tree in Newick format: nested brackets of names and
# branch lengths, with support values (0-1) after each closing bracket.

FastTree -nt -gtr aligned_16S.fasta > tree_16S.nwk 2> fasttree.log
cat tree_16S.nwk

# WHAT YOU SHOULD SEE
#   One line of brackets, names and numbers, ending with ";". For example:
#   (Escherichia_coli_K12:0.002,Shigella_flexneri_301:0.003,(Salmonella_...
#
#   Don't worry if Pseudomonas looks grouped with another organism here.
#   FastTree makes an UNROOTED tree: it shows who is close to whom, but not
#   where the tree starts. You fix that by rooting it on the outgroup in Step 7.
#
# CHECKPOINT: the numbers right after ")" are support values. What would a
# value of 0.4 tell you about that group?


# -----------------------------------------------------------------------------
# STEP 7  Visualise in iTOL  (lesson 3.6)
# -----------------------------------------------------------------------------
# 1. In the file list on the left, open week3, right-click tree_16S.nwk
#    and choose Download.
# 2. Go to https://itol.embl.de and click Upload. (You can upload without an
#    account; a free account lets you save trees.)
# 3. Upload tree_16S.nwk.
# 4. ROOT THE TREE: click the Pseudomonas_aeruginosa_PAO1 label →
#    Tree structure → Reroot the tree here.
# 5. Show support values: Control panel (right) → Advanced → Bootstrap /
#    metadata → Display → "Text".
# 6. Export: Control panel → Export → PNG. Save it as tree_16S.png and
#    upload it into your week3 folder (drag it onto the folder on the left).
#
# WHAT YOU SHOULD SEE (after rooting)
#   Pseudomonas on its own branch, then Klebsiella, then Salmonella, then
#   E. coli and Shigella together as the closest pair.


# -----------------------------------------------------------------------------
# STEP 8  Interpret the tree  (lesson 3.7)
# -----------------------------------------------------------------------------
# Write short answers in a file called week3/interpretation.md:
#
#  1. Which organism is closest to E. coli K-12? Is that what you expected
#     from their names?
#  2. Shigella is a separate genus by name, yet sits right next to (or even
#     inside) E. coli. Look up why. Is this a problem with the tree, or with
#     the names?
#  3. Look at the support value for the E. coli + Shigella group, and the
#     branch length between them. Can 16S tell these two apart well?
#  4. Why did we need Pseudomonas at all? What would go wrong without an
#     outgroup?
#  5. Name one limitation of building a tree from a single gene.
#
# Create the file and open it in the editor:
touch interpretation.md
code interpretation.md 2> /dev/null || echo "Open week3/interpretation.md from the file list on the left."


# -----------------------------------------------------------------------------
# STEP 9  Save your work to GitHub
# -----------------------------------------------------------------------------

cd "$(git rev-parse --show-toplevel)"
git add week3
git commit -m "Week 3: 16S tree of E. coli and relatives"
git push
git status

# WHAT YOU SHOULD SEE
#   "Your branch is up to date with 'origin/main'"
#
# Done for today? Stop your codespace: github.com/codespaces → ⋯ → Stop.


# =============================================================================
#  TROUBLESHOOTING
# =============================================================================
#  "command not found: seqkit" (or mafft, FastTree)
#      Rebuild your codespace: Ctrl+Shift+P → "Codespaces: Rebuild Container".
#
#  "No such file" for data/*.ffn.gz
#      Your repo was made before the example data was added. Ask your TA
#      for the files, or download them from the BRSP template repo.
#
#  A *_16S.fasta file is empty
#      Check the file name in the Step 3 loop matches the name in data/.
#
#  Step 5: sequences have different lengths after MAFFT
#      MAFFT didn't finish. Read the reason: tail mafft.log
#
#  Step 6: tree_16S.nwk is empty
#      Read the reason: tail fasttree.log
#      Usually the alignment is empty because an earlier step failed.
#
#  iTOL won't accept the file
#      Make sure you uploaded tree_16S.nwk, not the .fasta files.
#
#  Still stuck? Post in the WhatsApp group with: which step, the exact error
#  (copy and paste), and what you already tried.
# =============================================================================
