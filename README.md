## simp-tpm2-simulator


## Description

This project builds and packages newer versions of TPM 2.0 simulator for testing
purposes.  It is a repackage of the upstream IBM's Software TPM 2.0 source code.

### This is a SIMP project

This module is a component of the [System Integrity Management
Platform][simp]
a compliance-management framework built on Puppet.

If you find any issues, please submit them to our [bug tracker][simp-jira].

## Setup

### Setup Requirements

The TPM 2.0 simulator requires EL7. To build rpm files to install the TPM 2.0 
simulator, install this package and update the configuration files, namely
`things_to_build.yaml` and `simp-tpm2-simulator.spec`, as necessary.  Then build
and package the simulator with the command `bundle exec rake pkg:rpm` from with
the simp-tpm2-simulator directory.

### Beginning with simp-tpm2-simulator

The TPM 2.0 simulator relies upon a few rpm packages which should be
installed on any target system intended to use the module. The packages are
tpm2-tools, tpm2-tss, and tpm2-abrmd, a suite of tools supporting the TPM 2.0. 

## Usage

To install the rpm, copy the rpm file to the target system and install it
with the command:

```yaml
yum localinstall simp-tpm2-simulator-*.rpm
```

This will install the simulator programs to utilize the TPM 2.0 simulator.

To initialize and use the TPM simulator, issue the following commands:

```yaml
# runuser tpm2sim --shell /bin/sh -c "cd /tmp; nohup \
  /usr/local/bin/tpm2-simulator &> /tmp/tpm2-simulator.log &" 
# mkdir -p /etc/systemd/system/tpm2-abrmd.service.d
# printf "[Service]\nExecStart=\nExecStart=/sbin/tpm2-abrmd -t socket" \
  > /etc/systemd/system/tpm2-abrmd.service.d/override.conf
# systemctl daemon-reload
# systemctl start tpm2-abrmd
```

[simp]: https://github.com/NationalSecurityAgency/SIMP/
[simp-jira]: https://simp-project.atlassian.net/

