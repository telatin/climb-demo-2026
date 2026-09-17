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


:bulb: similarily, you can create R notebooks installing `r-irkernel` and any r or bioconductor library you should need.

## **Q&A**

### **Can I add a package to an existing environment?**

Yes. If the new package is compatible with the packages already installed, you can add it to an existing environment.

There are two common ways to do this.

1. Activate the environment first:

```bash
conda activate my_env
mamba install DEPENDENCY_NAME
```

2. Specify the environment directly:

```bash
mamba install -n my_env DEPENDENCY_NAME
```

In both cases, `mamba` will check whether the new package can be installed together with the packages already present in the environment.

---

### **Can I export an environment?**

Yes.

A Conda environment contains the package you explicitly requested, for example `kraken2`, together with the additional libraries and dependencies that it needs to run.

You can export the environment definition to a YAML file:

```bash
# Run this inside the Conda environment
conda env export > my_conda_env.yaml
```

The resulting file contains the packages and versions installed in the environment.

You can later use it as a record of the software environment, or as a starting point for recreating it:

```bash
conda env create -f my_conda_env.yaml
```

This is useful for reproducibility, although it does not guarantee that the environment can always be recreated exactly on every operating system or at any point in the future.

---

### **Can I install all packages in the same environment?**

Sometimes, but this is usually not a good idea.

Some packages may be incompatible because they require different versions of the same dependency. For example, one tool may require an older version of a library while another requires a newer one.

Even when all packages are compatible, a very large environment can become difficult to manage. Installing or updating one package may also affect other packages in the same environment.

There are two useful strategies.

1. **Create environments per task**

For example:

```text
qc
assembly
mapping
taxonomy
```

This keeps environments relatively small and allows you to reuse the same set of tools for similar tasks.

For example, a `qc` environment could contain tools such as `fastp`, `fastplong` and `NanoPlot`.

This approach is particularly convenient for common preprocessing steps.

2. **Create environments per analysis or project**

For example:

```text
ecoli_outbreak_2024
```

This keeps the software used for a particular analysis together.

It can be useful for downstream analyses, where you may want a specific collection of Python or R libraries to remain associated with one project.
