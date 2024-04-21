#!/usr/bin/env python3.11
""""""
from __future__ import annotations

import abc
import argparse
import contextlib as ctx
import dataclasses as dc
import io
import itertools as it
import json
import os
import pathlib as p
import subprocess as sp
import sys

import more_itertools as mit
from agave import *


@dc.dataclass
class Script:
    subcommands: list

    def run(self) -> Result[IO[str], IO[str]]:
        """Run the script sequentially, quitting on errors."""

        def lift_process(process):
            result = (process.returncode, process.stdout, process.stderr)
            return Ok(result) if process.returncode == 0 else Err(result)

        logging = []

        for command in self.subcommands:
            command_string = " ".join(map(str, command))
            logging.append(f"+ {command_string}")

            process = sp.run(command, stdout=sp.PIPE, stderr=sp.PIPE, check=False)
            result = lift_process(process)

            if result.is_err:
                code, stdout, stderr = result.unwrap_err()
                indented = "\n".join(">>> " + i for i in stderr.decode("utf-8").splitlines())
                logging.append(f"! error: exited with return code {code}. error message: \n{indented}")
                logging.append("exiting early due to error.")
                return Err(logging)

        return Ok(logging)


# cache_path = p.Path("_cache.json")
#
# if cache_path.exists():
#     with cache_path.open("r", encoding="utf-8") as file:
#         CACHE_HASHES = json.load(file)
# else:
#     CACHE_HASHES = {}
#
#
# def get_hash_value(path):
#     return CACHE_HASHES


class Task(abc.ABC):
    @abc.abstractmethod
    def perform(self, logger, clean=False):
        raise NotImplementedError()

    # def update_db(self):
    #     set_hash_value(path)
    #
    # def is_done(self):
    #     return (
    #         get_hash_value(self)
    #         .map(lambda expected_hash: self.target_path.exists() and hash_of(target_path) == expected_hash)
    #         .unwrap_or(False)
    #     )


@dc.dataclass
class CompileCoffeeScriptTask(Task):
    path: ...

    def description(self):
        return f"compile (coffeescript -> javascript) `{self.path}`"

    def perform(self, clean=False):
        target = self.path.with_suffix(".js")
        compile_cs = Script([["coffee", "-c", "-b", self.path]])
        compile_cs.subcommands.append(["uglifyjs", target, "--output", target])
        return compile_cs.run()


@dc.dataclass
class CompileSCSSTask(Task):
    path: ...

    def description(self):
        return f"compile (SCSS -> CSS) `{self.path}`"

    def perform(self, clean=False):
        target = self.path.with_suffix(".css")
        compile_sass = Script([["sass", self.path, self.path.with_suffix(".css")]])
        compile_sass.subcommands.append(["uglifycss", target, "--output", target])

        # if clean:
        if True:
            compile_sass.subcommands.append(["rm", self.path.with_suffix(".css.map")])

        return compile_sass.run()


def find_tasks(directory) -> Iterator[Task]:
    for file in directory.iterdir():
        if file.is_dir():
            yield from find_tasks(file)

        elif file.suffix == ".coffee":
            yield CompileCoffeeScriptTask(file)

        elif file.suffix == ".scss" and file.stem == "styles":
            yield CompileSCSSTask(file)


def main() -> None:
    parser = argparse.ArgumentParser(description="Process some integers.")
    parser.add_argument(
        "--path", metavar="N", type=p.Path, default=p.Path(__file__).parent, help="the path to recursively compile in"
    )
    parser.add_argument("--clean", default=True, action="store_true", help="remove intermediate files afterwards")
    parser.add_argument("--silent", action="store_true", help="don't write to stdout")

    args = parser.parse_args()

    target = sys.stdout if not args.silent else io.StringIO()

    with ctx.redirect_stdout(target):
        print("searching for tasks... ", end="")
        tasks = list(find_tasks(args.path))
        tot = len(tasks)
        print(f"scheduled {tot} tasks.")
        print()

        for i, task in enumerate(tasks, 1):
            adjusted_i = str(i).rjust(len(str(tot)), "0")
            print(f"[task {adjusted_i} / {tot}] {task.description()}")
            result = task.perform(args.clean)

            if result.is_err:
                print("\n".join(result.unwrap_err()))
                exit(1)

            print("\n".join(result.unwrap()))
            print()

        print("done! <3")


if __name__ == "__main__":
    main()
