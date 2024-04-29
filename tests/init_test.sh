function create_gerrit_repo() {
    local repo=$1
    local default_branch=$2

    mkdir "${repo}"
    pushd "${repo}" >/dev/null
    git init --quiet -b ${default_branch}
    echo "Repo ${repo} with default branch ${default_branch}" > README.md
    git add README.md
    git commit --quiet -am "Initial commit"
    popd >/dev/null
}

# Called prior to running all tests
function set_up_before_script()
{
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    export PATH="${SCRIPT_DIR}/..:${PATH}"

    # Mock Gerrit with mock repos
    declare -g GERRIT=/tmp/gerrit
    if [ ! -d "${GERRIT}" ]
    then
        mkdir "${GERRIT}"
    fi
    pushd "${GERRIT}" >/dev/null
    rm -rf *

    create_gerrit_repo repo1 main #>& /dev/null
    create_gerrit_repo repo2 master #>& /dev/null
    create_gerrit_repo repo3 dev #>& /dev/null

    popd >/dev/null
}


# Run prior to each test case
function set_up()
{
    # Working directory
    declare -g WORK=/tmp/test-git-gerrit

    rm -rf "${WORK}"
    mkdir -p "${WORK}"
    cd "${WORK}"
}

# Run after each test case
function tear_down()
{
    rm -rf "${WORK}"
}


# Auxiliary functions


# Clones and inits a repo, with option args to 'git gerrit init'
# cd's into the cloned repository
function _init_repo()
{
    local repo=$1
    shift

    git clone "${GERRIT}/${repo}" 2> /dev/null
    cd "${repo}"
    git config gerrit.url "${GERRIT}"
    git ger init "$@"
    assert_exit_code
}

# Multi-invoker functions.
function main_master_repos() {
    run_test repo1 main
    run_test repo2 master
}

function all_repos() {
    main_master_repos
    run_test repo3 dev
}


# Test functions follow


# multi_invoker main_master_repos
function test_raw_init()
{
    local repo=$1
    local default_branch=$2

    _init_repo ${repo}
    assert_equals "$(git remote get-url gerrit)" "${GERRIT}/${repo}"
    assert_equals "$(cat .git/git-gerrit/default_branch)" "${default_branch}"
}

# multi_invoker all_repos
function test_init_dash_b()
{
    local repo=$1
    local default_branch=$2

    _init_repo ${repo} -b ${default_branch}
    assert_equals "$(git remote get-url gerrit)" "${GERRIT}/${repo}"
    assert_equals "$(cat .git/git-gerrit/default_branch)" "${default_branch}"
}

# multi_invoker all_repos
function test_start_from_default_branch()
{
    local repo=$1
    local default_branch=$2

    _init_repo ${repo} -b ${default_branch}

    git ger start work

    [ "$(git rev-parse --abbrev-ref HEAD)" = "work" ] || \
        fail "Didn't change to local branch 'work'!"
    assert_equals "refs/heads/${default_branch}" \
        "$(git for-each-ref --format '%(upstream)' refs/heads/work)"
}

# multi_invoker all_repos
function test_start_from_another_branch()
{
    local repo=$1
    local default_branch=$2

    _init_repo ${repo} -b ${default_branch}
    git checkout -B another 2> /dev/null
    git ger start work -b another

    [ "$(git rev-parse --abbrev-ref HEAD)" = "work" ] || \
        fail "Didn't change to local branch 'work'!"
    assert_equals "refs/heads/another" \
        "$(git for-each-ref --format '%(upstream)' refs/heads/work)"
    assert_file_exists .git/git-gerrit/work/change-id
}
