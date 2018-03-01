# Invoke-CleanDriverStore

This PowerShell module is designed to be run against a folder that contains either OEM drivers or an export from a known good system.

## Goals
The goal of this module is to prune a driver share to as small as possible that can then later be imported and used within MDT and/or SCCM. In initial testing the size of an export from a good system was 700MB and was decreased to under 17.5MBs.