#!/usr/bin/env python
import json
import os
import subprocess
import sys
import tarfile
from contextlib import suppress
from pathlib import Path
from shutil import move, which
from urllib.request import urlopen, urlretrieve


def get_release_info(repo: str, release: str = "latest") -> dict:
    releases_url = f"https://api.github.com/repos/{repo}/releases/{release}"
    try:
        with urlopen(releases_url) as response:
            release_info = json.loads(response.read())
            return release_info
    except Exception as error:
        print(f"Cannot fetch information about '{release}' release for '{repo}'", error)
        sys.exit(-1)


def fetch_release_bundle(tarball_url: str):
    try:
        file_name, _ = urlretrieve(tarball_url)
        return file_name
    except Exception as error:
        print(f"Cannot fetch release bundle", error)
        sys.exit(-2)


def unpack_release(file_name: str, destination: str):
    unpacked_folder = Path("")
    try:
        with tarfile.open(file_name) as tar:
            unpacked_object = None
            for info in tar.getmembers():
                if "/dist/" in info.name and "flavors" not in info.name:
                    tar.extract(info)
                    unpacked_object = info.name
            unpacked_folder = Path(unpacked_object).parent
            move(unpacked_folder, Path(destination))
    except Exception as error:
        print("Failed to unpack release bundle:", error)
        sys.exit(-3)
    finally:
        with suppress(OSError):
            os.remove(file_name)
        with suppress(OSError):
            os.remove(unpacked_folder.parent)


def set_openapi_doc_url(root: Path):
    index_html = root / "index.html"
    sample_openapi_url = "https://petstore.swagger.io/v2/swagger.json"
    project_openapi_url = "http://{{ cookiecutter.domain_name }}:8080/api/"
    with open(index_html) as original:
        updated_index_html = original.read().replace(
            sample_openapi_url, project_openapi_url
        )
    with open(index_html, "w") as updated:
        updated.write(updated_index_html)


def init_swagger_ui():
    github_repo = "swagger-api/swagger-ui"
    destination = Path("www/swagger")
    print("Pulling and setting up Swagger page... ", end="", flush=True)
    release_info = get_release_info(github_repo)
    file_name = fetch_release_bundle(release_info["tarball_url"])
    unpack_release(file_name, destination)
    set_openapi_doc_url(destination)
    print("done!")


def get_sqitch_tool() ->  str:
    sqitch = which("sqitch")
    if sqitch is None:
        print("'sqitch' not found on PATH. Follow the installation instructions here")
        print(" > http://sqitch.org/download/")
        exit(1)
    return sqitch


def init_sqitch():
    print("Configuring sqitch for db migrations...")
    sqitch = get_sqitch_tool()
    process_info = subprocess.run(
        (
            sqitch,
            "init", "{{ cookiecutter.project_slug }}",
            "--engine", "pg",
            "--top-dir", "sql",
            "--target", "db:pg:{{ cookiecutter.project_slug }}",
        ),
        timeout=30,
    )
    if process_info.returncode != 0:
        exit(process_info.returncode)
    print("Sqitch initialised!")


def main():
    if "{{ cookiecutter.use_swagger_ui }}" == "y":
        init_swagger_ui()
    init_sqitch()
    exit(0)


if __name__ == "__main__":
    main()
