# ezproxy-stanza-update-checker
Script that checks the  [OCLC EZproxy](https://www.oclc.org/en/ezproxy.html) configuration files for official stanza updates in local installations.

## Keep your local configuration up to date
A key issue with running a self-hosted installation of EZproxy on your local server is keeping your configuration up to date with the official supported configuration file snippets (stanzas) provided by OCLC.

It seems pretty straightforward to me that OCLC could create a provisioning system to push these stanzas out to customers. But this is probably one of the main advantages of the more expensive SaaS solution.

This (crude) script can help you a bit by comparing the official [RSS feed](https://www.oclc.org/support/services/ezproxy/database-setup.en.rss) of recently updated stanzas with your local configuration files and telling you when it is time to update your stanza or when you are safe.

## Prerequisites
First, the script needs your configuration files to follow a certain syntax. Don't worry. It is quite simple.

Example:

```
# https://help.oclc.org/Library_Management/EZproxy/EZproxy_database_stanzas/Database_stanzas_A/Access_Science
Title Access Science (updated 20220909)
URL https://www.accessscience.com
HJ accessscience.com
HJ https://accessscience.com
HJ https://www.accessscience.com
HJ www.accessscience.com
HJ https://idp.sams-sigma.com
HJ idp.sams-sigma.com
DJ accessscience.com

# https://help.oclc.org/Library_Management/EZproxy/EZproxy_database_stanzas/Database_stanzas_A/ACM_Digital_Library
Option X-Forwarded-For
Title ACM Digital Library (updated 20211019)
URL http://dl.acm.org
HJ https://dl.acm.org
HJ https://dlnext.acm.org
HJ https://www.acm.org
HJ dlnext.acm.org
[...]
```

Add a blank line break after each stanza you copy into the file (you probably already do this). Then add a comment line (#) before each stanza, followed by a space and a link to the official stanza on the OCLC Help Portal.

Try not to add line breaks within each stanza as this may confuse the script. Sorry, it's a bit rough in its parsing at the moment.

Please keep the official __Title__ line of the stanza with the e.g. __(updated 20180905)__ text. In other words -- copy and paste as much as possible from the official stanzas.

You can format your private stanzas (the ones that have no OCLC equivalent) more or less as you like, as long as you add a blank line break after the stanza.

If you have multiple configuration files or installations -- no problem. The script can read and verify multiple files in one run.

Please note that from time to time OCLC may change the link syntax for stanza pages. This will break the scripts' ability to match between the local and official stanza. Check your links to make sure they are up to date.


## Usage
If your configuration file(s) follow the syntax above you are ready to go...

Run the script and add a ```--file``` option with a filename and path for each configuration file to be verified. If you add no options the script will try to open ```config.txt``` in your current working directory.

Example:

```
perl ./ezproxy-stanza-update-checker.pl --file /usr/local/ezproxy/config.txt
```

And the output might look like this:

```
Checking OCLC official stanza for: American Physiological Society
    found local copy in file: /usr/local/ezproxy/config.txt
    Local stanza updated on 20-04-2019 and official stanza updated on 25-04-2019
    Local stanza needs updating...
    https://help.oclc.org/Library_Management/EZproxy/Database_stanzas/physiology

Checking OCLC official stanza for: University of California Press
    found local copy in file: /usr/local/ezproxy/config.txt
    Local stanza needs manual checking (no datestamp to compare)...
    https://help.oclc.org/Library_Management/EZproxy/Database_stanzas/ucpress

Checking OCLC official stanza for: American Society for Microbiology
    found local copy in file: /usr/local/ezproxy/config.txt
    Local stanza is up-to-date...

Checking OCLC official stanza for: American Society of Clinical Oncology (ASCO)
    found local copy in file: /usr/local/ezproxy/config.txt
    Local stanza is up-to-date...

Checking OCLC official stanza for: AAO Ebooks Library
    not found

Checking OCLC official stanza for: VLex
    not found

Checking OCLC official stanza for: Ovid
    found local copy in file: /usr/local/ezproxy/aau_config.txt
    Local stanza is up-to-date...

Checking OCLC official stanza for: Philosophy Now
    not found

```

From the above output you can see that you will need to update the __American Physiological Society__ stanza as it appears to be out of date. The __University of California Press__ stanza has no (updated) information in the local title and you should check the stanza manually. The stanza for __American Society for Microbiology__ is up to date.

## Additional notes
As the information contained in the RSS feed can change quite quickly (and older entries disappear), you should run this script quite often (probably twice a week). Add it to your crontab and send the output to your email address. Or write a plugin for your monitoring system, if you have one, to send automatic alerts when stanzas are out of date.

An updated OCLC stanza page may include additional information about database configuration, not an update to the stanza itself. You will need to check this manually. This script only flags changes. So if a stanza suddenly shows up as up to date with a date that is not recent, then something other than the stanza has probably been updated. Check for yourself by reading the page.

The script is written in Perl and requires some non-core modules to be installed. If you have no idea what I am talking about, consult your local IT staff as you will probably need their help to get this to work. Personally, I recommend [perlbrew](https://perlbrew.pl/) and [Carton](https://metacpan.org/pod/Carton) to manage Perl and dependencies.

## Crontab example
Get an email update on Tuesday and Friday morning with the example below. For conversion between ANSI and HTML the [ansifilter](https://gitlab.com/saalen/ansifilter) is required.

```
30 07 * * 2,5 ( echo To: mail@example.com ; echo From: EZproxy Stanza Check \<mail@example.com\> ; echo "Content-Type: text/html; " ; echo Subject: EZproxy stanza update checker ; echo ; ( perl /path/ezproxy-stanza-update-checker.pl --file /usr/local/ezproxy/config.txt | ansifilter -H ) ) | /usr/sbin/sendmail -t
```
