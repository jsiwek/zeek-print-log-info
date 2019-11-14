Output field descriptions for all Zeek logs
===========================================

This is a simple script to introspect all Zeek logs and output
field name, type, and description information.  The default output
format is CSV files.

Installation
------------

Via `zkg <https://docs.zeek.org/projects/package-manager/en/stable/>`_::

    zkg install jsiwek/zeek-print-log-info

Manually::

    cd <prefix>/share/zeek/site
    git clone https://github.com/jsiwek/zeek-print-log-info

Running
-------

Run the following command::

    ZEEK_ALLOW_INIT_ERRORS=1 zeek zeek-print-log-info

There is a lot of extraneous output because it's loading and parsing
a lot of scripts that aren't necessarily meant to be loaded in this
fashion, but otherwise should write `*.csv` files in the current
directory just fine.
