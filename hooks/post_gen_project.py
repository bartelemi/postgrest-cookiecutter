#!/usr/bin/env python
import json
import os
import sys
import tarfile
from pathlib import Path
from shutil import move
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


def unpack_release(file_name):
    try:
        with tarfile.open(file_name) as tar:
            for info in tar.getmembers():
                if "/dist/" in info.name and "flavors" not in info.name:
                    tar.extract(info)
                    unpack_location = info.name
            move(Path(unpack_location).parent, Path("www/swagger"))
    except Exception as error:
        print("Failed to unpack release bundle:", error)
        sys.exit(-3)
    finally:
        os.remove(file_name)


def main():
    github_repo = "swagger-api/swagger-ui"
    release_info = get_release_info(github_repo)
    file_name = fetch_release_bundle(release_info["tarball_url"])
    unpack_release(file_name)


if "{{ cookiecutter.use_swagger_ui }}" == "y":
    main()    
