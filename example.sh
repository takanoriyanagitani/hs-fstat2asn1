#!/bin/sh

bname=hs-fstat2asn1
bin=$(cabal exec -- which "${bname}")

check_schema() {
	python3 -c 'import asn1tools; import sys; import functools; functools.reduce(
        lambda state, f: f(state),
        [
            lambda fstat: fstat.encode(
                "Dirent",
                dict(
                    name = "dummy.dat",
                    size = 42,
                    modified = 299792458,
                    fileType = "regular",
                ),
            ),
            sys.stdout.buffer.write,
        ],
        asn1tools.compile_files("./FileStat.asn"),
    )' |
		python3 -c 'import asn1tools; import sys; import json; import functools; functools.reduce(
            lambda state, f: f(state),
            [
                functools.partial(
                    asn1tools.compile_files("./FileStat.asn").decode,
                    "Dirent",
                ),
                json.dumps,
                print,
            ],
            sys.stdin.buffer.read(),
        )' |
        jq
}

der2json(){
    cat /dev/stdin |
		python3 -c 'import asn1tools; import sys; import json; import functools; functools.reduce(
            lambda state, f: f(state),
            [
                functools.partial(
                    asn1tools.compile_files("./FileStat.asn").decode,
                    "Dirent",
                ),
                json.dumps,
                print,
            ],
            sys.stdin.buffer.read(),
        )' |
        jq
}

ln -sf "${bin}" ./

ENV_DIRENT_PATH=./hs-fstat2asn1 "${bin}" |
    der2json
