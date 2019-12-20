## simp-tpm2-simulator

<!-- vim-markdown-toc GFM -->

* [Overview](#overview)
  * [This is a SIMP project](#this-is-a-simp-project)
* [Setup](#setup)
  * [Requirements](#requirements)
  * [Building the `simp-tpm2-simulator` RPM](#building-the-simp-tpm2-simulator-rpm)
  * [Beginning with simp-tpm2-simulator](#beginning-with-simp-tpm2-simulator)
* [Usage](#usage)
* [Development](#development)

<!-- vim-markdown-toc -->

## Overview

Rake and config files to build/package newer versions of the [IBM TPM 2.0
simulator][ibmswtpm2] as an EL7 or EL8 RPM.

### This is a SIMP project

This module is a (development) component of the [System Integrity Management
Platform][simp], a compliance-management framework built on Puppet.

If you find any issues, please submit them to our [bug tracker][simp-jira].

## Setup

### Requirements

The TPM 2.0 simulator build process requires:

* An EL7 or EL8 host with:
  - `rpm`
  - `tar`
  - `curl` (for direct downloads)
  - `rpm-build`
* Ruby 2.1+ with RubyGems.
* [bundler][bundler] 1.14+


To build rpm files to install the TPM 2.0 simulator, install this package and
update the configuration files, namely `things_to_build.yaml` and
`simp-tpm2-simulator.spec`, as necessary.

### Building the `simp-tpm2-simulator` RPM

To build the `simp-tpm2-simulator` RPM:

```sh
# Use bundler to install all necessary gems (https://bundler.io)
bundle install

# change to the project directory:
cd simp-tpm2-simulator/

# Download source + build the RPM
bundle exec rake pkg:rpm

# The RPM will be in the dist/ directory
ls -l dist/*.rpm
```

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
# runuser simp-tpm2-sim --shell /bin/sh -c "cd /tmp; nohup \
  /usr/local/bin/simp-tpm2-simulator &> /tmp/simp-tpm2-simulator.log &"
# mkdir -p /etc/systemd/system/tpm2-abrmd.service.d
On EL7 systems:
# printf "[Service]\nExecStart=\nExecStart=/sbin/tpm2-abrmd -t socket" \
  > /etc/systemd/system/tpm2-abrmd.service.d/override.conf
On EL8 systems:
# printf "[Service]\nExecStart=\nExecStart=/sbin/tpm2-abrmd --tcti mssim" \
  > /etc/systemd/system/tpm2-abrmd.service.d/override.conf
# systemctl daemon-reload
# systemctl start tpm2-abrmd
```

On systems using SELinux (for example, check with the getenforce utility) the
default service policy is too restrictive. See INSTALL.md at [TPM2 Access Broker
& Resource Management Daemon][tpm2-abrmd] for more details.


## Development

Please read our [Contribution Guide](http://simp-doc.readthedocs.io/en/stable/contributors_guide/index.html).

[bundler]:    https://bundler.io
[simp]:       https://www.simp-project.com/
[simp-jira]:  https://simp-project.atlassian.net/
[ibmswtpm2]:  https://sourceforge.net/projects/ibmswtpm2/
[tpm2-abrmd]: https://github.com/tpm2-software/tpm2-abrmd
