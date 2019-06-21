#!/usr/bin/env python3

import sys
import ycm_core

# TODO: this

# def Settings( **kwargs ):
#   return {
#     'flags': [ '-x', 'c++', '-Wall', '-Wextra', '-Werror' ],
#   }
#

def Settings(**kwargs):
    with open("/home/justin/output", "w") as f:
        p = lambda *args, **kwargs: print(*args, file=f, **kwargs)
        p(kwargs)
        p(kwargs["client_data"])

        p(ycm_core)
        p(type(ycm_core))
        p(dir(ycm_core))
        p(help(ycm_core.ClangCompleter))

    return {
            'flags': [ '-x', 'c++', '-Wall', '-Wextra', '-Werror' ],
            }

