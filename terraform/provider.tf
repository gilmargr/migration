provider "opc" {
    user            = "${var.user}"
    password        = "${var.password}"
    identity_domain = "${var.domain}"
    endpoint = "https://compute.brcom-central-1.oraclecloud.com"
}
