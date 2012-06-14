Open-PC
=======

Open-PC is a programming contest server.  Contestants are able to submit source files to the server for judging.

For screenshots, install instructions, and more see the [Open-PC homepage](https://github.com/leachlife4/Open-PC).

Bugs are tracked on [GitHub](https://github.com/leachlife4/Open-PC).

License: GNU GPLv3+

Getting Started
  --------------

# Setting up the Server
## Installing Services
My setup has thus far been on an Ubuntu server, but could be run on some other distro with minimal effort.
To run the server you will need the following (the following is what I have tested with; other servers/daemons could be use but woult probably take more work on your own to get working):
- Apache2
  - mod-ssl
  - mod-rewrite
  - mod-cgi
- MySQL
- Perl & all the modules being used in the perl scripts -- here is a list which is not necessarily complete:
  - CGI, CGI::Carp, CGI::Session
  - DBI
  - Template, Template::Plugin::CGI
  - File::Path
  - IPC::Open3, IPC::Open2
  - JSON
  - Switch
  - String::Random
- Java/JDK (for executing submitted code)

## Configuring Services
### MySQL
- Create a user (if you use the user 'evan' and password 'password' you wont have to edit any of the source files which the MySQL credentials are currently hardcoded into)
  > `my $db = DBI->connect( 'DBI:mysql:competition:127.0.0.1', 'evan', 'password');`
- Create the required tables (the commands required are in `examples/sql/competition_db.sql`)
- Grant the user permissions on the newly created database and tables

### Apache2
- Enable the required modules
- Setup and enable a site (including ssl) to be used by the competition server and point it to the source dir where you have cloned the source to
- Make sure that the user which the CGI scripts will be run by has write access to `filestore/`

## Testing the Server
- In your browser navigate to `https://serverRoot/cgi-bin/login.pl` and try to login (eg. username `admin` with password `admin`)
