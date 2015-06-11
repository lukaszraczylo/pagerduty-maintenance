# pagerduty-maintenance
Script managing maintenance mode for PagerDuty

To list all the projects use *only* -l switch.
To check current maintenance windows for project use *only* -p switch

```
# Script puts specific PD project into maintenance mode.
# Needs two ENV variables:
#   - PD_API_KEY ( pagerDuty api access key, with write permissions )
#   - PD_PROJECT_NAME ( pagerDuty project name - custom part of the URL you log in with )
# Needs two parameters:
#   - Project ( which project should it put into maintenance )
#   - Time ( ... and for how long )
```

Usage:
```
Options:
  -p, --project=<s+>       Pick specific PagerDuty service.
  -t, --time=<s>           Enable maintenance window for specific time (in minutes).
  -l, --list-projects      Shows list of the services together with their ID
  -d, --description=<s>    Optional description for maintenance window.
  -f, --filter=<s>         Search and apply for services matching the filter
  -h, --help               Show this message
```

## Sample output:

```
@12:55pm [lukaszraczylo@LukaszRaczyloMBP] ~/Documents/projects/pagerduty-maintenance git:(master*)$ ./pd-maintenance-mode.rb -p PBCXXXX -t 5
Maintenance window P2PXXXX has been created for service PBCXXXX
Window starts 2015-06-11 12:56:09 +0100 and expires 2015-06-11 13:01:09 +0100
To manage maintenance mode visit: https://potato.pagerduty.com/services/PBCXXXX
@12:56pm [lukaszraczylo@LukaszRaczyloMBP] ~/Documents/projects/pagerduty-maintenance git:(master*)$ ./pd-maintenance-mode.rb -p PBCXXXX
START_TIME     | END_TIME                  | DESCRIPTION
---------------|---------------------------|----------------------------
14 seconds ago | 2015-06-11 13:01:08       | Automated maintenance mode.
```

## Changelog:

```
- Take multiple arguments for project:
  It creates a single maintenance window with specified services included.
- Filter:
  Find all the services matching name from --filter field.
- Automated maintenance mode description contains creators system username.
```
