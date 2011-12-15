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

#import <Foundation/Foundation.h>
#import "TXODHostsManager.h"
#import "hostage_options.h"
#import "color_streams.h"

#import <sstream>

NSDictionary *hosts_from_stdin()
{
    NSMutableArray * ips   = [[NSMutableArray arrayWithCapacity:10] autorelease];
    NSMutableArray * hosts = [[NSMutableArray arrayWithCapacity:10] autorelease];

    char line_buffer[256];
    while (std::cin.getline(line_buffer, 255)) {
        std::stringstream stream(line_buffer);
        std::string ip;   stream >> ip;
        std::string host; stream >> host;

        // Mmh... Can a std::string be empty being read from a stream?
        if (ip.empty() || host.empty()) continue;

        // Simple sanitize checks on ip and hosts.
        // This should skip comments and IPv6 addresses and reserved hostnames.
        if (ip.find('#') != std::string::npos) continue;
        if (ip.find(':') != std::string::npos) continue;
        if (host.find('#') != std::string::npos) continue;
        if (host.find(':') != std::string::npos) continue;
        if ((host == "localhost") || (host == "broadcasthost")) continue;

        [ips addObject:[NSString stringWithUTF8String:ip.c_str()]];
        [hosts addObject:[NSString stringWithUTF8String:host.c_str()]];
    }
    return [[NSDictionary dictionaryWithObjects:ips forKeys:hosts] autorelease];
}


int main(int argc, char *argv[])
{
    int rc = 0;

    TXHostageOptions opts(argc, argv);
    if (!opts) exit(-1);

    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    TXODHostsManager *man = [[TXODHostsManager alloc] init];

    switch (opts.action()) {

        case TXHostageOptions::TXHostageList:
            if (opts.hostname().empty()) {
                [man listHosts];
            } else {
                [man listHostsWithPattern:[NSString stringWithUTF8String:opts.hostname().c_str()]];
            }
            break;

        case TXHostageOptions::TXHostageAdd:
            if (opts.hostname().empty()) {
                NSDictionary *hosts = hosts_from_stdin();
                for (id key in hosts) {
                    [man addOrModifyHost:key withIp:[hosts objectForKey:key]];
                }
            } else {
                NSString *ip = opts.ip().empty() ? nil : [NSString stringWithUTF8String:opts.ip().c_str()];
                NSString *hostname = [NSString stringWithUTF8String:opts.hostname().c_str()];
                ODRecord *host = [man getHostWithName:hostname];

                if (host == nil) {
                    // Record not found, it's safe to add
                    rc = [man addHost:hostname withIp:ip];
                } else {
                    if (opts.force()) {
                        // Force rewriting of the host IP
                        rc = [man modifyHost:host withIp:ip];
                    } else {
                        std::cerr << "Hostname already exists. Try using the --force next time..." << std::endl;
                        rc = -1;
                    }
                }
            }
            break;

        case TXHostageOptions::TXHostageDelete:
            if (opts.hostname().empty()) {
                std::cerr << "Missing hostname..." << std::endl;
                rc = -1;
            } else {
                NSString *hostname = [NSString stringWithUTF8String:opts.hostname().c_str()];
                ODRecord *host = [man getHostWithName:hostname];
                if (host == nil) {
                    // Host not found, let's try to match against a pattern...
                    if (!opts.force()) {
                        std::cerr << "Sorry master, I require you to use the --force in order to delete hostnames with a pattern..." << std::endl;
                        if (geteuid() != 0) std::cerr << "(Remember to use 'sudo' to become superuser)" << std::endl;
                        rc = -1;
                    } else {
                        // Whipeout!
                        int total_clean = [man deleteHostsWithPattern:hostname];
                        std::cout << "Deleted " << total_clean << " records." << std::endl;
                    }
                } else {
                    rc = [man deleteHost:host] ? 0 : -1;
                }
            }
            break;

        case TXHostageOptions::TXHostageClean:
            if (!opts.force()) {
                std::cerr << "Sorry master, I require you to use the --force in order to wipe all hostnames..." << std::endl;
                if (geteuid() != 0) std::cerr << "(Remember to use 'sudo' to become superuser)" << std::endl;
                rc = -1;
            } else {
                // Whipeout!
                int total_clean = [man cleanAllRecords];
                std::cout << "Deleted " << total_clean << " records." << std::endl;
            }
            break;
        
    }

    // [results enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
    //     NSLog(@"%d - %@ (%@)", idx, [object recordName], [object recordType]);
    // }];

    [man release];
    [pool drain];
	return rc;
}

