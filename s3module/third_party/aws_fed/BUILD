filegroup(
    name = "aws_fed",
    srcs = [
        "aws-fed.toml",
    ],
    visibility = ["PUBLIC"],
)

sh_binary(
    deps = [":aws_fed"],
    main = "federate.sh",
    name = "federate",
)
