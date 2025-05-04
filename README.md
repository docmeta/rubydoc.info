# RubyDoc.info: YARD Doc Server

RubyDoc.info is the next generation Ruby doc server, replacing
[http://rdoc.info](http://rdoc.info) and
[http://yardoc.org/docs](http://yardoc.org/docs).
This doc server uses YARD to generate project documentation on the fly, for
both published RubyGems as well as GitHub projects.

The public doc server is hosted at [http://www.rubydoc.info](http://www.rubydoc.info)

## Getting Started

This site is a public service and is community-supported. Patches and
enhancements are welcome.

### Requirements

- Docker Desktop
- Ruby 3.3+

### Configuration

This server uses typical Rails configuration, but we rely on a specific `config/rubydoc.yml` file to configure the
application level settings. You should first copy the `config/rubydoc.yml.sample` file to `config/rubydoc.yml` and
then edit the file to configure your server (although the defaults should provide a working experience).

```sh
cp config/rubydoc.yml.sample config/rubydoc.yml
```

### Development

Clone the repository and run the setup script to install dependencies and create the database:

```sh
git clone git://github.com/docmeta/rubydoc.info
cd rubydoc.info
./bin/setup
```

You can also use `./bin/dev` if you have already setup the project.

> [!NOTE]
> Windows users must use WSL2 to run the development server.

### Job Queue

You can inspect running jobs at http://localhost:3000/jobs in development. In production this URL is backed behind
Basic Auth using [mission_control-jobs](https://github.com/rails/mission_control-jobs?tab=readme-ov-file#authentication).

Run `WITHOUT_JOBS=1 ./bin/dev` to disable the job queue in development. You can run `./bin/jobs` to start a separate
job queue process if needed.

## Deploying

This server can be deployed using Docker swarm. In the case of a single node deployment, you can use the following
commands to deploy the server:

```sh
./script/deploy
```

This will build the Docker image and deploy the server using the local configuration files.

## Administration Commands

RubyDoc.info comes with a set of rails tasks that can be run to update remote gems, force documentation generate, or
install Ruby stdlib documentation.

```sh
# Update remote gems
rails rubydoc:gems:update

# Install Ruby stdlib documentation for X.Y.Z
rails rubydoc:stdlib:install VERSION=X.Y.Z

# Generate documentation for a gem or github project (NAME=owner/repo VERSION=branch for github projects)
rails rubydoc:docs:generate NAME=library VERSION=X.Y.Z SOURCE=github|gem
```

## Thanks

RubyDoc.info was created by Loren Segal ([YARD](https://github.com/lsegal/yard)) and Nick Plante (rdoc.info) and is a
project of DOCMETA, LLC. Additional help was provided by
[our friendly developer community](https://github.com/docmeta/rubydoc.info/graphs/contributors).
Pull requests welcome!

(c) 2025 DOCMETA LLC. This code is distributed under the MIT license.
