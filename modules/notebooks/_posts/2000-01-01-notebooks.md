---
title: Python notebooks in JupyterLab
---

# Python notebooks

Jupyter notebooks are documents that combine text, code and the output of that
code. They are useful for exploratory bioinformatics because we can keep the
analysis and the explanation together. We can run one small piece of Python,
inspect the result, and then change the code without rerunning an entire
pipeline.

![JupyterLab interface]({{ site.baseurl }}{% link img/python-notebook.png %})

In this example we will use JupyterLab to explore a table of microbial
abundance counts. 
We will start with a simple pandas notebook and then use a
second notebook to make plots. 

The important part is not only the Python
syntax: we will also learn how JupyterLab finds files and how it chooses the
Python environment that runs our code.

