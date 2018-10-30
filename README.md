# ezproxy-stanza-update-checker
Script to check for official stanza updates to the [OCLC EZproxy](https://www.oclc.org/en/ezproxy.html) configuration files in local deployments.

## Keep your local configuration updated
One key issue of running a self-hosted installation of EZproxy on your local server is to keep your configuration up-to-date with the official supported configuration file snippets (stanzas) provided by OCLC.

To me it would seem to be quite easy for OCLC to make a provisioning system to push these stanzas out to the customer. But it is probably one of the key advantages of the more expensive SaaS solution.

This (crude) script can help you a bit by comparing the official [RSS feed](https://www.oclc.org/support/services/ezproxy/database-setup.en.rss) of recently updated stanzas with your local configuration files and tell you when it is time to update your stanza or when you are safe.

## Prerequisites
First, the script will need your configuration files to follow a certain syntax. Don’t worry. It is quite easy.

Example:

```

# https://help.oclc.org/Library_Management/EZproxy/Database_stanzas/Access_Science
Title Access Science (updated 20180905)
URL https://www.accessscience.com
HJ http://www.accessscience.com
HJ accessscience.com
DJ accessscience.com

```

Add an empty line break after each stanza you copy into the file (you probably do that already). Then before each stanza add a comment line (#) followed by an empty space and a link to the official stanza on OCLC's help portal.

Try not to add empty line breaks within each stanza as this might confuse the script. Sorry, it is a bit crude in it's parsing at the moment.

Please maintain the official __Title__ line of the stanza with the e.g. __(updated 20180905)__ text. In other words -- copy and paste as much as possible from the official stanzas.

You can more or less format your private stanzas (the ones that have no OCLC equivalent) as you like as long as you add an empty line break after the stanza.

If you have multiple configuration files or installations -- no problem. The script can read and check multiple files in one run.

*I have only tested the script on UNIX and Windows text files might not work due to the CR/LF differences. Can be fixed pretty easilly if required.*

## Usage
If your configuration file(s) follow the above syntax you are ready to go...

Run the script and add an option ```--file``` with a file name and path for each configuration file to test. If you add no options the script will try to open ```config.txt``` within your current working directory.

Example:

```
perl ./ezproxy-stanza-update-checker.pl --file /usr/local/ezproxy/config.txt
```

And the output might look something like:

```
Checking stanza from: https://help.oclc.org/Library_Management/EZproxy/Database_stanzas/NationalJournal
Checking stanza from: https://help.oclc.org/Library_Management/EZproxy/Database_stanzas/ScienceAAAS
    in: /usr/local/ezproxy/config.txt
    found local copy of OCLC official stanza for: "Science - AAAS"
    Local stanza needs updating... Stanza updated on 23-09-2018 and feed updated on 23-10-2018
    https://help.oclc.org/Library_Management/EZproxy/Database_stanzas/ScienceAAAS

Checking stanza from: https://help.oclc.org/Library_Management/EZproxy/Database_stanzas/SymptomMedia
Checking stanza from: https://help.oclc.org/Library_Management/EZproxy/Database_stanzas/IEEE_Xplore
    in: /usr/local/ezproxy/config.txt
    found local copy of OCLC official stanza for: "IEEE Xplore"
    Local stanza needs manual checking...    https://help.oclc.org/Library_Management/EZproxy/Database_stanzas/IEEE_Xplore

Checking stanza from: https://help.oclc.org/Library_Management/EZproxy/Database_stanzas/SDU
Checking stanza from: https://help.oclc.org/Library_Management/EZproxy/Database_stanzas/jospt
    in: /usr/local/ezproxy/config.txt
    found local copy of OCLC official stanza for: "Journal of Orthopaedic and Sports Physical Therapy"
    Local stanza is up-to-date...
Checking stanza from: https://help.oclc.org/Library_Management/EZproxy/Database_stanzas/Westlaw_China
Checking stanza from: https://help.oclc.org/Library_Management/EZproxy/Database_stanzas/Westlaw
Checking stanza from: https://help.oclc.org/Library_Management/EZproxy/Database_stanzas/Womens_Pregnancy_and_Breastfeeding_Medicines_Guide
Checking stanza from: https://help.oclc.org/Library_Management/EZproxy/Database_stanzas/Sabinet_ePublications
```

From the above output you can read that you will need to update the __Science - AAAS__ stanza as it seems to be out-of-date. The __IEEE Xplore__ has no (updated) information in the local title and you should manually check the stanza. The __Journal of Orthopaedic and Sports Physical Therapy__ is up-to-date.

## Additional notes
As the information contained within the RSS feed can be changed quite rappidly (and older entries disapear) you should run this script quite often (twice a week probably). Add it to your crontab and send the output to your email address. Or, write a plugin to your monitoring system if you have one to send automatic alerts when stanzas are out-of-date.

An updated OCLC stanza pages could be enhanced with additional information regarding the database configuration and not an update to the stanza itself. You will have to manually check this. This script only flags changes to the stanza. So, if a stanza suddenly shows up as being up-to-date with a non recent date then something other than the stanza has probably been updated. Check out for yourself by reading the page.

The script is written in Perl and does require some non-core modules to be installed. If you have no idea of what I am talking about then consult with local IT staff as you probably need their help to get this to work.

## Crontab example
Get an email update tuesday and friday morning with the example below. For conversion between ANSI and HTML the [ansifilter](https://gitlab.com/saalen/ansifilter) is required.

```
30 07 * * 2,5 ( echo To: mail@example.com ; echo From: EZproxy Stanza Check \<mail@example.com\> ; echo "Content-Type: text/html; " ; echo Subject: EZproxy stanza update checker ; echo ; ( perl /path/ezproxy-stanza-update-checker.pl --file /usr/local/ezproxy/config.txt | ansifilter -H ) ) | /usr/sbin/sendmail -t
```
