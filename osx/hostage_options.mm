/*
 * Copyright (c) 2011 Jose Miguel Pérez, Twoixter S.L.
 *
 * Licensed under the MIT License: http://www.opensource.org/licenses/mit-license.php
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#import "color_streams.h"
#import "hostage_options.h"
#import <getopt.h>

TXHostageOptions::TXHostageOptions(int argc, char *argv[])
    : _valid(true)
    , _force(0)
{
    static const struct option longOpts[] = {
        { "help", no_argument, NULL, 'h' },
        { "force", no_argument, &_force, 1 },
        { NULL, no_argument, NULL, 0 }
    };

    // Mmhhh... I would like to use the boost::program_options for this,
    // but I don't think it's a good idea to include boost as a requirement
    // only to parse a simple command line...
    // Ok, falling back to C and their "getopt_long" mess.
    // What a project... C / C++ / ObjectiveC in one shot... :-D
    opterr = 0;
    int longIndex = -1, opt = 0;
    do {
        opt = getopt_long( argc, argv, "h", longOpts, &longIndex );
        switch (opt) {
            case 'H': usage(); return;
            case '?': usage("Invalid option!"); return;
        }
    } while (opt != -1);
    argc -= optind;
    argv += optind;

    if (argc == 0) {
        usage();
        _valid = false;
        return;
    }

    if (argc == 1) {
        _action = parse_action(argv[0]);
    }

    if (argc == 2) {
        _action = parse_action(argv[0]);
        _hostname = argv[1];
    }

    if (argc == 3) {
        _action = parse_action(argv[0]);
        _hostname = argv[1];
        _ip = argv[2];
    }

    if (_action == TXHostageNone) {
        usage("Invalid action!");
        _valid = false;
        return;
    }
}

void TXHostageOptions::usage(const std::string &__errorStr)
{
    using namespace std;
    using namespace ansi;

    if (!__errorStr.empty()) {
        cerr << bright << red << "ERROR: " << __errorStr << endlc;
        cerr << endl;
    }

    cerr << white(string("USAGE:")) << " hostage [options] <command> [hostname [ip]] | [pattern]\n\n";
    cerr << "Options:\n";
    cerr << white(string("--force"))
         << "\tRequired for some operations.\n\n";
    
    cerr << "Commands:\n";
    cerr << white(string("list [pattern]")) << "\n"
            "\tLists the current configured local hostnames in Open Directory.\n"
            "\tUse [pattern] to only list entries containing [pattern] in the\n"
            "\thostname or IP address.\n\n"
            "\tOutput is compatible with /etc/hosts format.\n\n";

/*
            "\t$ sudo hostage list >> /etc/hosts\n\n"
            "\t(Note that to be safe, we are _adding_ to /etc/hosts, not replacing it,\n"
            "\tthere's still some IPv6 entries in there for loopback and localhost)\n\n";
*/

    cerr << white(string("add [hostname] [ip address]")) << "\n"
            "\tAdds [hostname] to the local hostname list, with [ip address].\n"
            "\tDefaults to 127.0.0.1 if no IP address given.\n\n"
            "\tIf both [hostname] and [ip address] is missing, hostage reads\n"
            "\tfrom stdin a list of ip-hostname pairs in /etc/hosts format.\n\n";

    cerr << white(string("delete <hostname>")) << "\n"
            "\tRemoves <hostname> from the local hostname list.\n"
            "\tYou need to use the --force if there is no exact match.\n\n";

    cerr << white(string("clean")) << "\n"
            "\tRemoves ALL local hostnames from Open Directory Services.\n"
            "\tYou need to use the --force here, master.\n";

/*
    cerr << "Examples:\n"
            "\thostage add www.google.com         Adds www.google.com as 127.0.0.1 (not very useful :-)\n"
            "\thostage list                       Lists all configured local hostnames\n"
            "\thostage list > hosts.txt           Exports the host list to 'hosts.txt'\n"
            "\thostage add < /etc/hosts           Imports the file /etc/hosts\n"
            "\thostage delete www.google.com      Deletes www.google.com from the list\n"
            "\thostage --force delete www         Deletes all hosts that contains 'www' in the name\n"
            "\t                                   (Note that you need to use the --force)\n"
            "\n";
*/

    cerr << endl;
}

TXHostageOptions::TXHostageAction TXHostageOptions::parse_action(const std::string &__actionStr)
{
    if (__actionStr == "list")   return TXHostageList;
    if (__actionStr == "add")    return TXHostageAdd;
    if (__actionStr == "delete") return TXHostageDelete;
    if (__actionStr == "clean")  return TXHostageClean;
    return TXHostageNone;
}
