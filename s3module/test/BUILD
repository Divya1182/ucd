filegroup(
    name = "go_src",
    srcs = glob([
        '*.go',
        'go.mod',
        'go.sum',
    ])
)

sh_test(
    data = [
        ":go_src",
        "//:tf_source",
        "//examples:tf_src",
    ],
    labels = ["unit"],
    name = "run_all_terratest",
    src = "test_all.sh",
)
