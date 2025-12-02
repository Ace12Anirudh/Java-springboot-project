[
"#!/bin/bash",
"set -ex",
"yum update -y",
"yum install -y git",
"# allow agent forwarding via ssh? (keep default)",
"# Bastion is minimal; use it as SSH jump host."
]
