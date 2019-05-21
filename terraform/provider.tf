provider "opc" {
    user            = "${var.user}"
    password        = "${var.password}"
    identity_domain = "${var.domain}"
    endpoint = "${var.endpoint}"
}
