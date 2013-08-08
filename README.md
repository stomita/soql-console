# SOQL Console

[![Build Status](https://secure.travis-ci.org/stomita/soql-console.png)](http://travis-ci.org/stomita/soql-console)

## Abstract

Salesforce SOQL console app with metadata-aware word completion. Works both on TTY and web UI.

## Install

<pre>
  npm install -g soql-console
</pre>


## Running on TTY

### Usage

<pre>
$ soql -u username@example.com -p yourpassword
Logged in as: username@example.com

SOQL> SELECT Id, Name, Owner.Name FROM Account;
Id      Name    Owner.Name
001i0000009PyDrAAK      GenePoint       Tomita Shinichi
001i0000009PyDsAAK      United Oil & Gas, UK    Tomita Shinichi
001i0000009PyDtAAK      United Oil & Gas, Singapore     Tomita Shinichi
001i0000009PyDuAAK      Edge Communications     Tomita Shinichi
001i0000009PyDvAAK      Burlington Textiles Corp of America     Tomita Shinichi
001i0000009PyDwAAK      Pyramid Construction Inc.       Tomita Shinichi
001i0000009PyDxAAK      Dickenson plc   Tomita Shinichi
001i0000009PyDyAAK      Grand Hotels & Resorts Ltd      Tomita Shinichi
001i0000009PyDzAAK      Express Logistics and Transport Tomita Shinichi
001i0000009PyE0AAK      University of Arizona   Tomita Shinichi
001i0000009PyE1AAK      United Oil & Gas Corp.  Tomita Shinichi
001i0000009PyE2AAK      sForce  Tomita Shinichi

Total Size : 12
</pre>


### Command Options

<pre>
$ soql --help

  Usage: soql [options]

  Options:

    -h, --help                 output usage information
    -u, --username [username]  Salesforce username
    -p, --password [password]  Salesforce password (and security token, if available.)
    -e, --env [env]            Login environment ("production","sandbox", or hostname of login server)
    -q, --query [query]        SOQL query to execute automatically.
</pre>

### Intaractive Commands

Type ".help" to see command help menu when you are in REPL.

<pre>
SOQL> .help

  Commands:

   .connect [username] [password]  Login to Salesforce using given username and password. Security token should be concatinated to the password if available.
   .use [env]                      Change login server for user authentication. Argument "env" must be "production", "sandbox", or hostname of login server.
   .help                           Show command help.
   .exit                           Exit application.
   .quit                           Exit application. (synonym of .exit)

</pre>


## Running on Web UI

### Hosted Service

[https://soql-console.herokuapp.com/](https://soql-console.herokuapp.com/)

### Building on Local Server

Build and start your local web app for soql-console.

<pre>
$ git clone git://github.com/stomita/soql-console.git
$ cd soql-console
$ npm install
$ grunt build
$ foreman start
</pre>

Now you can access to http://localhost:5000 from your browser to get SOQL console web UI.

### Help

#### Start Completion
- Tab
- Ctrl + Space

#### Move Cursor to Next
- &#8595; (Down Arrow)
- Tab
- Ctrl + Space

#### Move Cursor to Previous
- &#8593; (Up Arrow)
- Shift + Tab
- Ctrl + Shift + Space

#### Execute Completion
- Return

#### Cancel Completion
- Esc

#### Run Query
- Ctrl + Return


## Credits

(The MIT License)

Copyright (c) 2012 Shinichi Tomita <shinichi.tomita@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


### Special Note

A lot of code in this project is borrowed from SQL Parser (https://github.com/forward/sql-parser) project by Andrew Kent. Thanks.


