# Using this repo

This repository started as a personal note, and it contains many files that work together to provide Istio multicluster setup.

When setting up Istio multiclutser, there are already more than handful of Istio configurations you will need to juggle with; and the situation only gets more complex as you try to integrate other system such as Prometheus, Argo CD, etc.

By using this repository, you can get a sense of how those configurations and installation specs can be structured, and thus getting this repo handy on your local is a good approach for seeing Istio multicluster in action at first.

## Clone this repo

The simplest approach is to clone this entire repository, without forking. That way, you can get the latest updates from this repository with a single command.

**GOOD**

- Extremely simple
- You can get the latest spec without too much hassle

**NOT SO GOOD**

- File size is larger than you'd ever need (as this repo tries to cover many scenarios)
- For GitOps based scenarios, you cannot tweak to how you like.

### Full clone

<!-- == export: full-clone-command / begin == -->

```bash
{
    pwd
    # /some/path/at

    git clone https://github.com/rytswd/get-istio-multicluster.git

    cd get-istio-multicluster
    # /some/path/at/get-istio-multicluster
}
```

<!-- == export: full-clone-command / end == -->

### Shallow clone

```bash
{
    pwd
    # /some/path/at

    git clone --depth 1 -b main https://github.com/rytswd/get-istio-multicluster.git

    cd get-istio-multicluster
    # /some/path/at/get-istio-multicluster
}
```

## Fork this repo

To be updated

## Get files from this repo

**GOOD**

- Requires basically no tool (not even `git`)
- Fast and simple

**NOT SO GOOD**

- You cannot get the latest spec
- May not work as you see in your local copy if this repo has had updates

### With curl

```bash
# Simple curl without Git
{
    pwd
    # /some/path/at

    curl -sL -o get-istio-multicluster.zip https://github.com/rytswd/get-istio-multicluster/archive/main.zip
    unzip get-istio-multicluster.zip

    cd get-istio-multicluster-main
    # /some/path/at/get-istio-multicluster-main
}
```

## Why?

Many of the Istio setup documentation here assumes you have this repo cloned to your local. There are a few reasons:

- Istio's configurations can be separated into so many files
- Many files work in tandem, and having directory structure makes it easier to see
- GitOps solution requires configurations to be declarative and commited to repo

In order to follow the installation and usage steps in this repo, it is probably easiest to clone the repo for your starting point, so that you get the gist of what Istio can do and what sort of configurations you need for your business requirements.

From here on, all the steps are assumed to be run from `/some/path/at/get-istio-multicluster`.

Also, if you need to use specific Istio version, make sure your `PATH` is set up correctly, such as:

```bash
$ PATH="$HOME/Coding/bin/istio-1.7.5/bin:$PATH"
```

<details>
<summary>ℹ️ Details</summary>

This repository is mostly configuration files. Having the set of files all in directory structure makes it easier to see how multiple configurations work together.

Git repository is not necessarily a must-have. Although the clean-up step uses Git features, you could use either of the following commands for even simpler use cases:

```bash
# Shallow Git clone
git clone --depth 1 -b main https://github.com/rytswd/get-istio-multicluster.git
```

```bash
# Simple curl without Git
{
    curl -sL -o get-istio-multicluster.zip https://github.com/rytswd/get-istio-multicluster/archive/main.zip
    unzip get-istio-multicluster.zip
    cd get-istio-multicluster-main
}
```

</details>
