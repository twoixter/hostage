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
#import "TXODHostsManager.h"
#import <iomanip>

@implementation TXODHostsManager

- (id)init
{
    if (self = [super init]) {
        _session = [ODSession defaultSession];
        _node = [ODNode nodeWithSession:_session name:kLOCAL_NODE_NAME error:nil];
    }

    return self;
}

- (void)displayHosts:(NSArray *)hosts;
{
    int count = [hosts count];

    for (ODRecord *host in hosts) {
        NSDictionary *attrs = [host recordDetailsForAttributes:[NSArray arrayWithObjects: kODAttributeTypeIPAddress, nil] error:nil];

        // Only output records with an IPAddress Attribute
        if ([attrs count]) {
            std::cout << std::setw(15) << std::left
                      << [[[attrs objectForKey:kODAttributeTypeIPAddress] lastObject] UTF8String]
                      << "  " << [[host recordName] UTF8String]
                      << std::endl;
        }
    }
}

- (void)listHosts;
{
    [self displayHosts:[self getHostsWithPattern:nil searchIn:nil]];
}

- (void)listHostsWithPattern:(NSString *)pattern;
{
    // Trying first the hostnames
    NSArray *hosts = [self getHostsWithPattern:pattern searchIn:nil];
    if ([hosts count] == 0) {
        // If no hostnames found, try looking the IP addresses
        hosts = [self getHostsWithPattern:pattern searchIn:kODAttributeTypeIPAddress];
    }

    // Ok, whatever...
    [self displayHosts:hosts];
}

- (NSArray *)getHostsWithPattern:(NSString *)pattern searchIn:(ODAttributeType)attribute;
{
    NSError *error = nil;
    ODQuery *query = [ODQuery queryWithNode: _node
                             forRecordTypes: kODRecordTypeHosts
                                  attribute: attribute
                                  matchType: kODMatchContains
                                queryValues: pattern
                           returnAttributes: kODAttributeTypeIPAddress // kODAttributeTypeStandardOnly
                             maximumResults: nil
                                      error: &error];
    if (error) {
        NSLog(@"error: %@", [error localizedDescription]);
        return nil;
    }

    NSArray *results = [query resultsAllowingPartial:NO error:&error];
    if (error) NSLog(@"unexpected error: %@", [error localizedDescription]);

    return results; // results is already nil in case of error
}

- (ODRecord *)getHostWithName:(NSString *)name
{
    NSError *error = nil;
    ODQuery *query = [ODQuery queryWithNode: _node
                             forRecordTypes: kODRecordTypeHosts
                                  attribute: nil
                                  matchType: kODMatchEqualTo
                                queryValues: name
                           returnAttributes: kODAttributeTypeIPAddress // kODAttributeTypeStandardOnly
                             maximumResults: nil
                                      error: &error];
    if (error) {
        NSLog(@"unexpected error (1): %@", [error localizedDescription]);
        return nil;
    }

    NSArray *results = [query resultsAllowingPartial:NO error:nil];
    if ([results count] > 0) {
        return [results objectAtIndex:0];
    }
    return nil;
}

- (int)addHost:(NSString *)hostname withIp:(NSString *)ip;
{
    NSError *error = nil;

    if (ip == nil) ip = @"127.0.0.1";
    ODRecord *newRecord = [_node createRecordWithRecordType: kODRecordTypeHosts
                                name: hostname  attributes: nil  error: &error];
    if (error) {
        std::cerr << "Unable to create record for '" << [hostname UTF8String] << "'.";
        if (geteuid() != 0) std::cerr << " Try using 'sudo' next time...";
        std::cerr << std::endl;
        return -1;
    }

    [newRecord setValue:ip forAttribute:kODAttributeTypeIPAddress error:&error];
    [newRecord synchronizeAndReturnError:&error];
    if (error) {
        NSLog(@"unexpected error (2): %@", [error localizedDescription]);
        return -1;
    }

    [newRecord release];
    return 0;
}

- (int)modifyHost:(ODRecord *)host withIp:(NSString *)ip;
{
    NSError *error = nil;

    if (ip == nil) ip = @"127.0.0.1";
    [host setValue:ip forAttribute:kODAttributeTypeIPAddress error:&error];
    if (error) {
        std::cerr << "Unable to modify record.";
        if (geteuid() != 0) std::cerr << " Try using 'sudo' next time...";
        std::cerr << std::endl;
        return -1;
    }

    [host synchronizeAndReturnError:&error];
    if (error) {
        NSLog(@"unexpected error (3): %@", [error localizedDescription]);
        return -1;
    }

    return 0;
}

- (int)addOrModifyHost:(NSString *)hostname withIp:(NSString *)ip;
{
    ODRecord *host = [self getHostWithName:hostname];
    if (host == nil) {
        // Record not found, it's safe to add
        return [self addHost:hostname withIp:ip];
    } else {
        return [self modifyHost:host withIp:ip];
    }
}

- (bool)deleteHost:(ODRecord *)host;
{
    bool rc = [host deleteRecordAndReturnError:nil];
    if (rc == NO) {
        std::cerr << "Unable to delete record for: " << [[host recordName] UTF8String] << std::endl;
    }
    return rc;
}

- (int)deleteHostsWithPattern:(NSString *)pattern;
{
    int total_deleted = 0;

    // Trying first the hostnames
    NSArray *hosts = [self getHostsWithPattern:pattern searchIn:nil];
    if ([hosts count] == 0) {
        // If no hostnames found, try looking the IP addresses
        hosts = [self getHostsWithPattern:pattern searchIn:kODAttributeTypeIPAddress];
    }

    // Delete whatever found
    for (ODRecord *host in hosts) {
        if ([self deleteHost:host] == YES) {
            total_deleted++;
        }
    }
    return total_deleted;
}

- (int)cleanAllRecords;
{
    NSError *error = nil;
    NSArray *dead_recs_walking = [self getHostsWithPattern:nil searchIn:nil];

    int total_records = [dead_recs_walking count];
    for (ODRecord *host in dead_recs_walking) {
        if ([self deleteHost:host] == NO) {
            total_records--;
        }
    }
    return total_records;
}

@end
