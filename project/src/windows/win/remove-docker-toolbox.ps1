# https://github.com/docker/for-win/issues/1746#issuecomment-384940428
[Environment]::SetEnvironmentVariable("DOCKER_CERT_PATH", $null, "User")
[Environment]::SetEnvironmentVariable("DOCKER_HOST", $null, "User")
[Environment]::SetEnvironmentVariable("DOCKER_MACHINE_NAME", $null, "User")
[Environment]::SetEnvironmentVariable("DOCKER_TLS_VERIFY", $null, "User")
[Environment]::SetEnvironmentVariable("DOCKER_TOOLBOX_INSTALL_PATH", $null, "User")
