# PostgREST Cookiecutter Template

* [Cookiecutter](https://cookiecutter.readthedocs.io/) for project templating.
* [PostgreSQL](https://www.postgresql.org/) as a database engine.
* [PostgREST](https://postgrest.com/) as RestAPI server.
* [Nginx](https://nginx.org/) as web server (reverse proxy + content hosting).
* [Sqitch](https://sqitch.org/) for managing  database migrations.
* [Let’s Encrypt](https://letsencrypt.org/) as certificate authority.
* [Docker](https://www.docker.com/) for app isolation, aka containers.
* [Docker compose](https://docs.docker.com/compose/) for container orchestration.

## Project generation

To scaffold your own project from this template, first install cookiecutter, then invoke it with a link to this repository as an argument: 

```sh
pip install cookiecutter
python -m cookiecutter https://github.com/bartelemi/postgrest-cookiecutter
```

You can customise a lot of aspects of what/how different parts are generated based on the flags.

| Flag                   | Description                           | Default              |
|------------------------|---------------------------------------|----------------------|
| project_name           | Project name.                         | Project Name         |
| project_slug           | Project slug (sanitised project name) | project-name         |
| description            | Description for your project.         | Project description. |
| author_name            | Project author.                       | John Smith           |
| domain_name            | Domain for the website.               | 127.0.0.1            |
| email                  | Contact e-mail address.               | john-smith@127.0.0.1 |
| version                | Project version.                      | 0.1.0                |
| open_source_license    | Project licence type.                 | MIT                  |
| timezone               | Default timezone used by app and db.  | UTC                  |
| nginx_version          | Nginx Docker image version tag.       | alpine               |
| nginx_use_ssl          | Whether to configure nginx with SSL.  | n                    |
| postgrest_version      | PostgREST Docker image version tag.   | latest               |
| postgresql_version     | PostgreSQL Docker image version tag.  | latest               |
| postgresql_user        | Default DB root username.             | postgres             |
| postgresql_password    | Database root user password.          | postgres             |
| use_swagger_ui         | Whether to deploy Swagger/OpenAPI UI. | y                    |
| authenticator_password | 'authenticator' API user password.    | password             |

## Docker Compose commands

- `docker compose up` - start database, application and webserver.
- `docker compose down` - tear down application stack.

## Security hardening

### JWT token

Example token (with signature removed):

```txt
eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJyb2xlIjoiYXV0aG9yIiwidXNlcmlkIjoiYXV0aDB8NTZkZWEwYjM4MWRlMjkyZTBjYjc1OTY1IiwiaXNzIjoiaHR0cHM6Ly9vcGVuZXRoLmF1dGgwLmNvbS8iLCJzdWIiOiJhdXRoMHw1NmRlYTBiMzgxZGUyOTJlMGNiNzU5NjUiLCJhdWQiOiJBWm10a0JONXpER0VSSmVzRlpHRlM4dllKWXlaVHJEbyIsImV4cCI6MTQ1NzQ4NjM5MywiaWF0IjoxNDU3NDUwMzkzfQ.2DIZz2bf19Jr9UaNA3DLl263JqzXvrAUky3Vr_ZgIbQ
```

```json
{
	"role": "author",
	"userid": "auth0|56dea0b381de292e0cb75965",
	"iss": "https://example.auth0.com/",
	"sub": "auth0|56dea0b381de292e0cb75965",
	"aud": "AZmtkBN5zDGERJesFZGFS8vYJYyZTrDo",
	"exp": 1457486393,
	"iat": 1457450393
}
```

The `role` gets mapped to a PostgreSQL role, `sub` is used to uniquely identify users.


### Diffie-Hellman parameters

```sh
openssl dhparam -out certificates/dhparam.pem 4096
```

Goals:

* A+ on <https://www.ssllabs.com/ssltest/analyze.html?d=example.com>
* <https://cyh.herokuapp.com/cyh>

<https://www.owasp.org/index.php/List_of_useful_HTTP_headers>
<https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html>

### Content Security Policy

* <https://www.w3.org/TR/CSP/>
* <https://developer.mozilla.org/en-US/docs/Web/Security/CSP/CSP_policy_directives>
