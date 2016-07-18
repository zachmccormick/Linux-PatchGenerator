[![Get help on Codementor](https://cdn.codementor.io/badges/get_help_github.svg)](https://www.codementor.io/zachmccormick?utm_source=github&utm_medium=button&utm_term=zachmccormick&utm_campaign=github)

PatchGenerator
==============

A self-extracting patcher.  To generate a patch, requires a clean source tree and a modified one.  Uses GNU and/or BSD tools.

To use
======

Run `./generatepatch.sh /full/path/to/original/source/tree/root /full/path/to/modified/source/tree/root`

This will generate patch.sh.

To patch
========

Copy patch.sh to the root directory of a clean source tree and run `./patch`.

To revert
=========

Copy patch.sh to the root directory of an already patched source tree and run `./patch --revert`.  The original patching process generates `*.orig` files that will be restored after deleting patched binaries.

Repo Pull Requests
==================

If you have any suggestions to make this better or more flexible (i.e. if you can figure out a better way than using full paths to generate the patch, and all of my --strip-components and `cut` commands, let me know!)
