# Hostage

**Hostage** is a command line utility to manage local hostnames, inspired by the Ghost GEM for ruby.

Tipically this is done editing `/etc/hosts` on Unix systems, but with Mac OS X we can use the Open Directory Services as an alternative. I prefer not to mess with system files, I want to keep my `/etc/hosts` file as clean as possible...

> **NOTE:** Currently **Hostage** doesn't work with OSX Lion / Mountain Lion. I'm Looking for a fix.
> This has to do with how Lion / Mountain Lion handles Open Directory Services.

# Compiling and installing hostage

## Requirements

* Mac OS X
* CMAKE (Install with Mac Ports or similar)

## For the impatient

Clone the repository and use:

    cmake . && sudo make install

## HELP

This is the help output from `hostage --help`. I think this should be enough... :-)

	USAGE: hostage [options] <command> [hostname [ip]] | [pattern]

	Options:
	--force  Required for some operations.

	Commands:
	list [pattern]
	        Lists the current configured local hostnames in Open Directory.
	        Use [pattern] to only list entries containing [pattern] in the
	        hostname or IP address.

	        Output is compatible with /etc/hosts format.

	add [hostname] [ip address]
	        Adds [hostname] to the local hostname list, with [ip address].
	        Defaults to 127.0.0.1 if no IP address given.

	        If both [hostname] and [ip address] is missing, hostage reads
	        from stdin a list of ip-hostname pairs in /etc/hosts format.

	delete <hostname>
	        Removes <hostname> from the local hostname list.
	        You need to use the --force if there is no exact match.

	clean
	        Removes ALL local hostnames from Open Directory Services.
	        You need to use the --force here, master.

## Examples

Adding `mywebapp.priv` to the local hostnames pointing to 192.168.0.1

	sudo hostage add mywebapp.priv 192.168.0.1

Getting a list of all local hostnames

	hostage list

Export the list to a file (the format is like `/etc/hosts`)

	hostage list > hosts.txt

Clear all local hostnames

	sudo hostage --force clean

Import the hosts definition from a file

	hostage add < hosts.txt

You need superuser privileges to do that, so you can use someting like this:

	cat hosts.txt | sudo hostage add

Deleting a host with exact match

	sudo hostage delete mywebapp.priv

Deleting hosts matching a pattern (note the use of the --force)

	sudo hostage --force delete mywebapp
