# This says that all targets in this package that don't specify otherwise
# will be visible to the whole repo.
# This is often useful for third-party packages like this where we expect
# anyone to use them.
package(default_visibility = ['PUBLIC'])

go_module(
    deps = [
        ':awssdk',
        ':copier',
        ':crypto',
        ':errors',
        ':go-multierror',
        ':mysql',
        ':net',
        ':otp',
        ':testify',
        ':uuid',
    ],
    install = [
        'modules/aws',
        'modules/collections',
        'modules/files',
        'modules/logger',
        'modules/random',
        'modules/retry',
        'modules/shell',
        'modules/ssh',
        'modules/terraform',
        'modules/testing',
    ],
    module = 'github.com/gruntwork-io/terratest',
    name = 'terratest',
    test_only = True,
    version = 'v0.32.0',
)

go_module(
    deps = [
        ':go-jmespath',
        ':net',
    ],
    install = [
        'aws',
        'aws/...',
        'service/...',
        'internal/...',
        'models/...',
        'private/...',
    ],
    module = 'github.com/aws/aws-sdk-go',
    name = 'awssdk',
    test_only = True,
    version = 'v1.36.32',
)

go_module(
    name = 'go-jmespath',
    module = 'github.com/jmespath/go-jmespath',
    version = 'v0.4.0',
    test_only = True,
)

go_module(
    name = 'mysql',
    module = 'github.com/go-sql-driver/mysql',
    version = 'v1.5.0',
    test_only = True,
)

go_module(
    name = 'uuid',
    module = 'github.com/google/uuid',
    version = 'v1.2.0',
    test_only = True,
)

go_module(
    deps = [
        ':goerrors',
        ':urfave-cli',
    ],
    name = 'errors',
    module = 'github.com/gruntwork-io/gruntwork-cli',
    install = [
        'errors',
    ],
    test_only = True,
    version = 'v0.7.2',
)

go_module(
    deps = [
        ':errwrap',
    ],
    name = 'go-multierror',
    module = 'github.com/hashicorp/go-multierror',
    version = 'v1.1.0',
    test_only = True,
)

go_module(
    deps = [
        ':barcode',
    ],
    name = 'otp',
    module = 'github.com/pquerna/otp',
    install = [
        '.',
        'hotp',
        'totp',
    ],
    version = 'v1.3.0',
    test_only = True,
)

go_module(
    deps = [
        ':yamlv3',
        ':go-spew',
        ':difflib',
    ],
    install = [
        'assert',
        'require',
    ],
    module = 'github.com/stretchr/testify',
    name = 'testify',
    test_only = True,
    version = 'v1.7.0',
)

go_module(
    deps = [
        ':net',
        ':sys',
        ':term',
    ],
    name = 'crypto',
    module = 'golang.org/x/crypto',
    install = [
        '...',
    ],
    test_only = True,
    version = 'v0.0.0-20201221181555-eec23a3978ad',
)

go_module(
    deps = [
        ':text',
    ],
    name = 'net',
    module = 'golang.org/x/net',
    install = [
        'context',
        'http2',
    ],
    test_only = True,
    version = 'v0.0.0-20210129194117-4acb7895a057',
)

go_module(
    name = 'barcode',
    module = 'github.com/boombuler/barcode',
    install = [
        '.',
        'qr',
        'utils',
    ],
    version = 'v1.0.1',
    test_only = True,
)

go_module(
    name = 'errwrap',
    module = 'github.com/hashicorp/errwrap',
    version = 'v1.1.0',
    test_only = True,
)

go_module(
    name = 'goerrors',
    module = 'github.com/go-errors/errors',
    version = 'v1.1.0',
    test_only = True,
)

go_module(
    deps = [
        ":md2man",
    ],
    name = 'urfave-cli',
    module = 'github.com/urfave/cli',
    version = 'v1.22.2',
    test_only = True,
)

go_module(
    name = 'go-spew',
    module = 'github.com/davecgh/go-spew',
    install = [
        'spew',
    ],
    version = 'v1.1.1',
    test_only = True,
)

go_module(
    name = 'difflib',
    module = 'github.com/pmezard/go-difflib',
    install = [
        'difflib'
    ],
    version = 'v1.0.0',
    test_only = True,
)

go_module(
    name = 'yamlv3',
    module = 'gopkg.in/yaml.v3',
    test_only = True,
    version = 'v3.0.0-20200313102051-9f266ea9e77c',
)

go_module(
    deps = [
        ":blackfriday",
    ],
    install = [
        'md2man',
    ],
    module = 'github.com/cpuguy83/go-md2man/v2',
    name = 'md2man',
    test_only = True,
    version = 'v2.0.0',
)

go_module(
    name = 'blackfriday',
    module = 'github.com/russross/blackfriday/v2',
    version = 'v2.1.0',
    test_only = True
)

go_module(
    name = 'copier',
    module = 'github.com/jinzhu/copier',
    version = 'v0.2.3',
    test_only = True
)

go_module(
    name = 'text',
    module = 'golang.org/x/text',
    install = [
        'secure',
        'unicode',
    ],
    test_only = True,
    version = 'v0.3.5',
)

go_module(
    deps = [
        ':sys',
    ],
    install = [
        '...'
    ],
    module = 'golang.org/x/term',
    name = 'term',
    test_only = True,
    version = 'v0.0.0-20201210144234-2321bbc49cbf',
)

go_module(
    install = [
        '...',
    ],
    module = 'golang.org/x/sys',
    name = 'sys',
    test_only = True,
    version = 'v0.0.0-20210124154548-22da62e12c0c',
)
