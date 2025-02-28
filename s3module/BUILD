# Terraform init build targets
filegroup(
    name = "tf_source",
    srcs = glob([
        "*.tf",
        "module.version",
    ]),
    visibility = ["PUBLIC"],
)

# Terraform format
gentest(
    labels = ["lint"],
    name = "fmt",
    no_test_output = True,
    srcs = [":tf_source"],
    test_cmd = f"tfswitch {CONFIG.TERRAFORM_VERSION} && terraform --version && terraform fmt -check -recursive -diff=true",
    test_tools = ["//third_party/terraform:terraform"],
)

# Terraform format
gentest(
    labels = ["lint"],
    name = "tflint",
    no_test_output = True,
    srcs = [":tf_source"],
    test_cmd = f"$(exe tflint) ./",
)