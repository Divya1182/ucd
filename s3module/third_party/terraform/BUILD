genrule(
    binary = True,
    cmd = f"tfswitch {CONFIG.TERRAFORM_VERSION} && cp {CONFIG.TF_SWITCH_DIR}/* .terraform.versions",
    name = "terraform",
    out = f".terraform.versions/terraform_{CONFIG.TERRAFORM_VERSION}",
    visibility = ["PUBLIC"],
)
