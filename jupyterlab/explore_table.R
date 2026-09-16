#!/usr/bin/env Rscript
# ==============================================================================
# explore_table.R
# ------------------------------------------------------------------------------
# A simple exploration of the abundance table "table.tsv" using the tidyverse.
#
# The input table has:
#   - one row per taxon, labeled with its full taxonomic lineage
#     (e.g. "k__Bacteria,p__Firmicutes,...,g__Lactobacillus")
#   - one column per sample (sequencing runs named "ERR...")
#   - raw abundance counts as values
#
# What this script does:
#   1. Imports the table
#   2. Reshapes it to tidy ("long") format and parses the taxonomy
#   3. Explores it: library sizes, dominant taxa, phylum/genus summaries
#   4. Produces three plots, saved as PNG files in the working directory:
#        - plot_library_size.png  : total counts per sample (log scale)
#        - plot_top_genera.png    : top 10 genera by total abundance
#        - plot_composition.png   : top 8 genera, relative abundance per sample
#
# Usage:  Rscript explore_table.R
# ==============================================================================

library(tidyverse)

# ------------------------------------------------------------------------------
# 1. Import -------------------------------------------------------------------
# ------------------------------------------------------------------------------
# read_tsv() parses the tab-separated file. The first column is called
# "#Taxon" in the header, so we rename it to "Taxon" right away.
counts <- read_tsv("table.tsv") |>
  rename(Taxon = `#Taxon`)

cat("Table dimensions:", nrow(counts), "taxa x", ncol(counts) - 1, "samples\n")

# ------------------------------------------------------------------------------
# 2. Tidy the data -------------------------------------------------------------
# ------------------------------------------------------------------------------
# For most analyses (and for ggplot2) it is convenient to have one row per
# (taxon, sample) combination: this is the "long" or "tidy" format.
# pivot_longer() stacks all sample columns into two new columns:
# "Sample" (former column name) and "Count" (the value).
tidy_counts <- counts |>
  pivot_longer(
    cols = -Taxon,
    names_to = "Sample",
    values_to = "Count"
  )

# The row labels are full lineage strings. We extract the rank prefixes
# (p__ = phylum, g__ = genus, ...) with regular expressions:
#   str_extract(Taxon, "g__[^,]+")  finds the "g__Genus" token,
#   str_remove(..., "g__")          strips the prefix,
#   replace_na(...)                 gives a label to rows without the rank
#                                   (e.g. the "u__unclassified" row).
tidy_counts <- tidy_counts |>
  mutate(
    Phylum = str_extract(Taxon, "p__[^,]+") |> str_remove("p__") |>
      replace_na("unclassified"),
    Genus  = str_extract(Taxon, "g__[^,]+") |> str_remove("g__") |>
      replace_na("unclassified")
  )

cat("Tidy table:", nrow(tidy_counts), "rows (taxon x sample combinations)\n")
cat("Nonzero records:", sum(tidy_counts$Count > 0), "\n\n")

# ------------------------------------------------------------------------------
# 3. Exploration ---------------------------------------------------------------
# ------------------------------------------------------------------------------

# 3a. Library size: total counts per sample. Samples differ a lot in sequencing
#     depth, which matters when comparing them (hence relative abundances below).
library_sizes <- tidy_counts |>
  summarise(Total = sum(Count), .by = Sample) |>
  arrange(desc(Total))

cat("== Library sizes (total counts per sample) ==\n")
print(library_sizes |> slice_head(n = 5))
cat("Min:", min(library_sizes$Total),
    " Max:", max(library_sizes$Total),
    " Median:", median(library_sizes$Total), "\n\n")

# 3b. Composition by phylum: collapse all taxa of the same phylum.
by_phylum <- tidy_counts |>
  summarise(Total = sum(Count), .by = Phylum) |>
  arrange(desc(Total)) |>
  mutate(Percent = round(100 * Total / sum(Total), 2))

cat("== Total abundance by phylum ==\n")
print(by_phylum)
cat("\n")

# 3c. Top 10 genera by total abundance across all samples.
top_genera <- tidy_counts |>
  summarise(Total = sum(Count), .by = Genus) |>
  arrange(desc(Total)) |>
  slice_head(n = 10)

cat("== Top 10 genera ==\n")
print(top_genera)
cat("\n")

# ------------------------------------------------------------------------------
# 4. Plots ---------------------------------------------------------------------
# ------------------------------------------------------------------------------
# In a script (unlike a notebook) plots must be saved explicitly: ggsave()
# writes the last ggplot object to a file.

# 4a. Library size per sample (log scale, since totals span >2 orders of
#     magnitude and small samples would otherwise be invisible).
p1 <- ggplot(library_sizes, aes(x = reorder(Sample, Total), y = Total)) +
  geom_col(fill = "steelblue") +
  scale_y_log10() +
  labs(
    title = "Library size per sample",
    x = NULL,
    y = "Total counts (log10 scale)"
  ) +
  theme_minimal(base_size = 10) +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, size = 6))
ggsave("plot_library_size.png", p1, width = 10, height = 5, dpi = 150)

# 4b. Top 10 genera by total abundance. reorder() + fct_rev() sort the
#     horizontal bars so the most abundant genus appears on top.
p2 <- ggplot(top_genera, aes(x = reorder(Genus, Total), y = Total)) +
  geom_col(fill = "darkorange") +
  coord_flip() +
  labs(
    title = "Top 10 genera by total abundance",
    x = NULL,
    y = "Total counts (all samples)"
  ) +
  theme_minimal(base_size = 11)
ggsave("plot_top_genera.png", p2, width = 7, height = 5, dpi = 150)

# 4c. Relative abundance of the top 8 genera per sample (stacked bars).
#     Converting counts to percentages removes the effect of unequal
#     sequencing depth and makes community composition comparable.
top8 <- top_genera$Genus[1:8]

composition <- tidy_counts |>
  mutate(RelAbundance = 100 * Count / sum(Count), .by = Sample) |>
  filter(Genus %in% top8) |>
  # Sort genera in the legend by overall abundance
  mutate(Genus = factor(Genus, levels = rev(top8)))

p3 <- ggplot(composition, aes(x = Sample, y = RelAbundance, fill = Genus)) +
  geom_col(width = 0.9) +
  labs(
    title = "Top 8 genera: relative abundance per sample",
    x = NULL,
    y = "Relative abundance (%)",
    fill = NULL
  ) +
  theme_minimal(base_size = 10) +
  theme(
    axis.text.x = element_text(angle = 90, vjust = 0.5, size = 6),
    legend.position = "right"
  )
ggsave("plot_composition.png", p3, width = 12, height = 5, dpi = 150)

cat("Plots saved: plot_library_size.png, plot_top_genera.png, plot_composition.png\n")
