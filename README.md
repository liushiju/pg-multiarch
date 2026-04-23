# PostgreSQL 15.12 Multi-Platform Build Templates
![pg](./pg_multiarch.png)

This repository contains a Docker-based build matrix for PostgreSQL 15.12 across:

- `ubuntu22`
- `ubuntu24`
- `el7`
- `el8`
- `el9`

The default build configuration matches the feature set you shared:

```text
--prefix=/data/postgresql/pgsql-15
--with-uuid=e2fs
--with-openssl
--with-libxml
--with-libxslt
--with-python
--with-perl
--with-tcl
--enable-nls
```

The build flow compiles the PostgreSQL core, enabled PL languages, and all source-tree
`contrib` extensions that are available in the target platform's dependency set.

`el7` is a legacy CentOS 7.9 target. It intentionally disables `--with-python` by
default because CentOS 7.9 does not provide a reliable Python 3 development stack in
the base repositories. `plperl`, `pltcl`, and source-tree `contrib` extensions are
still built for `el7`.

## Layout

- `docker/<target>/Dockerfile`: build image per target platform
- `scripts/build.sh`: unified entrypoint to build inside Docker
- `scripts/package.sh`: unified packager for staged install trees
- `.github/workflows/build-postgresql.yml`: GitHub Actions matrix
- `.gitlab-ci.yml`: GitLab CI matrix

## Local usage

```bash
chmod +x scripts/build.sh scripts/package.sh
./scripts/build.sh ubuntu22
./scripts/build.sh ubuntu24
./scripts/build.sh el7
./scripts/build.sh el8
./scripts/build.sh el9
./scripts/build.sh all
```

## GitHub CI and Release

- Push to `main`: GitHub Actions builds all matrix targets and uploads them as workflow artifacts
- Push a tag like `v15.12.0`: GitHub Actions builds all matrix targets and publishes a GitHub Release
- The Release page will contain every generated `.tar.gz` package and its `.sha256` checksum

Example:

```bash
git tag v15.12.0
git push origin v15.12.0
```

## Environment variables

- `PG_VERSION`: default `15.12`
- `PREFIX`: default `/data/postgresql/pgsql-15`
- `IMAGE_NAMESPACE`: default `local`
- `EXTRA_CONFIGURE_FLAGS`: extra flags appended to `configure`
- `SOURCE_TARBALL_URL`: override official PostgreSQL source URL
- `SOURCE_TARBALL_PATH`: use an existing source tarball instead of downloading
- `SKIP_PACKAGE=1`: build only, do not create tarball

## Output

Each build writes:

- staged install tree: `out/<target>/stage`
- archive: `dist/<target>/postgresql-15.12-<target>-<arch>.tar.gz`
- checksum: `dist/<target>/postgresql-15.12-<target>-<arch>.tar.gz.sha256`
