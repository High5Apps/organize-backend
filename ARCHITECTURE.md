# Architecture
This document describes the high-level architecture of the Organize API server. If you want to familiarize yourself with this codebase, you're in the right place!

(This document was inspired by [Alex Kladov's ARCHITECTURE.md](https://matklad.github.io/2021/02/06/ARCHITECTURE.md.html).)

## Bird's Eye View

This repo defines the components needed to create, develop, test, and administer an Organize API server.

The server uses [Docker containers](https://www.docker.com/resources/what-container/) for each of its core services. Services are coordinated using [Docker Compose](https://docs.docker.com/compose/).

The core API server is a [Ruby on Rails API-only application](https://guides.rubyonrails.org/api_app.html), which serves [JSON](https://developer.mozilla.org/en-US/docs/Learn/JavaScript/Objects/JSON) responses. [PostgreSQL](https://www.postgresql.org/) is used as the database. [NGINX](https://nginx.org/en/docs/) is used as the web server. [Certbot](https://certbot.eff.org/) and [Let's Encrypt](https://letsencrypt.org/) are used for TLS certificates. [Apache JMeter](https://jmeter.apache.org/) is used for load testing.

The server runs on top of [Raspberry Pi](https://www.raspberrypi.com/) hardware running the [Raspberry Pi OS Lite](https://www.raspberrypi.com/software/) operating system for now, but Docker and Docker Compose should simplify the transition onto other hardware if needed in the future.

## Code Map

This section talks briefly about various important directories and data structures. Pay attention to the **Architecture Invariant** sections. They often talk about things which are deliberately absent in the source code.

### `api`

The root of the Ruby on Rails api service. It follows [Rails conventions](https://github.com/jwipeout/rails-directory-structure-guide) for its subdirectory structure.

**Architecture Invariant**: All human-generated text must be end-to-end encrypted by the client using the relevant Org's group secret, and then stored in an `EncryptedMessage` attribute on its parent model. The attribute must begin with the prefix `encrypted_` (e.g. `Post.encrypted_title` or `Org.encrypted_member_definition`).

**Architecture Invariant**: Responses with `4XX` errors must include human-readable explanations of what went wrong by populating a non-empty string array at the top-level `error_messages` key. 

### `bin`

Admin scripts for dealing with top-level server operations.

### `certs`

Certbot sevice for renewing Let's Encrypt TLS certificates.

### `db-upgrade`

Service for performing PostgreSQL major version upgrades. Heavily inspired by this [proof-of-concept repo](https://github.com/tianon/docker-postgres-upgrade).

### `jmeter`

For load testing the server using the Apache JMeter application and CLI.

### `site`

The root of the Ruby on Rails site service. It serves the static website at <https://getorganize.app>. It follows [Rails conventions](https://github.com/jwipeout/rails-directory-structure-guide) for its subdirectory structure.

### `web`

NGINX web service for terminating TLS, defining non-Rails routes, and serving static assets.

## Cross-Cutting Concerns

This section talks about the things which are everywhere and nowhere in particular.

### Minimal reliance on external services with unaligned interests

When one party relies on another party for critical infrastructure, it's crucial for the first party to consider whether both parties' interests are aligned. Otherwise, the first party risks a denial-of-service if the other abruptly ends its partnership.

Many for-profit businesses have demonstrated that their interests are unaligned with the core interests of this project. As such, critical dependencies on these parties should not be introduced. 

However, some of these critical dependencies are too costly to avoid. In these circumstances, it's important to be prepared with a mitigation strategy.

Many of the following concerns are a result of this overarching concern.

### Containerization

Docker and Docker Compose are used to containerize each service running on the server. The main motivation for this is to provide the server with a straightforward path to being hardware-agnostic.

Docker Compose also offers a simple way of extending the production server to act as a local development server with different tooling and an exposed HTTP port at 8080.

**Architecture Invariant**: Service-specific code must live within its top-level folder. The folder  must have the same name as the Docker Compose service name. Service-specific Docker files should also live within the folder. In contrast, Docker Compose files should live in the root folder, since they deal with multiple services.

### Self-hostable

This project must remain lightweight enough to be self-hostable for a single Org on budget hardware like a Raspberry Pi. As a result, heavyweight features related to image, audio, and video are unlikely to be incorporated.

### Secrets

Secrets live in the `.env` file in the root folder. If you add a new secret to `.env`, be sure to add a corresponding entry to the `.env.example` file too.
