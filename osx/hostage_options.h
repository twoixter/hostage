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

// Including iostream and string from the Standard Library, ObjC style!! Yup!!
#import <iostream>
#import <string>

struct TXHostageOptions {
public:

    typedef enum {
        TXHostageNone, TXHostageList, TXHostageAdd, TXHostageDelete, TXHostageClean
    } TXHostageAction;

    explicit TXHostageOptions(int argc, char *argv[]);

    TXHostageAction action() const   { return _action; }
    std::string     hostname() const { return _hostname; }
    std::string     ip() const       { return _ip; }
    bool            force()          { return _force; }

    // The following two operators allows us to make something like:
    //
    //  if (opts) { ... }       /* operator void * called */
    //  if (!opts) { ... }      /* operator ! called */
    //
    operator void *() const
    { return _valid ? const_cast<TXHostageOptions *>(this) : 0; }

    bool operator!() const
    { return !_valid; }

private:
    void usage(const std::string &__errorStr = std::string());
    TXHostageAction parse_action(const std::string &__actionStr);
    
    bool            _valid;
    int             _force;
    TXHostageAction _action;
    std::string     _hostname;
    std::string     _ip;
};
