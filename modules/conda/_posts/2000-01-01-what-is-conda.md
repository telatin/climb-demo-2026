---
title: "What is conda"
---

# Installing packages with Conda (and Mamba)

![Scheme of conda vs non-conda installation]({{ site.baseurl }}/{% link img/conda-env.png %})

A **Conda environment** is a separate workspace where you can install the exact versions of Python, R, and bioinformatics tools needed for a particular analysis. 
This is useful when different projects require **different or conflicting versions of the same software**: for example, one environment can use Python 3.12 while another uses Python 3.6, without the two interfering with each other. 

Conda environments also **help reproducibility**, because you can record and share which software versions were used in an analysis and recreate a similar environment on another computer. 
However, they do not guarantee perfect reproducibility, because they still depend on the underlying operating system and system libraries. 
For stronger isolation and reproducibility, **containers** such as Docker or Apptainer are usually preferred.

On CLIMB conda is pre-installed and you can use it. You can use:

* `mamba` to create a new environment
* `conda` to operate with environments (listing, activating, deactivating etc.)

*mamba* is a drop-in, faster replacement for *conda*, that can be used for creating environment in a faster way. 
*mamba* can also be configured to activate environments but this is not the default state on CLIMB.

:warning: On CLIMB, you cannot install new software to the `base` conda environment. You should not use it.

> See the [CLIMB documentation](https://docs.climb.ac.uk/4.Documentation/4.1.JupyterLab/4.1.7.conda/) on environments

## Creating a new environment

A typical command looks like:

```bash
mamba create -n myenv \
  "fastp>=1.0" visidata jq
```

Where:

- `-n NAME` specifies the name of the environment to create
- a list of dependencies that can be just a package name like `jq` or you can specify a specific version like `"fastp=1.1.0"` or greater or lower than, `"fastp>=1.1.0"`. Always quote version specifiers when using `<` or `>`!

Optionally:
- `--yes` (or `-y`) to skip the prompt Y/n to proceed. Consider that this will "accept" the solution and you will not have the chance of reviewing the versions of packages installed.
  
## Listing environments

```bash
conda env list
```

will produce something like

```text
# conda environments:
#
# * -> active
# + -> frozen
base                     /opt/conda
datasets                 /shared/team/conda/telatin.qib/datasets
denovo                   /shared/team/conda/telatin.qib/denovo
kraken                   /shared/team/conda/telatin.qib/kraken
nb_env                   /shared/team/conda/telatin.qib/nb_env
notebooks            *   /shared/team/conda/telatin.qib/notebooks
qc                       /shared/team/conda/telatin.qib/qc
```

## Activating an environment

```bash
conda activate myenv
```

Your shell prompt should update to show the active environment, e.g. `(myenv) jovyan@climb:~$`.

To leave the current environment and return to the previous one:

```bash
conda deactivate
```

:warning: Since you shouldn't use `base` on CLIMB, always `activate` a named environment before running any tool — otherwise commands may fail with `command not found` or silently use the wrong version.

## Python notebooks

If you are planning to prepare an environment for a Python notebook, you **must** add `ipykernel` as a dependency.

For example, to use "pandas" and "matplotlib" in a Python notebook:

```bash
mamba create -n nb_env \
  ipykernel pandas matplotlib-base
```

All conda environments that include `ipykernel` will be shown in the launcher:

![Python Notebook Launcher]({{ site.basename }}/{% link /img/env-list.png %})