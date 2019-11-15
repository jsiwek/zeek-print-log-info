@if ( Version::info$version_number < 30100 )

# Versions before 3.1.0 did not install test-all-policy.zeek so load a copy.
@load ./test-all-policy-3.0.zeek

# Scripts which are commented out in test-all-policy.zeek.
@load protocols/ssl/notary.zeek
@load frameworks/control/controllee.zeek
@load frameworks/control/controller.zeek
@load frameworks/files/extract-all-files.zeek
@load policy/misc/dump-events.zeek

@load zeekygen/example.zeek

@else

@load zeekygen

@endif
