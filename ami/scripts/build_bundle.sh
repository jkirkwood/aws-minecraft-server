#!/bin/bash

# This script gzips the ../bundle directory so it can be copied over to the
# build server

# Clean up special files left by MacOS
find . -name '.DS_Store' -type f -delete
# COPYFILE_DISABLE=1 prevents ._* files from being put in the archive.
# This is another stupid MacOS thing.
COPYFILE_DISABLE=1 tar -C ./bundle -czf ./bundle.tar.gz .