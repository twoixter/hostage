= utility to manage local hostnames

Hostage is a command line utility to manage local hostnames, inspired by the Ghost GEM for ruby.

Tipically this is done editing `/etc/hosts` on Unix systems, but with Mac OS X we can use the Open Directory Services as an alternative. I prefer not to mess with system files, I want to keep my `/etc/hosts` file as clean as possible...

= Compiling and installing hostage

== Requirements

* MacOSX
* CMAKE (Install with Mac Ports or similar)

== For the impatient

Clone the repository and use:

    cmake . && sudo make install

== HELP

This is the help output from `hostage --help`. I think this should be enough... :-)

	USAGE: hostage [options] <command> [hostname [ip]] | [pattern]

	Options:
	__--force__  Required for some operations.

	Commands:
	__list [pattern]__
	        Lists the current configured local hostnames in Open Directory.
	        Use [pattern] to only list entries containing [pattern] in the
	        hostname or IP address.

	        Output is compatible with /etc/hosts format.

	__add [hostname] [ip address]__
	        Adds [hostname] to the local hostname list, with [ip address].
	        Defaults to 127.0.0.1 if no IP address given.

	        If both [hostname] and [ip address] is missing, hostage reads
	        from stdin a list of ip-hostname pairs in /etc/hosts format.

	__delete <hostname>__
	        Removes <hostname> from the local hostname list.
	        You need to use the --force if there is no exact match.

	__clean__
	        Removes ALL local hostnames from Open Directory Services.
	        You need to use the --force here, master.
