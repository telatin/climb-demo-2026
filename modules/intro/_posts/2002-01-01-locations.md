---
title: "Locations"
---

> Check the docs: [CLIMB documentation on storage](https://docs.climb.ac.uk/4.Documentation/4.2.Storage/4.2.1.storage/)


## Home directory

In Unix, the home directory...

On CLIMB, on the other hand, the home directory is very small and is not meant to be used to store any file, except configuration files and other small files.

## Shared team

A directory shared with all team members, providing fast storage for:
* your files
* your analyses
* your databases...

It is configured to automatically store:
* your conda/mamba environments
* your Nextflow temporary files


You can access it from `/shared/team/` (or from the shortcut in your home: `~/shared-team`)


### Shared public

A read-only storage where CLIMB shares databases commonly used in microbial genomics. 

You can explore it from `/shared/public/`

### S3 Buckets

An interesting feature of CLIMB is the native support of [S3 compatible buckets](https://docs.climb.ac.uk/4.Documentation/4.2.Storage/4.2.2.s3-buckets/).
A bucket is a collection of files.

You can create and manage your buckets from the [Bryn interface](https://docs.climb.ac.uk/3.Getting-started/3.3.bryn/).

You can read and write to buckets using Nextflow pipelines.